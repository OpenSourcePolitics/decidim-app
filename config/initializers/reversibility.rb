# frozen_string_literal: true

Decidim.menu :admin_menu do |menu|
  menu.add_item :content,
                I18n.t("menu.reversibility", scope: "decidim.admin", default: "Content Tree"),
                decidim_admin.content_root_path,
                icon_name: "node-tree",
                position: 15,
                active: is_active_link?(decidim_admin.content_root_path),
                if: allowed_to?(:update, :organization, organization: current_organization)
end
