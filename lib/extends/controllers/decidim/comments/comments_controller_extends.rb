# frozen_string_literal: true

require "active_support/concern"
module CommentsControllerExtends
  extend ActiveSupport::Concern
  included do
    def update
      set_comment
      set_commentable
      enforce_permission_to(:update, :comment, comment:)

      form = Decidim::Comments::CommentForm.from_params(
        params.merge(commentable: comment.commentable, current_component:)
      ).with_context(
        current_user:,
        current_organization:
      )

      Decidim::Comments::UpdateComment.call(comment, form) do
        on(:ok) do
          respond_to do |format|
            format.js { render :update }
          end
        end

        on(:invalid) do
          respond_to do |format|
            format.js { render :update_error }
          end
        end
      end
    end

    def create
      enforce_permission_to(:create, :comment, commentable:)

      form = Decidim::Comments::CommentForm.from_params(
        params.merge(commentable:, current_component:)
      ).with_context(
        current_organization:,
        current_component:,
        current_user:
      )
      Decidim::Comments::CreateComment.call(form) do
        on(:ok) do |comment|
          handle_success(comment)
          respond_to do |format|
            format.js { render :create }
          end
        end

        on(:invalid) do
          @error = t("create.error", scope: "decidim.comments.comments")
          respond_to do |format|
            format.js { render :error }
          end
        end
      end
    end
  end
end

Decidim::Comments::CommentsController.include(CommentsControllerExtends)
