# frozen_string_literal: true

# TODO: remove when [https://github.com/decidim/decidim/pull/15367] will be backport in 0.29

module MenuHelperExtends
  def menu_highlighted_participatory_process
    return if current_user.blank? && current_organization&.force_users_to_authenticate_before_access_organization

    @menu_highlighted_participatory_process ||= (
      # The queries already include the order by weight
      Decidim::ParticipatoryProcesses::OrganizationParticipatoryProcesses.new(current_organization) |
        Decidim::ParticipatoryProcesses::PromotedParticipatoryProcesses.new
    ).select(&:published?).map { |process| remove_private_space_if_not_private_user(process) }&.compact&.first
  end

  def remove_private_space_if_not_private_user(process)
    return nil if process.private_space == true && !process.can_participate?(current_user)

    process
  end
end

Decidim::MenuHelper.module_eval do
  prepend(MenuHelperExtends)
end
