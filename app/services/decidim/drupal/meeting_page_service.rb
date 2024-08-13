module Decidim
  module Drupal
    class MeetingPageService < Decidim::DrupalPage
      attr_reader :url, :slug, :md5, :nokogiri_document, :title, :description, :calendars, :short_description, :drupal_node_id, :thematique, :pdf_attachments, :participatory_process_url,
                  :decidim_participatory_process_id, :errors, :drupal_type, :drupal_author, :drupal_organization, :drupal_thematique, :address, :location, :date

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
          address: @address,
          location: @location,
          date: @date,
          errors: @errors
        }
      end

      def scrape
        fetch_html
        return if @nokogiri_document.blank?

        set_drupal_node_id
        set_title
        set_description
        set_address
        set_location
        set_date
        save!

        self
      rescue StandardError => e
        add_error(message: e.message)
        save!
        self
      end

      def set_description
        @description = @nokogiri_document.css("div.desc").children.to_s.strip
      end

      def set_address
        @address = @nokogiri_document.css("div.location div.field-item").children.to_s.strip
      end

      def set_location
        @location = @nokogiri_document.css("div.location.communes").children.to_s.strip
      end

      def set_date
        @date = Date.today # Default date to today
        date = @nokogiri_document.css("div.date.datedebut").children.to_s.strip
        return if date.blank?

        date = date.split(" ")
        months = {
          "janvier" => "01",
          "février" => "02",
          "mars" => "03",
          "avril" => "04",
          "mai" => "05",
          "juin" => "06",
          "juillet" => "07",
          "août" => "08",
          "septembre" => "09",
          "octobre" => "10",
          "novembre" => "11",
          "décembre" => "12"
        }
        date = date[2] + "-" + months[date[1]] + "-" + date[0]

        @date = Date.parse(date).strftime("%d-%m-%Y")
      end
    end
  end
end