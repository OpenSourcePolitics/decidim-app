# frozen_string_literal: true

module Decidim
  module Ai
    module SpamDetection
      # Hérite de Decidim::Events::BaseEvent
      # et inclut Decidim::Events::EmailEvent pour activer l'envoi d'emails.
      class SpamDigestEvent < Decidim::Events::BaseEvent
        include Decidim::Events::EmailEvent  # active l’envoi d’emails

        # 🔧 Types d’événements pris en charge :
        # :email → envoi d’un email via Decidim::NotificationMailer
        # :notification → affichage d’une notification dans l’interface admin
        def self.types
          [:email, :notification]
        end

        # RESSOURCE !

        # Decidim s’attend à ce que la ressource ait une méthode `.organization`.
        # Mais ici, la ressource *est déjà* une organisation (Decidim::Organization).
        # On l’emballe donc dans un petit objet OpenStruct avec un attribut .organization.
        def resource
          return @resource unless @resource.is_a?(Decidim::Organization)
          OpenStruct.new(organization: @resource)
        end

        # CONTENU DE L’EMAIL / NOTIFICATION ---

        # Texte d’introduction du mail (et du corps de la notification)
        def email_intro
          I18n.t(
            "decidim.ai.spam_detection.digest.summary",
            count: spam_count,
            frequency_label: frequency_label
          )
        end

        # Titre de la notification interne = même texte que l’intro du mail
        def notification_title
          email_intro
        end

        # Sujet de l'email
        def email_subject
          I18n.t(
            "decidim.ai.spam_detection.digest.subject",
            count: spam_count,
            frequency_label: frequency_label
          )
        end

        # Titre du bloc “ressource” dans le mail
        def resource_title
          org = organization

          # Récupère le nom localisé (FR > machine_translation > EN)
          org_name =
            org.name[I18n.locale.to_s].presence ||
              org.name.dig("machine_translations", I18n.locale.to_s).presence ||
              org.name["en"].presence ||
              org.name.values.compact.first

          # Traduction de la clé i18n avec interpolation du nom
          I18n.t(
            "decidim.ai.spam_detection.digest.title",
            organization: org_name
          )
        end

        # LOCALISATION / URL DE LA RESSOURCE

        # Fournit à Decidim un objet qui sait générer .path et .url
        # Ce format est attendu par BaseEvent pour construire les liens.
        def resource_locator
          helpers = Decidim::Core::Engine.routes.url_helpers
          host = Decidim::Organization.first&.host || "localhost"

          # Petite classe locale avec les deux méthodes nécessaires
          Class.new do
            def initialize(path, url)
              @path = path
              @url = url
            end

            # Appelée par Decidim sans argument
            def path(_params = nil)
              @path
            end

            # Appelée par Decidim avec un argument facultatif (resource_url_params)
            def url(_params = nil)
              @url
            end
          end.new(
            resource_path,
            helpers.root_url(host: host, protocol: "http") # Ex: http://localhost:3000
          )
        end

        # ROUTE PRINCIPALE

        # Indique à Decidim où pointer le lien dans le mail
        # (ici, la page d’administration des modérations)
        def resource_path(_organization = nil)
          Decidim::Core::Engine.routes.url_helpers.admin_moderations_path
        rescue NoMethodError
          Decidim::Core::Engine.routes.url_helpers.root_path
        end

        # Empêche Decidim d’ajouter des infos supplémentaires dans le mail
        def show_extended_information?
          false
        end

        # ORGANISATION ASSOCIÉE ---

        # Récupère toujours une organisation, quelle que soit la ressource.
        # Evite les erreurs quand la ressource n’a pas de méthode .organization.
        def organization
          if @resource.is_a?(Decidim::Organization)
            @resource
          elsif @resource.respond_to?(:organization)
            @resource.organization
          elsif @resource.respond_to?(:component)
            @resource.component.participatory_space.organization
          else
            Decidim::Organization.first # fallback pour le dev
          end
        end

        private

        # Nombre de spams détectés (valeur par défaut = 0)
        def spam_count
          extra[:spam_count] || 0
        end

        def frequency_label
          I18n.t(
            "decidim.ai.spam_detection.digest.frequency_label.#{extra[:frequency] || 'daily'}"
          )
        end
      end
    end
  end
end
