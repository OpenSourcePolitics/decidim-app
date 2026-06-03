# frozen_string_literal: true

# organization = Decidim::Organization.first
# bundler = Decidim::Content::CsvBundler.new(organization: organization)
# bundler.export_to_directory
#
# reload!; Decidim::Content::CsvBundler.new(organization: Decidim::Organization.first).export_to_directory

module Decidim
  module Content
    class CsvBundler
      include Decidim::Content::UidTools

      DEFAULT_OPTIONS = {
        flatten_json: false,
        export_mode: :archive
      }.freeze

      attr_reader :organization, :options

      def initialize(organization:, **options)
        @organization = organization
        @options = DEFAULT_OPTIONS.merge(options)
      end

      def bundle
        @bundle ||= parse_bundle_manifests(
          [
            {
              path: "organization",
              serializer: Decidim::Content::OrganizationSerializer,
              collection: [organization]
            },
            {
              path: "users",
              serializer: Decidim::Content::UserSerializer,
              collection: organization.users.reorder("id ASC")
            },
            {
              path: "scopes",
              serializer: Decidim::Content::ScopeSerializer,
              collection: organization.scopes.includes(:scope_type).reorder("id ASC")
            },
            {
              path: "areas",
              serializer: Decidim::Content::AreaSerializer,
              collection: organization.areas.includes(:area_type).reorder("id ASC")
            },
            {
              path: "participatory-processes",
              children: [
                {
                  path: "participatory-process-groups",
                  serializer: Decidim::Content::ParticipatoryProcessGroupSerializer,
                  collection: Decidim::ParticipatoryProcessGroup.where(organization:).reorder("id ASC")
                },
                {
                  path: ->(resource) { uid(resource) },
                  collection: Decidim::ParticipatoryProcess.where(organization:).reorder("id ASC"),
                  children: [
                    {
                      path: "participatory-process",
                      serializer: Decidim::Content::ParticipatoryProcessSerializer,
                      collection: ->(parent) { [parent] }
                    },
                    {
                      path: "steps",
                      serializer: Decidim::Content::ParticipatoryProcessStepSerializer,
                      collection: ->(parent) { parent.steps.reorder("start_date ASC") }
                    },
                    {
                      path: "categories",
                      serializer: Decidim::Content::CategorySerializer,
                      collection: ->(parent) { parent.categories }
                    },
                    {
                      path: "attachment_collections",
                      serializer: Decidim::Content::AttachmentCollectionSerializer,
                      collection: ->(parent) { parent.attachment_collections }
                    },
                    {
                      path: "attachments",
                      serializer: Decidim::Content::AttachmentSerializer,
                      collection: ->(parent) { parent.attachments }
                    },
                    {
                      path: "components",
                      serializer: Decidim::Content::ComponentSerializer,
                      collection: ->(parent) { parent.components }
                    },
                    {
                      path: "users",
                      serializer: Decidim::Content::ParticipatorySpaceUserSerializer,
                      collection: ->(parent) { participatory_process_users(parent) }
                    }
                  ]
                }
              ]
            }
          ]
        )
      end

      def export_to_directory
        bundle.each do |exportable|
          exportable_path = File.join(local_export_path, "#{exportable[:path]}.csv")
          FileUtils.mkdir_p(File.dirname(exportable_path))
          File.write(exportable_path, exportable[:data])
        end.count
      end

      def export_to_archive
        buffer = Zip::OutputStream.write_buffer do |output|
          bundle.each do |exportable|
            output.put_next_entry("#{exportable[:path]}.csv")
            output.write(exportable[:data])
          end
        end
        buffer.rewind
        buffer
        # File.binwrite("#{local_export_path}.zip", buffer.read)

        # blob = ActiveStorage::Blob.create_and_upload!(io: buffer, filename: "#{archive_name}.zip", content_type: "application/zip")
        # puts "Download link is : #{root_url}#{Rails.application.routes.url_helpers.rails_blob_url(blob, only_path: true)}"
      end

      private

      # rubocop:disable Metrics/PerceivedComplexity
      def parse_bundle_manifests(bundle_manifests, object: nil)
        bundle_manifests.each.with_index.inject([]) do |bundle_results, (bundle_manifest, index)|
          manifest = bundle_manifest.dup
          results = []

          begin
            validate_manifest!(manifest, object:)

            manifest[:collection] = manifest[:collection].call(object) if manifest[:collection].respond_to?(:call)

            if manifest[:serializer].present?
              if manifest[:collection].present?
                results << manifest.merge(
                  path: compute_path(manifest[:path], object:, index:),
                  data: generate_csv_for(manifest)
                )
              end
            elsif manifest[:children].present?
              if manifest[:collection].present?
                results.concat(
                  manifest[:collection].each.with_index.inject([]) do |collection_results, (collection_item, collection_index)|
                    collection_item_results = parse_bundle_manifests(manifest[:children], object: collection_item)
                    add_prefix_path_to_children(collection_item_results, prefix: compute_path(manifest[:path], object: collection_item, index: collection_index + index))
                    collection_results.concat(collection_item_results)
                  end
                )
              else
                manifest[:path] = compute_path(manifest[:path], object:, index:)
                results.concat(parse_bundle_manifests(manifest[:children], object:))
                add_prefix_path_to_children(results, prefix: manifest[:path])
              end
            end
            bundle_results.concat(results)
          rescue ArgumentError => e
            Rails.logger.error "#{e.message}. Manifest will be ignored."
            Rails.logger.error "Manifest : #{inspect_manifest(manifest)}"
            next bundle_results
          end
        end
      end
      # rubocop:enable Metrics/PerceivedComplexity

      # rubocop:disable Metrics/CyclomaticComplexity
      # rubocop:disable Metrics/PerceivedComplexity
      def validate_manifest!(manifest, object: nil)
        raise ArgumentError, "Manifest must have a path" if manifest[:path].nil?

        raise ArgumentError, "Manifest with serializer must have a collection" if manifest[:serializer].present? && manifest[:collection].blank?

        raise ArgumentError, "Manifest with both children and serializer are not yet supported" if manifest[:children].present? && manifest[:serializer].present?

        if manifest[:path].respond_to?(:call) && object.nil? && manifest[:collection].nil?
          raise ArgumentError, "Manifest path is a lambda but no object or collection were provided to compute it"
        end

        raise ArgumentError, "Manifest collection is a lambda but no object was provided to compute it" if manifest[:collection].respond_to?(:call) && object.nil?
      end
      # rubocop:enable Metrics/CyclomaticComplexity
      # rubocop:enable Metrics/PerceivedComplexity

      def compute_path(path, object: nil, index: nil)
        path = path.call(object) if path.respond_to?(:call) && !object.nil?
        path = "#{format("%02d", index + 1)}---#{path}" if index.present?
        path
      end

      def add_prefix_path_to_children(manifests, prefix: "")
        manifests.each do |manifest|
          manifest[:path] = File.join(prefix, manifest[:path])
        end
      end

      def inspect_manifest(manifest)
        manifest.merge(
          children_count: manifest[:children]&.size,
          collection: manifest[:collection]&.class&.name
        ).except(:children).to_s
      end

      def bundle_prefix
        "#{organization.host.parameterize}--#{Time.zone.now.strftime("%Y%m%d%H%M%S")}"
      end

      def local_export_path
        @local_export_path ||= Rails.root.join("tmp/exports/content", bundle_prefix)
      end

      def csv_options
        @csv_options ||= {
          col_sep: ","
        }
      end

      def generate_csv_for(exportable)
        Decidim::Content::CsvExporter.new(
          collection: exportable[:collection],
          serializer: exportable[:serializer],
          flatten: options[:flatten_json],
          csv_options:
        ).export.read
      end

      def participatory_process_users(participatory_process)
        users_with_roles = participatory_process.user_roles.select(:decidim_user_id, :role).reorder("decidim_user_id").to_a
        private_users = participatory_process.users.select(:decidim_user_id).reorder("decidim_user_id").to_a
        (users_with_roles + private_users).uniq(&:decidim_user_id).map { |o| o.attributes.compact.symbolize_keys.merge(role: o.role || "private_user") }
      end
    end
  end
end
