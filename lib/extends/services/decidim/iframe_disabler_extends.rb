# frozen_string_literal: true

module IframeDisablerExtends
  def perform
    @document = Nokogiri::HTML::DocumentFragment.parse(@text)
    # disable_iframes(@document)
    document.to_html
  end
end

Decidim::IframeDisabler.class_eval do
  prepend(IframeDisablerExtends)
end
