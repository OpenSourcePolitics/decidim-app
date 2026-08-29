# frozen_string_literal: true

module ApplicationHelperExtends
  def render_proposal_body(proposal)
    if awesome_proposal_custom_fields.present? ||
       awesome_config[:allow_images_in_editors] ||
       awesome_config[:allow_videos_in_editors]
      content = present(proposal).body(links: true, strip_tags: false)
      sanitized = decidim_sanitize_editor_admin(content, {})
      Decidim::ContentProcessor.render_without_format(sanitized).html_safe
    else
      decidim_render_proposal_body(proposal)
    end
  end
end

Decidim::Proposals::ApplicationHelper.prepend(ApplicationHelperExtends)
