# frozen_string_literal: true

require "spec_helper"

describe "rake decidim:repare:search", type: :task do
  let(:task_cmd) { :"decidim:repare:search" }

  let!(:organization) { create(:organization) }
  let!(:users) { create_list(:user, 3, organization: organization) }
  let!(:participatory_process_1) { create(:participatory_process, organization: organization) }
  let!(:component) { create :component, participatory_space: participatory_process_1, manifest_name: "blogs" }
  let!(:post) { create(:post, component: component, author: users.first) }
  let!(:comment) { create(:comment, commentable: post, author: users.last) }
  let!(:participatory_process_group) { create(:participatory_process_group, organization: organization) }
  let!(:participatory_process_2) { create(:participatory_process, organization: organization, participatory_process_group: participatory_process_group) }

  before do
    # ParticipatoryProcess are not indexed by default
    participatory_process_1.try_update_index_for_search_resource
    participatory_process_2.try_update_index_for_search_resource
  end

  after do
    Rake::Task[task_cmd].reenable
  end

  context "when executing task" do
    it "doesn't updates the search data" do
      expect { Rake::Task[task_cmd].invoke }.to change(Decidim::SearchableResource, :count).by(0)
    end

    context "when a component has been deleted" do
      before do
        component.destroy
      end

      it "updates the search data" do
        # The post and the comment are not indexed anymore because the component has been deleted
        # Each resource has 2 SearchableResource records (one per locale)
        # Therefore we expect to have 4 SearchableResource records less
        expect { Rake::Task[task_cmd].invoke }.to change(Decidim::SearchableResource, :count).by(-Decidim.available_locales.count * 2)
      end
    end
  end
end
