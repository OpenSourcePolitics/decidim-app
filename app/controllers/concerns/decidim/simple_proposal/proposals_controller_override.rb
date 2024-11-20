# frozen_string_literal: true

module Decidim
  module SimpleProposal
    module ProposalsControllerOverride
      extend ActiveSupport::Concern

      included do
        def index
          if component_settings.participatory_texts_enabled?
            @proposals = Decidim::Proposals::Proposal
                         .where(component: current_component, deleted_at: nil)
                         .published
                         .not_hidden
                         .only_amendables
                         .includes(:category, :scope)
                         .order(position: :asc)
            render "decidim/proposals/proposals/participatory_texts/participatory_text"
          else
            @base_query = search
                          .result
                          .where(deleted_at: nil)
                          .published
                          .not_hidden

            @proposals = @base_query.includes(:component, :coauthorships)
            @all_geocoded_proposals = @base_query.geocoded

            @voted_proposals = if current_user
                                 Decidim::Proposals::ProposalVote.where(
                                   author: current_user,
                                   proposal: @proposals.pluck(:id)
                                 ).pluck(:decidim_proposal_id)
                               else
                                 []
                               end
            @proposals = paginate(@proposals)
            @proposals = reorder(@proposals)
          end
        end

        def new
          if proposal_draft.present?
            redirect_to edit_draft_proposal_path(proposal_draft, component_id: proposal_draft.component.id, question_slug: proposal_draft.component.participatory_space.slug)
          else
            enforce_permission_to :create, :proposal
            @step = Decidim::Proposals::ProposalsController::STEP1
            @proposal ||= Decidim::Proposals::Proposal.new(component: current_component)
            @form = form_proposal_model
            @form.body = translated_proposal_body_template
            @form.attachment = form_attachment_new
          end
        end

        def create
          enforce_permission_to :create, :proposal
          @step = Decidim::Proposals::ProposalsController::STEP1
          @form = form(Decidim::Proposals::ProposalForm).from_params(proposal_creation_params)

          @proposal = Decidim::Proposals::Proposal.new(@form.attributes.except(
            :user_group_id,
            :category_id,
            :scope_id,
            :has_address,
            :attachment,
            :body_template,
            :suggested_hashtags,
            :photos,
            :add_photos,
            :documents,
            :add_documents,
            :require_category,
            :require_scope
          ).merge(
            component: current_component
          ))
          user_group = Decidim::UserGroup.find_by(
            organization: current_organization,
            id: params[:proposal][:user_group_id]
          )
          @proposal.add_coauthor(current_user, user_group: user_group)

          # We could set these when creating proposal, but We want to call update because after that proposal becomes persisted
          # and it adds coauthor correctly.
          @proposal.update(title: { I18n.locale => @form.attributes[:title] })
          @proposal.update(body: { I18n.locale => @form.attributes[:body] })

          Decidim::Proposals::UpdateProposal.call(@form, current_user, @proposal) do
            on(:ok) do |proposal|
              flash[:notice] = I18n.t("proposals.update_draft.success", scope: "decidim")
              redirect_to "#{Decidim::ResourceLocatorPresenter.new(proposal).path}/preview"
            end

            on(:invalid) do
              flash.now[:alert] = I18n.t("proposals.update_draft.error", scope: "decidim")
              render :new
            end
          end
        end

        # Overridden because of a core bug when the command posts the "invalid"
        # signal and when rendering the form.
        def update_draft
          enforce_permission_to :edit, :proposal, proposal: @proposal
          @step = Decidim::Proposals::ProposalsController::STEP1

          @form = form_proposal_params
          Decidim::Proposals::UpdateProposal.call(@form, current_user, @proposal) do
            on(:ok) do |proposal|
              flash[:notice] = I18n.t("proposals.update_draft.success", scope: "decidim")
              redirect_to "#{Decidim::ResourceLocatorPresenter.new(proposal).path}/preview"
            end

            on(:invalid) do
              flash.now[:alert] = I18n.t("proposals.update_draft.error", scope: "decidim")
              fix_form_photos_and_documents
              render :edit_draft
            end
          end
        end

        # On invalid render edit instead of edit_draft
        def update
          enforce_permission_to :edit, :proposal, proposal: @proposal

          @form = form_proposal_params

          Decidim::Proposals::UpdateProposal.call(@form, current_user, @proposal) do
            on(:ok) do |proposal|
              flash[:notice] = I18n.t("proposals.update.success", scope: "decidim")
              redirect_to Decidim::ResourceLocatorPresenter.new(proposal).path
            end

            on(:invalid) do
              flash.now[:alert] = I18n.t("proposals.update.error", scope: "decidim")
              fix_form_photos_and_documents
              render :edit
            end
          end
        end

        private

        def form_proposal_params
          form(Decidim::Proposals::ProposalForm).from_params(params)
        end

        def default_filter_params
          {
            search_text_cont: "",
            with_any_origin: default_filter_origin_params,
            activity: "all",
            with_any_category: default_filter_category_params,
            with_any_state: %w(accepted evaluating state_not_published not_answered rejected),
            with_any_scope: default_filter_scope_params,
            related_to: "",
            type: "all"
          }
        end

        def can_show_proposal?
          return false if @proposal&.deleted_at.present?
          return true if @proposal&.amendable? || current_user&.admin?

          Decidim::Proposals::Proposal.only_visible_emendations_for(current_user, current_component).published.include?(@proposal)
        end

        def fix_form_photos_and_documents
          return unless @form

          @form.photos = map_attachment_objects(@form.photos)
          @form.documents = map_attachment_objects(@form.documents)
        end

        # Maps the attachment objects for the proposal form in case there are errors
        # on the form when it is being saved. Without this, the form would throw
        # an exception because it expects these objects to be Attachment records.
        def map_attachment_objects(attachments)
          return attachments unless attachments.is_a?(Array)

          attachments.map do |attachment|
            if attachment.is_a?(String) || attachment.is_a?(Integer)
              Decidim::Attachment.find_by(id: attachment)
            else
              attachment
            end
          end
        end
      end
    end
  end
end
