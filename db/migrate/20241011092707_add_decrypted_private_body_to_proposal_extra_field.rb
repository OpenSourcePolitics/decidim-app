# frozen_string_literal: true

class AddDecryptedPrivateBodyToProposalExtraField < ActiveRecord::Migration[6.1]
  class ProposalExtraField < ApplicationRecord
    self.table_name = :decidim_awesome_proposal_extra_fields
  end

  def change
    add_column :decidim_awesome_proposal_extra_fields, :decrypted_private_body, :string
  end
end
