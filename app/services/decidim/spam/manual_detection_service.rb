# frozen_string_literal: true

module Decidim
  module Spam
    class ManualDetectionService
      DEFAULT_OPTIONS = {
        batch_size: 1000,
        batch_order: :asc,
        session_id: Time.zone.now.strftime("%Y%m%d%H%M%S"),
        sign_in_count_threshold: 2,
        save_users: false,
        block_users: false,
        block_suspicious_users: false,
        dirty_block: false,
        export_analyzed_users: false,
        ignore_previous_analysis: false,
        # Options passed to WhatLanguage.new. Don't use `only:` here : restricting the detection
        # to the expected language makes every text look like that language.
        whatlanguage: {
          min_chars: 10
        },
        expected_language: :french,
        # A non-mainstream email domain used by at least this many users of the organization is a bulk domain
        bulk_email_domain_threshold: 3,
        # Extra trusted email domains, on top of TRUSTED_EMAIL_DOMAINS_REGEX and the organization host
        trusted_email_domains: %w(opensourcepolitics.eu),
        # Extra (case insensitive) email fragments hinting at a local resident (e.g. postal code, city name)
        resident_email_hints: [],
        # Users created before this date (YYYY-MM-DD) get a resident hint (before the spam waves started)
        trusted_before: nil
      }.freeze

      MAINSTREAM_EMAIL_DOMAINS = %w(
        gmail.com googlemail.com hotmail.com outlook.com live.com msn.com yahoo.com ymail.com
        icloud.com me.com aol.com proton.me protonmail.com mail.com gmx.com yandex.com mail.ru
      ).freeze

      # French ISPs and public domains : spammers almost never use them
      TRUSTED_EMAIL_DOMAINS_REGEX = /(\.fr|\.gouv\.fr)\z|\A(orange|wanadoo|free|laposte|sfr|neuf|bbox|club-internet|aliceadsl|numericable|cegetel|9online)\./i

      # Betting brands such as go88, wi88, mb66, 33win, sv388 (checked on the name only, nicknames like "nath69" are common)
      BRAND_NAME_REGEX = /(\A|[^a-z])[a-z]{1,8}\d{2,3}([^a-z0-9]|\z)|\d{2,3}(win|bet|club|vip)/i

      COMMERCIAL_KEYWORDS_REGEX = Regexp.union(
        # Distinctive words, matched anywhere (spammers often glue words together)
        /casino|backlink|escort|call\s?girl|official|agency|solution|crypto|forex|pharma|clinic|dental|plumb|lawyer|academy/i,
        /iptv|hoodie|apparel|apperal|clothing|telegram|tai\s?xiu|nha\s?cai|uy tin|promo|digital|marketing|company|comapny|foundation|consult|cleaning/i,
        /hitclub|game\s?bai|betvisa|fashion|tiktok|download|review/i,
        # Short or ambiguous words (bet in Elisabeth, rent in Laurent...), matched between non-letters
        /(?<![a-z])(bet|slot|club|game|seo|vape|shop|store|services?|tech|llc|ltd|inc|online|loan|travel|rent|repair|design|media)(?![a-z])/i,
        /(?<![a-z])(studio|course|exam|blog|wiki|guru|support|shoes|college|school|labs?|app|vip|tv)(?![a-z])/i,
        /\.(com|net|org|io|vn|me)(?![a-z])/i
      ).freeze

      COMMERCIAL_EMAIL_LOCAL_PART_REGEX = /(seo|backlink|official|marketing|digital|agency|nhacai|casino|bet)/i

      NON_LATIN_OR_VIETNAMESE_REGEX = Regexp.union(
        /[\p{Cyrillic}\p{Arabic}\p{Han}\p{Hangul}\p{Thai}\p{Devanagari}\p{Bengali}\p{Hiragana}\p{Katakana}]/,
        /[ạảấầẩẫậắằẳẵặẹẻẽếềểễệỉịọỏốồổỗộớờởỡợụủứừửữựỳỵỷỹđ]/i
      ).freeze

      FRENCH_ACCENTS_REGEX = /[éèêëàâäçîïôöùûüœ]/i
      UPPERCASE_SURNAME_REGEX = /\b[A-Z][A-Z-]{3,}\b/

      RESIDENT_FIRST_NAMES = %w(
        jean pierre michel marie anne nathalie isabelle sylvie catherine christine sophie francoise martine valerie
        sandrine celine stephanie laurent nicolas philippe christophe patrick frederic olivier thierry pascal eric
        david julien sebastien vincent alain bernard gilles daniel daniele didier bruno franck yves serge denis rene
        claude jacques guy gerard henri louis paul thomas alexandre antoine maxime romain mathieu matthieu benoit
        fabrice cedric karim mohamed ahmed fatima nadia samira leila yasmine sarah sara camille julie aurelie audrey
        emilie elodie laetitia virginie caroline agnes brigitte monique colette josiane chantal danielle mireille odile
        helene corinne dominique evelyne veronique pauline manon lucie lea chloe clara emma ines
      ).to_set.freeze

      SPAM_RESULTS_KEYS_ORDER = [
        :personal_url,
        :about,
        :avatar_attached,
        :optional_profile_info_count,
        :low_sign_in_count,
        :suspicious_language,
        :no_contributions,
        :no_votes,
        :trusted_email_domain,
        :spam_email_domain,
        :commercial_identity,
        :resident_hint,
        :score,
        :conclusion
      ].freeze

      ANALYSIS_REPORT_SPAM_KEYS_ORDER = [
        :analyzable,
        :personal_url,
        :about,
        :avatar_attached,
        *(0..3).map { |i| "optional_profile_info_count#{i}".to_sym },
        :low_sign_in_count,
        :suspicious_language,
        :no_contributions,
        :no_votes,
        :trusted_email_domain,
        :spam_email_domain,
        :commercial_identity,
        :resident_hint,
        :score,
        *(%w(unknown suspicious probable_spam spam not_spam).map { |status| "conclusion_#{status}".to_sym })
      ].freeze

      attr_reader :organization, :options, :whatlanguage, :analysis_results

      def initialize(organization:, **options)
        @organization = organization
        raise ArgumentError, "Invalid organization provided : #{organization.inspect}" if @organization.nil? || !@organization.is_a?(Decidim::Organization)

        @options = DEFAULT_OPTIONS.deep_merge(options)
        @whatlanguage = WhatLanguage.new(**@options[:whatlanguage].slice(:min_chars)) if @options[:whatlanguage]

        @analysis_report = preflight_report
        @analysis_results = analyzable_users.to_a
      end

      def preflight_report
        {
          **options,
          organization: {
            id: organization.id,
            name: organization.name,
            host: organization.host
          },
          users: {
            total: organization.user_entities.count,
            groups: organization.user_entities.select { |u| u.type == "Decidim::UserGroup" }.count,
            admins: organization.admins.count,
            available: organization.users.available.count,
            confirmed: organization.users.confirmed.count,
            blocked: organization.users.blocked.count,
            deleted: organization.users.where.not(deleted_at: nil).count,
            legacy_spam_users: organization.users.where("extended_data -> 'spam_detection' ? :key", key: "reported_at").count,
            already_analyzed_users: organization.users.where("extended_data -> 'spam_detection' ? :key", key: "manual").count
          },
          spam: {
            analyzable: analyzable_users.count
          }
        }
      end

      def analysis_report
        @analysis_report.merge(
          spam: @analysis_report[:spam].reverse_merge(
            ANALYSIS_REPORT_SPAM_KEYS_ORDER.index_with { nil }
          ).compact
        )
      end

      # TODO : check users blocked for other reasons than spam detection
      def analyzable_users
        @analyzable_users ||= begin
          Rails.logger.debug "Performing analyzable_users query"
          base_query = organization.users.available.where(admin: false).where("roles = '{}' OR roles IS NULL")
          base_query = base_query.where.not(quick_auth_users_sql)
          base_query = base_query.where.not(legacy_spam_unreported_users_sql)
          base_query = base_query.where.not(already_analyzed_users_sql) unless options[:ignore_previous_analysis]

          begin
            base_query = base_query.where("created_at < ?", Date.parse(options[:before]).to_fs(:db)) if options[:before].present?
          rescue Date::Error
            Rails.logger.error "Invalid date format for options[:before]: #{options[:before]}"
          end

          begin
            base_query = base_query.where("created_at > ?", Date.parse(options[:after]).to_fs(:db)) if options[:after].present?
          rescue Date::Error
            Rails.logger.error "Invalid date format for options[:after]: #{options[:after]}"
          end

          base_query = base_query.limit(options[:limit]) if options[:limit].present?
          base_query = base_query.order(options[:order]) if options[:order].present?
          base_query.with_attached_avatar
        end
        # .tap(&:load)# Ensure the query is executed and cached
      end

      def quick_auth_users_sql
        "email LIKE 'quick_auth-%@#{organization.host}'"
      end

      def legacy_spam_unreported_users_sql
        "(extended_data ? 'spam_detection') AND (extended_data -> 'spam_detection' ? 'unreported_at')"
      end

      def already_analyzed_users_sql
        "(extended_data ? 'spam_detection') AND (extended_data -> 'spam_detection' ? 'manual')"
      end

      # TODO : add exclusion for space members and meetings invites
      # TODO : meetings registrations (+ requests)
      # TODO : decidim_proposals_collaborative_draft_collaborator_requests.decidim_user_id
      # TODO : messaging (decidim_messaging_messages.decidim_sender_id + decidim_messaging_participations.decidim_participant_id)
      def analyse_user(user)
        {
          score: 0,
          conclusion: "unknown"
        }.tap do |results|
          process_simple_analysis_rule(results, :personal_url, user.personal_url.present?)
          process_simple_analysis_rule(results, :about, user.about.present?)
          process_simple_analysis_rule(results, :avatar_attached, user.avatar.attached?)

          optional_profile_info_count = 0
          optional_profile_info_count += 1 if user.personal_url.present?
          optional_profile_info_count += 1 if user.about.present?
          optional_profile_info_count += 1 if user.avatar.attached?
          results[:optional_profile_info_count] = optional_profile_info_count
          update_report_counter("optional_profile_info_count#{optional_profile_info_count}".to_sym, true)

          process_simple_analysis_rule(results, :low_sign_in_count, user.sign_in_count < options[:sign_in_count_threshold])
          process_simple_analysis_rule(results, :suspicious_language, suspicious_language?(user.about))

          process_simple_analysis_rule(results, :no_contributions, count_contributions(user).zero?)
          process_simple_analysis_rule(results, :no_votes, count_votes(user).zero?)

          # Identity signals, used to settle users with an empty profile and no activity. They don't count in the score.
          process_simple_analysis_rule(results, :trusted_email_domain, trusted_email_domain?(email_domain(user)), scored: false)
          process_simple_analysis_rule(results, :spam_email_domain, spam_email_domain?(email_domain(user)), scored: false)
          process_simple_analysis_rule(results, :commercial_identity, commercial_identity?(user), scored: false)
          process_simple_analysis_rule(results, :resident_hint, resident_hint?(user), scored: false)

          user_analysis_conclusion(results)
        end.reverse_merge(
          SPAM_RESULTS_KEYS_ORDER.index_with { nil }
        ).compact.with_indifferent_access
      end

      # Short texts are not detected (nil) and are not considered suspicious
      def suspicious_language?(text)
        return false if whatlanguage.blank? || text.blank?

        language = whatlanguage.language(text)
        language.present? && language != options[:expected_language].to_sym
      end

      def email_domain(user)
        user.email.to_s.split("@").last.to_s.strip.downcase
      end

      # Number of users per email domain, for all users and for already blocked users
      def email_domains_stats
        @email_domains_stats ||= begin
          domain_sql = Arel.sql("lower(split_part(email, '@', 2))")
          {
            all: organization.users.group(domain_sql).count,
            blocked: organization.users.blocked.group(domain_sql).count
          }
        end
      end

      def trusted_email_domain?(domain)
        return false if domain.blank?

        domain.match?(TRUSTED_EMAIL_DOMAINS_REGEX) ||
          domain == organization.host.to_s.downcase.sub(/\A[^.]+\.(?=.+\..+)/, "") ||
          Array(options[:trusted_email_domains]).map(&:downcase).include?(domain)
      end

      # Non-mainstream domain already used by blocked users, or shared by many accounts (disposable / bulk domains)
      def spam_email_domain?(domain)
        return false if domain.blank? || MAINSTREAM_EMAIL_DOMAINS.include?(domain) || trusted_email_domain?(domain)

        email_domains_stats[:blocked].fetch(domain, 0).positive? ||
          email_domains_stats[:all].fetch(domain, 0) >= options[:bulk_email_domain_threshold]
      end

      def commercial_identity?(user)
        commercial_name?(user) || user.email.to_s.split("@").first.to_s.match?(COMMERCIAL_EMAIL_LOCAL_PART_REGEX)
      end

      def commercial_name?(user)
        name = user.name.to_s
        nickname = user.nickname.to_s

        name.match?(BRAND_NAME_REGEX) ||
          I18n.transliterate(name).match?(COMMERCIAL_KEYWORDS_REGEX) ||
          nickname.match?(COMMERCIAL_KEYWORDS_REGEX) ||
          name.match?(NON_LATIN_OR_VIETNAMESE_REGEX) ||
          name.match?(/\d{3,}/) ||
          nickname.match?(/\d{4,}/) ||
          name.match?(/\A[a-z0-9]{14,}\z/)
      end

      # A name that looks like a brand is never a resident hint (vietnamese accents, uppercase brands...)
      def resident_hint?(user)
        return false if commercial_name?(user)

        name = user.name.to_s
        email = user.email.to_s.downcase
        name_words = I18n.transliterate(name.downcase).split(/[\s._-]+/)

        name.match?(FRENCH_ACCENTS_REGEX) ||
          name.match?(UPPERCASE_SURNAME_REGEX) ||
          name_words.any? { |word| RESIDENT_FIRST_NAMES.include?(word) } ||
          resident_email_hint?(email) ||
          trusted_before?(user)
      end

      def resident_email_hint?(email)
        email_local_part = email.split("@").first.to_s

        RESIDENT_FIRST_NAMES.any? { |first_name| first_name.size > 3 && email_local_part.match?(/\A#{first_name}[._-]/) } ||
          Array(options[:resident_email_hints]).any? { |hint| email.include?(hint.to_s.downcase) }
      end

      def trusted_before?(user)
        options[:trusted_before].present? && user.created_at < Date.parse(options[:trusted_before].to_s)
      rescue Date::Error
        false
      end

      def count_contributions(user)
        psql = %{
          WITH
            cterc AS (
              SELECT count(id) as rc FROM decidim_coauthorships WHERE decidim_author_type = 'Decidim::UserBaseEntity' AND decidim_author_id = $1
              UNION ALL
              SELECT count(id) as rc FROM decidim_comments_comments WHERE decidim_author_type = 'Decidim::UserBaseEntity' AND decidim_author_id = $1
              UNION ALL
              SELECT count(id) as rc FROM decidim_initiatives WHERE decidim_author_type = 'Decidim::UserBaseEntity' AND decidim_author_id = $1
              UNION ALL
              SELECT count(id) as rc FROM decidim_forms_answers WHERE decidim_user_id = $1
              UNION ALL
              SELECT count(id) as rc FROM decidim_meetings_answers WHERE decidim_user_id = $1
            )
          SELECT SUM(rc) as total
          from cterc
        }.squish
        bind = ActiveRecord::Relation::QueryAttribute.new(
          "decidim_author_id",
          user.id,
          ActiveRecord::Type::Value.new
        )
        ActiveRecord::Base.connection.select_all(psql, "PSQL", [bind], preparable: true).first["total"].to_i
      end

      def has_contributions?(user)
        count_contributions(user).positive?
      end

      def count_votes(user)
        psql = %{
          WITH
            cterc AS (
              SELECT count(id) as rc FROM decidim_budgets_orders WHERE decidim_user_id = $1
              UNION ALL
              SELECT count(id) as rc FROM decidim_comments_comment_votes WHERE decidim_author_id = $1
              UNION ALL
              SELECT count(id) as rc FROM decidim_endorsements WHERE decidim_author_type = 'Decidim::UserBaseEntity' AND decidim_author_id = $1
              UNION ALL
              SELECT count(id) as rc FROM decidim_follows WHERE decidim_user_id = $1
              UNION ALL
              SELECT count(id) as rc FROM decidim_initiatives_votes WHERE decidim_author_id = $1
              UNION ALL
              SELECT count(id) as rc FROM decidim_proposals_proposal_votes WHERE decidim_author_id = $1
            )
          SELECT SUM(rc) as total
          from cterc
        }.squish
        bind = ActiveRecord::Relation::QueryAttribute.new(
          "decidim_user_id",
          user.id,
          ActiveRecord::Type::Value.new
        )
        ActiveRecord::Base.connection.select_all(psql, "PSQL", [bind], preparable: true).first["total"].to_i
      end

      def has_votes?(user)
        count_votes(user).positive?
      end

      def process_simple_analysis_rule(results, key, boolean_value, scored: true)
        results[key.to_sym] = boolean_value
        results[:score] += 1 if boolean_value && scored
        update_report_counter(key, boolean_value)
      end

      def update_report_counter(key, boolean_value)
        @analysis_report[:spam][key.to_sym] ||= 0
        @analysis_report[:spam][key.to_sym] += 1 if boolean_value
      end

      def user_analysis_conclusion(results)
        if results[:score] >= 7
          results[:conclusion] = "spam"
        elsif results[:no_contributions] && results[:no_votes]
          results[:conclusion] = inactive_user_conclusion(results)
        elsif results[:suspicious_language]
          results[:conclusion] = "suspicious"
          # elsif results[:score] == 0
          #   results[:conclusion] = "not_spam"
        end
        update_report_counter("conclusion_#{results[:conclusion]}".to_sym, true)
      end

      # Users without contributions nor votes
      def inactive_user_conclusion(results)
        spam_profile?(results) ? "spam" : empty_profile_conclusion(results)
      end

      def spam_profile?(results)
        (results[:suspicious_language] && results[:low_sign_in_count]) ||
          results[:score] >= 5 ||
          (results[:score] >= 4 && (results[:suspicious_language] || results[:personal_url]))
      end

      # Users with an empty profile and no activity : bots that didn't fill their profile yet, or real residents
      # who never participated. "suspicious" is kept for the ones worth a manual review.
      def empty_profile_conclusion(results)
        if results[:commercial_identity]
          "spam"
        elsif results[:spam_email_domain]
          results[:resident_hint] ? "suspicious" : "spam"
        elsif results[:trusted_email_domain]
          "not_spam"
        elsif results[:resident_hint]
          "suspicious"
        else
          "probable_spam"
        end
      end

      def run
        run_started_at = Time.current
        @analysis_results = []
        user_processed = 0
        analyzable_users.find_each(batch_size: options[:batch_size], order: options[:batch_order]) do |user|
          Rails.logger.info "Analyzing user (#{user.class}) #{user.id} (#{user.email})"
          user.extended_data["spam_detection"] ||= {}
          user.extended_data["spam_detection"]["manual"] = {
            session_id: options[:session_id]
          }.merge(analyse_user(user))

          # user.save!(validate: false) if options[:save_users]
          user.update_columns(extended_data: user.extended_data) if options[:save_users] # rubocop:disable Rails/SkipsModelValidations

          @analysis_results << user

          user_processed += 1
        end
        run_finished_at = Time.current
        @analysis_report[:run] = {
          started_at: run_started_at,
          finished_at: run_finished_at,
          processed: user_processed,
          duration: ActiveSupport::Duration.build(run_finished_at - run_started_at).inspect
        }
      end

      def export_results
        export_path = Rails.root.join("tmp/spam/manual-spam-detection", "#{options[:session_id]}--#{organization.host}")
        FileUtils.mkdir_p(export_path) unless File.directory?(export_path)

        export_path.join("analysis_report.json").tap do |path|
          path.write(JSON.pretty_generate(@analysis_report))
        end

        return unless @analysis_results.present? && options[:export_analyzed_users]

        export_path.join("analysis_results.csv").tap do |path|
          path.write(Decidim::Exporters::CSV.new(@analysis_results, Decidim::Spam::ManualUserReportSerializer).export.read)
        end
      end
    end
  end
end
