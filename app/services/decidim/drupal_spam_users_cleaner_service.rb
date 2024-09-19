# frozen_string_literal: true

require "logger_with_stdout"

module Decidim
  class DrupalSpamUsersCleanerService
    AUTHORIZED_SITES = %w(
      bordeaux-metropole
      eelv
      bordeaux-bastide
      injs-bordeaux.org
      bordeaux-tradition.com
      u-bordeaux-montaigne.fr
      apprentus.fr
      metrobordeaux.fr
      www.theshifters.org
      linkedin.com
      lafab-bm.fr
      naturjalles.over-blog.com
      bernard.sarlandie.over-blog.fr
      www.velo-cite.org
      www.chrispillot.fr
      www.atelierdecosolidaire.com
      www.bupa.pro
      gironde.gouv.fr
      vinylmaniaque.com
      wheelers33.com
      olivierrichard2017
      edeis.com
      prendre-le-tram-a-gradignan.com
      visiteusedumonde.wordpress.com
      mixeratum-ergosum.com
      cellbiol.net
      eddydurteste.com
      cabinetransdisciplinaire.webself.net
      pessacrugby.fr
      ffmc33.org
      jrguillaumie.fr
      carto.metro.free.fr
      quartierlapaillere
      theatre-escale.fr
      steco.fr
      vignesavendre.com
      AssoSemoPerma
      pierreneyt.fr
      damienduriez.com
      clement-rossignol-puech.fr
      aehdcna.fr
      Christopher.blckford
      blackday.fr
      mfp.cnrs.fr
      bardin.eurl
      guy.l1954
      sauvonslebourg.org
      testavis.fr
      shaynlink.fr
      japa-mania.fr
      ciip.fr
      elus-gironde.eelv.fr
      fi33.fr
      amaf-medoc.fr
      aurasdusol.org
      reinecargo.fr
      toctoucau.fr
      association.adema.online.fr
      quais270.e-monsite.com
      kultnride.fr
      blayeamicaledesusagersdutrain
      Benoitsimian.fr
      vg-agglo.com
      enrayerlamachine.canalblog.com
      jeanluc.rigal.free.fr
      baboulenne120427
      garrigues.fr
      franceapprentissage.fr
      casiwinner.com
      nicolasjullien.fr
      bebert.free.fr
    ).freeze

    MODERATION_EMAIL = "mako@osp.cat"

    def self.run(**args)
      new(**args).execute
    end

    def initialize(**args)
      @logger = ::LoggerWithStdout.new("log/clean-bdx-spam_users--#{Time.zone.now.strftime("%Y-%m-%d-%H-%M-%S")}.log")
      @logger.warn "Rake(clean:bdx:spam_users)> initializing..."
      @organization = args[:organization]
      @logger.warn "Rake(clean:bdx:spam_users)> Organization with host #{@organization.host}"
      @limit = args[:limit]
      @logger.warn("Rake(clean:bdx:spam_users)> limit is #{@limit}") if @limit
      @errors = []
      @spam_users = []
      @spam_resources = []
      @spam_proposals_counter = 0
      @spam_comments_counter = 0
    end

    def execute
      @logger.warn "Rake(clean:bdx:spam_users)> executing..."
      users = select_users_from_external_db

      if users.blank?
        @logger.warn "Rake(clean:bdx:spam_users)> No users found"
        return
      else
        @logger.warn "Rake(clean:bdx:spam_users)> found #{users.size} drupal users"
      end

      users.each do |drupal_user|
        next if drupal_user.site_web.blank?

        spam_account = true
        spam_account &&= (drupal_user.site_web != "http:// ")
        AUTHORIZED_SITES.each do |site|
          spam_account &&= !/#{Regexp.escape(site)}/.match?(drupal_user.site_web)
        end

        next unless spam_account

        @logger.warn "Rake(clean:bdx:spam_users)> drupal user with site #{drupal_user.site_web} is flag as spam"
        begin
          spam_csv_data = {
            drupal_id: drupal_user.uid,
            decidim_id: nil,
            email: drupal_user.mail,
            name: nil,
            site_web: drupal_user.site_web,
            proposals_count: nil,
            comments_count: nil,
            status: "not found"
          }
          decidim_user = find_user(drupal_user)

          if decidim_user
            @logger.warn "Rake(clean:bdx:spam_users)> found decidim user with id #{decidim_user.id}"

            spam_csv_data[:decidim_id] = decidim_user.id
            spam_csv_data[:name] = decidim_user.name
            spam_csv_data[:email] = decidim_user.email
            spam_csv_data[:status] = decidim_user.deleted? ? "already deleted" : "active"

            profile_data = {
              drupal: decidim_user.extended_data["drupal"].merge({
                                                                   name: decidim_user.name,
                                                                   mail: decidim_user.email,
                                                                   spam: true
                                                                 })
            }

            proposals = find_proposals(decidim_user)
            spam_csv_data[:proposals_count] = proposals.size
            if proposals.size.positive?
              @logger.warn "Rake(clean:bdx:spam_users)> found #{proposals.size} proposals for user #{decidim_user.id}"
              proposals.each do |reportable|
                if reportable.hidden?
                  @logger.warn "Rake(clean:bdx:spam_users)> #{reportable.class.name} with id #{reportable.id} is already hidden"
                else
                  hide_resource!(reportable)
                  @spam_proposals_counter += 1
                  @spam_resources.push(spam_resource_data(decidim_user, reportable).merge({
                                                                                            abstract: reportable.title[@organization.default_locale].truncate(75)
                                                                                          }))
                end
              end
            end

            comments = find_comments(decidim_user)
            spam_csv_data[:comments_count] = comments.size
            if comments.size.positive?
              @logger.warn "Rake(clean:bdx:spam_users)> found #{comments.size} comments for user #{decidim_user.id}"
              comments.each do |reportable|
                if reportable.hidden?
                  @logger.warn "Rake(clean:bdx:spam_users)> #{reportable.class.name} with id #{reportable.id} is already hidden"
                else
                  hide_resource!(reportable)
                  @spam_comments_counter += 1
                  @spam_resources.push(spam_resource_data(decidim_user, reportable).merge({
                                                                                            abstract: reportable.body[@organization.default_locale].truncate(75)
                                                                                          }))
                end
              end
            end

            unless decidim_user.deleted?
              destroy_user_account!(decidim_user)
              spam_csv_data[:status] = "deleted"
              @logger.warn "Rake(clean:bdx:spam_users)> Decidim user #{decidim_user.id} is anonymized"
            end

            decidim_user.extended_data = decidim_user.extended_data.merge(profile_data)
            decidim_user.save!(validate: false)

          else
            @logger.warn "Rake(clean:bdx:spam_users)> decidim user with email #{drupal_user.mail} or drupal uid #{drupal_user.uid} not found"
          end

          @spam_users.push(spam_csv_data)
        rescue StandardError => e
          @logger.warn { "Rake(clean:bdx:spam_users)>  #{e.class}: '#{e.message}'" }
          @errors.push(spam_csv_data.merge({ error: "#{e.class}: #{e.message}" }))
          next
        end
      end

      @logger.warn "Rake(clean:bdx:spam_users)> found and deleted #{@spam_users.size} spam users"
      write_csv_spam_users_file if @spam_users.present?
      @logger.warn "Rake(clean:bdx:spam_users)> found and moderated #{@spam_resources.size} spam resources"
      write_csv_spam_resources_file if @spam_resources.present?
      @logger.warn "#{@errors.size} errors"
      write_csv_error_file if @errors.present?
      @logger.warn "Rake(clean:bdx:spam_users)> terminated"
    end

    private

    def select_users_from_external_db
      ::Drupal::User.select(%w(uid mail)).where.not(mail: [nil, "", "."]).limit(@limit)
    end

    def find_user(drupal_user)
      Decidim::User.find_by(email: drupal_user.mail) || Decidim::User.where("extended_data::jsonb @> :drupal", drupal: { drupal: { uid: drupal_user.uid } }.to_json)&.first
    end

    def find_proposals(decidim_user)
      Decidim::Proposals::Proposal.where(id: Decidim::Coauthorship.where(coauthorable_type: "Decidim::Proposals::Proposal", decidim_author_type: "Decidim::UserBaseEntity",
                                                                         decidim_author_id: decidim_user.id))
    end

    def find_comments(decidim_user)
      Decidim::Comments::Comment.where(decidim_author_type: "Decidim::UserBaseEntity", decidim_author_id: decidim_user.id)
    end

    def moderation_user_params
      {
        organization: @organization,
        admin: true,
        email: MODERATION_EMAIL
      }
    end

    def moderation_user
      @moderation_user ||= Decidim::User.find_by(moderation_user_params)

      return @moderation_user unless @moderation_user.nil?

      create_moderation_user!
    end

    def create_moderation_user!
      password = ::Devise.friendly_token(24)
      additional_params = {
        name: "Spam import bot",
        nickname: "spam_import_bot",
        password: password,
        password_confirmation: password,
        tos_agreement: true,
        email_on_moderations: false
      }
      new_moderation_user = Decidim::User.new(moderation_user_params.merge(additional_params))
      new_moderation_user.skip_confirmation!
      new_moderation_user.save!
      @logger.warn "Rake(clean:bdx:spam_users)> Created new moderation user with id #{new_moderation_user.id}"
      @moderation_user = new_moderation_user
    end

    def find_or_create_moderation!(reportable)
      Decidim::Moderation.find_or_create_by!(reportable: reportable, participatory_space: reportable.participatory_space)
    end

    def create_report!(reportable)
      moderation = find_or_create_moderation!(reportable)
      return if Decidim::Report.exists?(moderation: moderation, user: moderation_user)

      Decidim::Report.create!(
        moderation: moderation,
        user: moderation_user,
        reason: "spam",
        details: "drupal import spam detection",
        locale: @organization.default_locale
      )
    end

    def hide_resource!(reportable)
      create_report!(reportable)
      reportable.reload
      reportable.moderation.update!(
        report_count: reportable.moderation.report_count + 1,
        hidden_at: Time.current
      )
      @logger.warn "Rake(clean:bdx:spam_users)> #{reportable.class.name} with id #{reportable.id} is now moderated (hidden)"
    end

    def spam_resource_data(decidim_user, reportable)
      {
        decidim_user_id: decidim_user.id,
        decidim_user_email: decidim_user.email,
        resource_type: reportable.class.name,
        resource_id: reportable.id,
        abstract: nil,
        moderation_link: "https://#{@organization.host}/admin/moderations/#{reportable.moderation.id}/reports"
      }
    end

    def destroy_user_account!(decidim_user)
      decidim_user.invalidate_all_sessions!

      decidim_user.name = ""
      decidim_user.nickname = ""
      decidim_user.email = ""
      decidim_user.delete_reason = "drupal import spam detection"
      decidim_user.admin = false if decidim_user.admin?
      decidim_user.deleted_at = Time.current
      decidim_user.skip_reconfirmation!
      decidim_user.avatar.purge
      decidim_user.save!

      decidim_user.identities.destroy_all
    end

    def write_csv_spam_users_file
      Dir.mkdir("tmp/drupal_import") unless File.exist?("tmp/drupal_import")
      file_path = "tmp/drupal_import/spam-users--list--#{Time.zone.now.strftime("%Y-%m-%d-%H-%M-%S")}.csv"
      FileUtils.mkdir_p(File.dirname(file_path))
      file_exists = File.exist?(file_path) && !File.zero?(file_path)

      CSV.open(file_path, "a") do |csv|
        csv << @spam_users.first.keys unless file_exists || @spam_users.empty?
        @spam_users.each do |u|
          csv << u.values
        end
      end
    end

    def write_csv_spam_resources_file
      Dir.mkdir("tmp/drupal_import") unless File.exist?("tmp/drupal_import")
      file_path = "tmp/drupal_import/spam-resources--list--#{Time.zone.now.strftime("%Y-%m-%d-%H-%M-%S")}.csv"
      FileUtils.mkdir_p(File.dirname(file_path))
      file_exists = File.exist?(file_path) && !File.zero?(file_path)

      CSV.open(file_path, "a") do |csv|
        csv << @spam_resources.first.keys unless file_exists || @spam_resources.empty?
        @spam_resources.each do |u|
          csv << u.values
        end
      end
    end

    def write_csv_error_file
      Dir.mkdir("tmp/drupal_import") unless File.exist?("tmp/drupal_import")
      file_path = "tmp/drupal_import/spam-users--errors--#{Time.zone.now.strftime("%Y-%m-%d-%H-%M-%S")}.csv"
      FileUtils.mkdir_p(File.dirname(file_path))
      file_exists = File.exist?(file_path) && !File.zero?(file_path)

      CSV.open(file_path, "a") do |csv|
        csv << @errors.first.keys unless file_exists || @errors.empty?
        @errors.each do |error|
          csv << error.values
        end
      end
    end
  end
end
