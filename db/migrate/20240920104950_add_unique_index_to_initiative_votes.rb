class AddUniqueIndexToInitiativeVotes < ActiveRecord::Migration[6.1]
  def change
    add_index :decidim_initiatives_votes,
              [:decidim_initiative_id, :decidim_author_id, :decidim_scope_id],
              unique: true,
              name: "unique_initiative_votes_by_author_and_scope"
  end
end
