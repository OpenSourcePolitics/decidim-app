module Decidim
  class DrupalPage
    attr_reader :url, :slug, :md5, :nokogiri_document, :title, :description, :calendars, :short_description, :drupal_node_id, :thematique, :pdf_attachments, :participatory_process_url,
                :decidim_participatory_process_id, :errors, :drupal_type, :drupal_author, :drupal_organization, :drupal_thematique

    def self.scrape(**args)
      new(**args).scrape
    end

    def initialize(**args)
      @url = args[:url]
      @slug = args[:slug]
      @md5 = Digest::MD5.hexdigest(@url)
      @pdf_attachments = []
      @errors = []
      @base_url = base_url
    end

    def migration_metadata
      {
        url: @url,
        title: @title,
        short_url: @short_url,
        drupal_node_id: @drupal_node_id,
        thematique: @thematique,
        attachments_count: @pdf_attachments.length,
        decidim_participatory_process_id: @decidim_participatory_process_id,
        participatory_process_url: @participatory_process_url,
        errors_count: @errors.size,
        md5: @md5,
        decidim_meeting_id: @decidim_meeting_id,
        decidim_page_id: @decidim_page_id,
        decidim_proposal_id: @decidim_proposal_id
      }
    end

    def attributes
      {
        html_page: "tmp/drupal_import/#{@md5}/#{@md5}.html",
        title: @title,
        url: @url,
        short_url: @short_url,
        drupal_node_id: @drupal_node_id,
        thematique: @thematique,
        description: @description,
        short_description: @short_description,
        pdf_attachments: @pdf_attachments,
        calendars: @calendars,
        errors: @errors
      }
    end

    def scrape
      fetch_html
      return if @nokogiri_document.blank?

      set_thematique
      set_drupal_node_id
      set_title
      set_description
      set_short_description
      set_pdf_attachments
      set_calendars
      set_drupal_type
      set_drupal_thematique
      set_drupal_organization
      set_drupal_author
      save!

      self
    rescue StandardError => e
      add_error(message: e.message)
      save!
      self
    end

    def fetch_html
      Faraday.default_adapter = :net_http
      req = Faraday.get(@url)
      @html = req.body if req.status == 200
      @nokogiri_document = Nokogiri::HTML(@html) if @html.present?
    end

    def set_participatory_process_url(url)
      @participatory_process_url = url
    end

    def set_decidim_participatory_process_id(id)
      @decidim_participatory_process_id = id
    end

    def set_decidim_meeting_id(id)
      @decidim_meeting_id = id
    end

    def set_decidim_page_id(id)
      @decidim_page_id = id
    end

    def set_decidim_proposal_id(id)
      @decidim_proposal_id = id
    end

    def set_title
      @title = @nokogiri_document.css("#page-title h1").text.strip
    end

    def set_short_description
      @short_description = @nokogiri_document.css(".field-name-field-descriptif .field-item.even").children.to_s.strip
    end

    def set_description
      @description = @nokogiri_document.css("div.description").children.to_s.strip
    end

    def set_calendars
      @calendars = @nokogiri_document.css("div.calendars a")&.map do |nokogiri_element|
        relative_path = nokogiri_element.attributes["href"].value
        next if relative_path.blank?

        "#{@base_url}#{relative_path}"
      end
    end

    def set_pdf_attachments
      unique_links = []
      @pdf_attachments = @nokogiri_document.css("a.doc-name")&.map do |link|
        next if link["href"].blank?
        next unless link["href"].include?(".pdf")
        next if link.text.blank?
        next if unique_links.include?(link["href"])

        unique_links << link["href"]
        { title: link.text&.strip, href: link["href"] }
      end.compact.uniq
    end

    def set_drupal_type
      @drupal_type = @nokogiri_document.css(".attr-list li")&.map do |li|
        li if li.text.include?("Type :")
      end.compact.first&.text&.split("\n")&.map(&:strip).second.gsub("  ", " ")
    end

    def set_drupal_thematique
      @drupal_thematique = @nokogiri_document.css(".attr-list li")&.map do |li|
        li if li.text.include?("Thématique :")
      end.compact.first&.text&.split("\n")&.map(&:strip)&.second&.gsub("  ", " ")
    end

    def set_drupal_organization
      @drupal_organization = @nokogiri_document.css(".attr-list li")&.map do |li|
        li if li.text.include?("Porteur de la participation :")
      end.compact.first&.text&.split("\n")&.map(&:strip).second.gsub("  ", " ")
    end

    def set_drupal_author
      @drupal_author = @nokogiri_document.css(".attr-list li")&.map do |li|
        li if li.text.include?("Gestionnaire de la participation :")
      end.compact.first&.text&.split("\n")&.map(&:strip).second.gsub("  ", " ")
    end

    def set_drupal_node_id
      @short_url = @nokogiri_document.css("link[rel='shortlink']").attr("href").value
      @drupal_node_id = @short_url&.split("/")&.last || 0
    end

    def set_thematique
      breadcrumbs = @nokogiri_document.css("ol.breadcrumb li")
      @thematique = if breadcrumbs.length > 2
                      @nokogiri_document.css("ol.breadcrumb li")[-2].text&.strip
                    else
                      ""
                    end
    end

    def add_error(hash)
      return if hash.blank? || hash[:message].blank?

      @errors << hash
    end

    def save_json_resume!
      Dir.mkdir("tmp/drupal_import") unless File.exist?("tmp/drupal_import")
      Dir.mkdir("tmp/drupal_import/#{@md5}") unless File.exist?("tmp/drupal_import/#{@md5}")
      File.write("tmp/drupal_import/#{@md5}/#{@md5}.json", JSON.pretty_generate(attributes))
    end

    def save_csv_resume!
      file_path = "tmp/drupal_import/resume.csv"
      FileUtils.mkdir_p(File.dirname(file_path))
      file_exists = File.exist?(file_path) && !File.zero?(file_path)

      CSV.open(file_path, "a") do |csv|
        csv << migration_metadata.keys unless file_exists
        csv << migration_metadata.values
      end
    end

    def save!
      return if @html.blank?

      Dir.mkdir("tmp/drupal_import") unless File.exist?("tmp/drupal_import")
      Dir.mkdir("tmp/drupal_import/#{@md5}") unless File.exist?("tmp/drupal_import/#{@md5}")
      File.write("tmp/drupal_import/#{@md5}/#{@md5}.html", @html)
    end

    def base_url
      url = URI.parse(@url)
      "#{url.scheme}://#{url.host}"
    end
  end
end