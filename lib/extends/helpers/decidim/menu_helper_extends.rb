# frozen_string_literal: true

# TODO: remove when [https://github.com/decidim/decidim/pull/15367] will be backport in 0.29

module MenuHelperExtends
  def menu_highlighted_participatory_process
    return if current_user.blank? && current_organization&.force_users_to_authenticate_before_access_organization

    @menu_highlighted_participatory_process ||= (
      # The queries already include the order by weight
      Decidim::ParticipatoryProcesses::OrganizationParticipatoryProcesses.new(current_organization) |
        Decidim::ParticipatoryProcesses::PromotedParticipatoryProcesses.new
    ).select(&:published?)&.first
  end
end

Decidim::MenuHelper.module_eval do
  prepend(MenuHelperExtends)
end
