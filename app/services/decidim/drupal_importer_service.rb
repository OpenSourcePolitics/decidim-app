# frozen_string_literal: true

# rubocop:disable Metrics/CyclomaticComplexity
# rubocop:disable Metrics/PerceivedComplexity
# rubocop:disable Security/Open
module Decidim
  class DrupalImporterService
    def self.run(**args)
      new(**args).execute
    end

    def initialize(**args)
      Rails.logger.warn "Rake(import:pps)> initializing..."
      @path = args[:path]
      @organization = args[:organization]
      @dev = true
    end

    def execute
      Rails.logger.warn "Rake(import:pps)> executing..."
      rows = CSV.read(@path, headers: true)

      if rows.blank?
        Rails.logger.warn "Rake(import:pps)> No rows found"
        return
      end

      Rails.logger.warn "Rake(import:pps)> processing #{rows.size} rows..."
      rows.each do |row|
        drupal_page = Decidim::DrupalPage.scrape(url: row["url"])
        Rails.logger.warn "Rake(import:pps)> Retrieving #{row["url"]}..."
        if drupal_page.errors.present?
          Rails.logger.warn "Rake(import:pps)> Error: #{drupal_page.errors} for '#{rows["url"]}'"
          next
        end

        pp = Decidim::ParticipatoryProcess.find_by(slug: "projet-#{drupal_page.drupal_node_id}")
        if pp.blank?
          pp = Decidim::ParticipatoryProcess.create!(
            title: { "fr" => drupal_page.title },
            slug: "projet-#{drupal_page.drupal_node_id}",
            subtitle: { "fr" => "Projet" },
            short_description: { "fr" => drupal_page.short_description },
            description: { "fr" => drupal_page.description },
            organization: @organization,
            participatory_scope: { "fr" => drupal_page.drupal_thematique },
            participatory_structure: { "fr" => drupal_page.drupal_type },
            target: { "fr" => "Gestionnaire de la participation : #{drupal_page.drupal_author}" },
            meta_scope: { "fr" => "" },
            developer_group: { "fr" => drupal_page.drupal_organization.presence || "Bordeaux Métropole" },
            start_date: Time.zone.now,
            end_date: 1.minute.from_now
          )
        end

        meeting = create_meeting!(@organization, pp)
        page = create_page!(@organization, pp)
        proposal = create_proposal!(@organization, pp)

        drupal_page.pdf_attachments.each do |f|
          content = URI.open(f[:href])
          file = {
            io: content,
            filename: File.basename(f[:href]),
            content_type: "application/pdf",
            name: f[:title]
          }

          attachment =
            {
              name: file[:name],
              filename: file[:filename],
              description: file[:name],
              content_type: file[:content_type],
              attached_to: pp,
              file: {
                io: file[:io],
                filename: file[:filename],
                content_type: file[:content_type],
                metadata: nil
              }
            }

          Decidim::Attachment.create!(
            title: { "fr" => attachment[:name] },
            description: { "fr" => attachment[:description] },
            attachment_collection: nil,
            content_type: attachment[:content_type],
            attached_to: pp,
            file: ActiveStorage::Blob.create_and_upload!(
              io: attachment.dig(:file, :io),
              filename: attachment.dig(:file, :filename),
              content_type: attachment.dig(:file, :content_type),
              metadata: attachment.dig(:file, :metadata)
            )
          )

        rescue ActiveRecord::RecordInvalid => e
          case e.message
          when /Validation failed: Title has already been taken/
            Rails.logger.warn "Rake(import:pps)> Attachment already exists"
          when /Validation failed: File file size must be less than or equal to/, /File la taille du fichier doit être inférieure ou égale/
            org = attachment[:attached_to].organization
            limit = ActiveSupport::NumberHelper::NumberToHumanSizeConverter.convert(org.maximum_upload_size, {})
            human_filesize = ActiveSupport::NumberHelper::NumberToHumanSizeConverter.convert(attachment[:file][:io].size, {})
            Rails.logger.warn { "Rake(import:pps)>  Attachment file size too big for '#{attachment[:name]}': #{human_filesize}" }
            Rails.logger.warn { "Rake(import:pps)>  Max: #{limit} current: #{human_filesize}" }
          else
            Rails.logger.warn { "Rake(import:pps)>  Error: '#{e.message}'" }
          end

          drupal_page&.add_error(
            message: e.message,
            name: attachment[:name],
            filename: attachment[:filename],
            human_filesize: human_filesize,
            limit: limit
          )
          sleep 0.75
        end

        drupal_page.set_decidim_participatory_process_id(pp.id)
        url = "https://#{@organization.host}/processes/#{pp.slug}"
        drupal_page.set_participatory_process_url(url)
        drupal_page.set_decidim_meeting_id(meeting.id)
        drupal_page.set_decidim_page_id(page.id)
        drupal_page.set_decidim_proposal_id(proposal.id)
        drupal_page&.save_json_resume!
        drupal_page&.save_csv_resume!
        sleep 2

      rescue StandardError => e
        drupal_page&.add_error(
          message: e.message
        )

        drupal_page&.save_json_resume!
        drupal_page&.save_csv_resume!
        next
      end
      Rails.logger.warn "Rake(import:pps)> terminated"
    end

    private

    def create_meeting!(org, pp)
      component = Decidim::Component.find_by(name: "RENCONTRES 📍", manifest_name: "meetings", participatory_space: pp)
      return component if component.present?

      Decidim::Component.create!(
        name: "RENCONTRES 📍",
        manifest_name: "meetings",
        participatory_space: pp,
        published_at: Time.zone.now,
        settings: {
          "title" => { "fr" => "RENCONTRES" },
          "description" => { "fr" => "Rencontres" },
          "position" => 1,
          "organization" => org
        }
      )
    end

    def create_page!(org, pp)
      component = Decidim::Component.find_by(name: "BILANS & DÉCISIONS", manifest_name: "pages", participatory_space: pp)
      return Decidim::Pages::Page.find_by(component: component) if component.present?

      component = Decidim::Component.create!(
        name: "BILANS & DÉCISIONS",
        manifest_name: "pages",
        participatory_space: pp,
        published_at: Time.zone.now,
        settings: {
          "title" => { "fr" => "BILANS & DÉCISIONS" },
          "description" => { "fr" => "Bilans" },
          "position" => 2,
          "organization" => org
        }
      )

      Decidim::Pages::Page.create!(
        body: { "fr" => "." },
        component: component
      )
    end

    def create_proposal!(org, pp)
      component = Decidim::Component.find_by(name: "AVIS ET REACTIONS 💡", manifest_name: "proposals", participatory_space: pp)
      return component if component.present?

      Decidim::Component.create!(
        name: "AVIS ET REACTIONS 💡",
        manifest_name: "proposals",
        participatory_space: pp,
        published_at: Time.zone.now,
        settings: {
          "title" => { "fr" => "PROPOSITIONS" },
          "description" => { "fr" => "Propositions" },
          "position" => 3,
          "organization" => org
        }
      )
    end
  end
end
# rubocop:enable Metrics/CyclomaticComplexity
# rubocop:enable Metrics/PerceivedComplexity
# rubocop:enable Security/Open
