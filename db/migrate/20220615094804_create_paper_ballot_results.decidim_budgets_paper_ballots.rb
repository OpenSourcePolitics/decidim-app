# frozen_string_literal: true
# This migration comes from decidim_budgets_paper_ballots (originally 20211226121530)

 class CreatePaperBallotResults < ActiveRecord::Migration[5.2]
   def change
     create_table :decidim_budgets_paper_ballot_results do |t|
       t.integer :votes, null: false
       t.references :decidim_project, null: false, foreign_key: { to_table: :decidim_budgets_projects }, index: { name: :index_decidim_paper_ballot_on_project }
       t.timestamps
     end
   end
 end
