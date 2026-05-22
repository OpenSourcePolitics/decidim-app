# frozen_string_literal: true

module MenuItemPresenterExtends
  extend ActiveSupport::Concern

  included do
    def render
      content_tag :li, role: :presentation, class: link_wrapper_classes do
        output = if url == "#"
                   [content_tag(:span, composed_label, class: "sidebar-menu__item-disabled", role: :menuitem)]
                 else
                   [link_to(composed_label, url, link_options.merge(role: :menuitem))]
                 end
        output.push(@view.send(:simple_menu, **@menu_item.submenu).render) if @menu_item.submenu

        safe_join(output)
      end
    end
  end
end

Decidim::MenuItemPresenter.class_eval do
  include(MenuItemPresenterExtends)
end
