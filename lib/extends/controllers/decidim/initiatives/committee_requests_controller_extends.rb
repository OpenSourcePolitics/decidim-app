# frozen_string_literal: true

module CommitteeRequestsControllerExtends
  def new
    return if authorized?(current_user)

    if current_user.nil?
      redirect_to decidim.new_user_session_path
    else
      authorization_method = Decidim::Verifications::Adapter.from_element(current_initiative.document_number_authorization_handler)
      redirect_url = new_initiative_committee_request_path(current_initiative)
      redirect_to authorization_method.root_path(redirect_url: redirect_url)
    end
  end

  private

  def authorized?(user)
    authorization = current_initiative.document_number_authorization_handler
    Decidim::Authorization.exists?(user: user, name: authorization)
  end
end

Decidim::Initiatives::CommitteeRequestsController.class_eval do
  prepend(CommitteeRequestsControllerExtends)
end
