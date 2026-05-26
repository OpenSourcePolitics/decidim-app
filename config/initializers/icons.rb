# frozen_string_literal: true

%w(
  pages-line
  stack-line
  price-tag-3-line
  bar-chart-line
  pen-nib-line
  coin-line
  discuss-line
  map-pin-line
  pages-line
  chat-new-line
  billiards-line
  survey-line
  node-tree
).each do |icon_name|
  Decidim.icons.register(name: icon_name, icon: icon_name, category: "system", description: "", engine: :core)
end
