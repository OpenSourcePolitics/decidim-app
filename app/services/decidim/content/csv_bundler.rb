# frozen_string_literal: true

# organization = Decidim::Organization.first
# bundler = Decidim::Content::CsvBundler.new(organization: organization)
# bundler.export_to_directory
#
# reload!; Decidim::Content::CsvBundler.new(organization: Decidim::Organization.first).export_to_directory

module Decidim
  module Content
    class CsvBundler
      include Decidim::Content::ComponentTools

      DEFAULT_OPTIONS = {
        export_mode: :archive,
        serializers: {
          flatten_json: false,
          private_fields: false
        },
        csv: {
          col_sep: ","
        }
      }.freeze

      attr_reader :organization, :options

      def initialize(organization:, **options)
        @organization = organization
        @options = DEFAULT_OPTIONS.deep_merge(options)
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
              collection: organization.user_entities.not_blocked.reorder("id ASC")
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
                    *participatory_space_shared_bundle_array,
                    **components_bundle_hash
                  ]
                }
              ]
            },
            {
              path: "assemblies",
              children: [
                {
                  path: "assembly-types",
                  serializer: Decidim::Content::AssembliesTypeSerializer,
                  collection: Decidim::AssembliesType.where(organization:).reorder("id ASC")
                },
                {
                  path: ->(resource) { uid(resource) },
                  collection: Decidim::Assembly.where(organization:).reorder("id ASC"),
                  children: [
                    {
                      path: "assembly",
                      serializer: Decidim::Content::AssemblySerializer,
                      collection: ->(parent) { [parent] }
                    },
                    *participatory_space_shared_bundle_array,
                    {
                      path: "members",
                      serializer: Decidim::Content::AssemblyMemberSerializer,
                      collection: ->(parent) { parent.members.includes(:user).reorder("id ASC") }
                    },
                    **components_bundle_hash
                  ]
                }
              ]
            }
          ]
        )
      end

      def participatory_space_shared_bundle_array
        @participatory_space_shared_bundle_array ||= [
          {
            path: "categories",
            serializer: Decidim::Content::CategorySerializer,
            collection: ->(parent) { parent.categories }
          },
          {
            path: "attachment-collections",
            serializer: Decidim::Content::AttachmentCollectionSerializer,
            collection: ->(parent) { parent.attachment_collections }
          },
          {
            path: "attachments",
            serializer: Decidim::Content::AttachmentSerializer,
            collection: ->(parent) { parent.attachments }
          },
          {
            path: "users",
            serializer: Decidim::Content::ParticipatorySpaceUserSerializer,
            collection: ->(parent) { participatory_space_users(parent) }
          }
          # TODO : followers
        ]
      end

      def components_bundle_hash
        @components_bundle_hash ||= {
          path: "components",
          children: [
            {
              path: ->(resource) { "#{uid(resource)}---#{resource.try(:manifest_name)}" },
              collection: ->(parent) { parent.components },
              children: [
                {
                  path: "component",
                  serializer: Decidim::Content::ComponentSerializer,
                  collection: ->(parent) { [parent] }
                },
                {
                  path: "statuses",
                  serializer: Decidim::Content::AccountabilityStatusSerializer,
                  collection: ->(parent) { Decidim::Accountability::Status.where(component: parent) }
                },
                {
                  path: "results",
                  serializer: Decidim::Content::AccountabilityResultSerializer,
                  collection: ->(parent) { accountability_results_for_component(parent).includes(:category) }
                },
                # TODO : before proposals -> states
                {
                  path: "proposal-states",
                  include_if: ->(parent) { parent&.manifest_name == "proposals" },
                  serializer: Decidim::Content::ProposalStateSerializer,
                  collection: ->(parent) { Decidim::Proposals::ProposalState.where(component: parent) }
                },
                {
                  path: "proposals",
                  include_if: ->(parent) { parent&.manifest_name == "proposals" },
                  serializer: Decidim::Content::ProposalSerializer,
                  collection: ->(parent) { proposals_for_component(parent).includes(:category) }
                },
                {
                  path: "debates",
                  include_if: ->(parent) { parent&.manifest_name == "debates" },
                  serializer: Decidim::Content::DebateSerializer,
                  collection: ->(parent) { debates_for_component(parent).includes(:category) }
                },
                {
                  path: "posts",
                  include_if: ->(parent) { parent&.manifest_name == "blogs" },
                  serializer: Decidim::Content::PostSerializer,
                  collection: ->(parent) { posts_for_component(parent) }
                },
                {
                  path: "sortitions",
                  include_if: ->(parent) { parent&.manifest_name == "sortitions" },
                  serializer: Decidim::Content::SortitionSerializer,
                  collection: ->(parent) { sortitions_for_component(parent) }
                },
                *components_bundle_for_budgets_array,
                *components_bundle_for_meetings_array,
                {
                  path: "attachment-collections",
                  include_if: ->(parent) { component_has_attachments?(parent&.manifest_name) && %w(budgets meetings).exclude?(parent&.manifest_name) },
                  serializer: Decidim::Content::AttachmentCollectionSerializer,
                  collection: ->(parent) { attachment_collections_for_component(parent) }
                },
                {
                  path: "attachments",
                  include_if: ->(parent) { component_has_attachments?(parent&.manifest_name) && %w(budgets meetings).exclude?(parent&.manifest_name) },
                  serializer: Decidim::Content::AttachmentSerializer,
                  collection: ->(parent) { attachments_for_component(parent) }
                },
                {
                  path: "comments",
                  include_if: ->(parent) { commentable_component?(parent&.manifest_name) && %w(budgets meetings).exclude?(parent&.manifest_name) },
                  serializer: Decidim::Content::CommentSerializer,
                  collection: ->(parent) { comments_for_component(parent) }
                },
                {
                  path: "comments-votes",
                  include_if: ->(parent) { commentable_component?(parent&.manifest_name) && %w(budgets meetings).exclude?(parent&.manifest_name) },
                  serializer: Decidim::Content::CommentVoteSerializer,
                  collection: ->(parent) { comment_votes_for_component(parent) }
                },
                {
                  path: "answers",
                  include_if: ->(parent) { parent&.manifest_name == "surveys" },
                  serializer: Decidim::Content::QuestionnaireAnswersSerializer,
                  collection: lambda { |parent|
                    survey = Decidim::Surveys::Survey.find_by(component: parent)
                    Decidim::Forms::QuestionnaireUserAnswers.for(survey.questionnaire)
                  }
                },
                {
                  path: "proposal-votes",
                  include_if: ->(parent) { parent&.manifest_name == "proposals" },
                  serializer: Decidim::Content::ProposalVoteSerializer,
                  collection: lambda { |parent|
                    Decidim::Proposals::ProposalVote.where(decidim_proposal_id: proposals_for_component(parent).pluck(:id))
                  }
                },
                {
                  path: "proposal-notes",
                  include_if: ->(parent) { parent&.manifest_name == "proposals" },
                  serializer: Decidim::Content::ProposalNoteSerializer,
                  collection: lambda { |parent|
                    Decidim::Proposals::ProposalNote.where(decidim_proposal_id: proposals_for_component(parent).pluck(:id))
                  }
                },
                {
                  path: "endorsements",
                  include_if: ->(parent) { endorsable_component?(parent&.manifest_name) },
                  serializer: Decidim::Content::EndorsementSerializer,
                  collection: ->(parent) { endorsements_for_component(parent) }
                },
                {
                  path: "followers",
                  include_if: ->(parent) { followable_component?(parent&.manifest_name) && %w(budgets meetings).exclude?(parent&.manifest_name) },
                  serializer: Decidim::Content::FollowerSerializer,
                  collection: ->(parent) { followers_for_component(parent) }
                }
              ]
            }
          ]
        }
      end

      def components_bundle_for_budgets_array
        # A budget component can have multiple budgets, and each budget can have multiple projects.
        # So we create a folder for each budget, and inside that folder we create a folder for each project.
        [
          {
            path: ->(resource) { uid(resource) },
            include_if: ->(parent) { parent&.manifest_name == "budgets" },
            collection: ->(parent) { Decidim::Budgets::Budget.where(component: parent).reorder(:weight, :id) },
            children: [
              {
                path: "budget",
                serializer: Decidim::Content::BudgetSerializer,
                collection: ->(parent) { [parent] }
              },
              {
                path: "projects",
                serializer: Decidim::Content::BudgetProjectSerializer,
                collection: ->(parent) { projects_for_budget(parent).includes(:category, :budget) }
              },
              {
                path: "orders",
                serializer: Decidim::Content::BudgetOrderSerializer,
                collection: ->(parent) { Decidim::Budgets::Order.where(budget: parent).includes(:line_items) }
              },
              {
                path: "attachment-collections",
                serializer: Decidim::Content::AttachmentCollectionSerializer,
                collection: ->(parent) { Decidim::AttachmentCollection.where(collection_for: projects_for_budget(parent)) }
              },
              {
                path: "attachments",
                serializer: Decidim::Content::AttachmentSerializer,
                collection: ->(parent) { Decidim::Attachment.where(attached_to: projects_for_budget(parent)) }
              },
              {
                path: "comments",
                serializer: Decidim::Content::CommentSerializer,
                collection: ->(parent) { comments_for_budget(parent) }
              },
              {
                path: "comment-votes",
                serializer: Decidim::Content::CommentVoteSerializer,
                collection: ->(parent) { comment_votes_for_budget(parent) }
              },
              {
                path: "followers",
                serializer: Decidim::Content::FollowerSerializer,
                collection: ->(parent) { Decidim::Follow.where(followable: projects_for_budget(parent)) }
              }
            ]
          }
        ]
      end

      def components_bundle_for_meetings_array
        # There is too much data associated with a meeting (registrations, questionnaire + answers, attachments, comments, etc.)
        # so we create a folder for each meeting to help organize the data.
        [
          {
            path: ->(resource) { uid(resource) },
            include_if: ->(parent) { parent&.manifest_name == "meetings" },
            collection: ->(parent) { meetings_for_component(parent).includes(:category, :questionnaire) },
            children: [
              {
                path: "meeting",
                serializer: Decidim::Content::MeetingSerializer,
                collection: ->(parent) { [parent] }
              },
              {
                path: "invites",
                serializer: Decidim::Content::MeetingInviteSerializer,
                collection: ->(parent) { invites_for_meeting(parent) }
              },
              {
                path: "registrations",
                serializer: Decidim::Content::MeetingRegistrationSerializer,
                collection: ->(parent) { registrations_for_meeting(parent) }
              },
              {
                path: "registrations-answers",
                serializer: Decidim::Content::QuestionnaireAnswersSerializer,
                include_if: ->(parent) { parent.try(:questionnaire).present? },
                collection: ->(parent) { Decidim::Forms::QuestionnaireUserAnswers.for(parent.questionnaire) }
              },
              {
                path: "poll-answers",
                serializer: Decidim::Content::MeetingPollAnswersSerializer,
                include_if: ->(parent) { parent.try(:poll).try(:questionnaire).present? },
                collection: ->(parent) { Decidim::Meetings::QuestionnaireUserAnswers.for(parent.poll.questionnaire) }
              },
              {
                path: "attachment-collections",
                serializer: Decidim::Content::AttachmentCollectionSerializer,
                collection: ->(parent) { Decidim::AttachmentCollection.where(collection_for: meetings_for_component(parent)) }
              },
              {
                path: "attachments",
                serializer: Decidim::Content::AttachmentSerializer,
                collection: ->(parent) { Decidim::Attachment.where(attached_to: meetings_for_component(parent)) }
              },
              {
                path: "comments",
                serializer: Decidim::Content::CommentSerializer,
                collection: ->(parent) { comments_for_meeting(parent) }
              },
              {
                path: "comment-votes",
                serializer: Decidim::Content::CommentVoteSerializer,
                collection: ->(parent) { comment_votes_for_meeting(parent) }
              },
              {
                path: "followers",
                serializer: Decidim::Content::FollowerSerializer,
                collection: ->(parent) { Decidim::Follow.where(followable: meetings_for_component(parent)) }
              }
            ]
          }
        ]
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

      # rubocop:disable Metrics/CyclomaticComplexity
      # rubocop:disable Metrics/PerceivedComplexity
      def parse_bundle_manifests(bundle_manifests, object: nil)
        index = 0
        bundle_manifests.each.inject([]) do |bundle_results, bundle_manifest|
          manifest = bundle_manifest.dup
          results = []

          begin
            validate_manifest!(manifest, object:)

            next bundle_results if manifest[:include_if].present? && !manifest[:include_if].call(object)

            index += 1

            manifest[:collection] = manifest[:collection].call(object) if manifest[:collection].respond_to?(:call)

            if manifest[:serializer].present?
              if manifest[:collection].present?
                results << manifest.merge(
                  path: compute_path(manifest[:path], object:, index:),
                  data: generate_csv_for(manifest)
                )
              else
                # if manifest[:collection] is empty, we restore the index to avoid gaps in the numbering of the next manifest with a collection.
                index -= 1
              end
            elsif manifest[:children].present?
              if manifest[:collection] # .present? doesn't fit in this case because [] is a valid candidate
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
      # rubocop:enable Metrics/CyclomaticComplexity

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
        path = "#{format("%02d", index)}---#{path}" if index.present?
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

      def generate_csv_for(exportable)
        Decidim::Content::CsvExporter.new(
          collection: exportable[:collection],
          serializer: exportable[:serializer],
          **options.slice(:serializers, :csv)
        ).export.read
      end

      def participatory_space_users(participatory_space)
        users_with_roles = participatory_space.user_roles.select(:decidim_user_id, :role).reorder("decidim_user_id").to_a
        private_users = participatory_space.users.select(:decidim_user_id).reorder("decidim_user_id").to_a
        (users_with_roles + private_users).uniq(&:decidim_user_id).map { |o| o.attributes.compact.symbolize_keys.merge(role: o[:role] || "private_user") }
      end
    end
  end
end
