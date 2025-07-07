# frozen_string_literal: true

# Meetings

Deface::Override.new(virtual_path: "decidim/meetings/shared/_index",
                     name: "replace_default_meetings_map",
                     replace: "erb[silent]:contains('if display_map')",
                     closing_selector: "erb[silent]:contains('end')",
                     text: <<~ERB
                        <% if display_map && defined? current_participatory_space %>
                         <%= cell("decidim/geo/content_blocks/geo_maps", current_participatory_space,
                           id: "Meetings",
                           hide_empty: true,
                           is_index: false,
                           is_group: false,
                           filters: if current_participatory_space.scope.present?
                               [
                                 { scopeFilter: { scopeId: current_participatory_space.scope.id } }
                               ]
                           else
                               []
                           end,
                           scopes: if current_participatory_space.scope.present?
                               [current_participatory_space.scope.id]
                           else
                               []
                           end
                         ) %>
                       <% end %>
                     ERB
                    )
