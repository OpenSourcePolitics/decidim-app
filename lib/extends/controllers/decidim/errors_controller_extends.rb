# frozen_string_literal: true

# Backport from decidim_awesome main (NotFoundRedirect#redirect_to_custom_paths):
# custom redirects may point to another host, which Rails 7 refuses
# (ActionController::Redirecting::UnsafeRedirectError) unless allowed explicitly.
# Remove once decidim-decidim_awesome is upgraded past 0.12.6.
module ErrorsControllerExtends
  private

  def redirect_to_custom_paths
    destination = custom_redirects_destination(request.original_fullpath)
    redirect_to(destination, allow_other_host: true) if destination.present?
  end
end

Decidim::ErrorsController.prepend(ErrorsControllerExtends)
