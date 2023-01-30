# frozen_string_literal: true

require "spec_helper"

describe Decidim::Budgets::ProjectListItemCell, type: :cell do
  controller Decidim::Budgets::ProjectsController

  subject { cell_html }

  let(:my_cell) { cell("decidim/budgets/project_list_item", model) }
  let(:cell_html) { my_cell.call }
  let(:budget) { create(:budget, component: component) }
  let(:component) { create(:budgets_component) }
  let!(:project) { create(:project, component: component) }
  let(:model) { project }
  let(:user) { create :user, organization: project.participatory_space.organization }

  before do
    allow(controller).to receive(:current_user).and_return(user)
    allow(controller).to receive(:current_component).and_return(component)
    allow(controller).to receive(:current_participatory_space).and_return(component.participatory_space)
    allow(controller).to receive(:current_settings).and_return(component.settings)
    allow(controller.current_settings).to receive(:votes).and_return("enabled")
    allow(controller).to receive(:budget).and_return(budget)
  end

  describe "#cache_hash" do
    it "generate a unique hash" do
      old_hash = my_cell.send(:cache_hash)

      expect(my_cell.send(:cache_hash)).to eq(old_hash)
    end

    context "when locale change" do
      let(:alt_locale) { :ca }

      it "generate a different hash" do
        old_hash = my_cell.send(:cache_hash)
        allow(I18n).to receive(:locale).and_return(alt_locale)

        expect(my_cell.send(:cache_hash)).not_to eq(old_hash)
      end
    end

    context "when model is updated" do
      it "generate a different hash" do
        old_hash = my_cell.send(:cache_hash)
        model.update!(title: { en: "New title" })

        expect(my_cell.send(:cache_hash)).not_to eq(old_hash)
      end
    end

    context "when component settings changes" do
      it "generate a different hash" do
        old_hash = my_cell.send(:cache_hash)
        component.settings = { foo: "bar", votes: "enabled" }
        component.save!
        allow(controller).to receive(:current_settings).and_return(component.settings)
        allow(controller.current_settings).to receive(:votes).and_return("enabled")

        expect(my_cell.send(:cache_hash)).not_to eq(old_hash)
      end
    end

    context "when current user" do
      it "generate a hash" do
        old_hash = my_cell.send(:cache_hash)

        expect(my_cell.send(:cache_hash)).to eq(old_hash)
      end
      context "and user changes" do
        it "generate a different hash" do
          old_hash = my_cell.send(:cache_hash)
          allow(controller).to receive(:current_user).and_return(nil)

          expect(my_cell.send(:cache_hash)).not_to eq(old_hash)
        end
      end
    end

    context "and has an attachment" do
      let!(:attachment_1_pdf) { create(:attachment, :with_pdf, attached_to: model) }
      let!(:attachment_2_img) { create(:attachment, :with_image, attached_to: model) }
      let!(:attachment_3_pdf) { create(:attachment, :with_pdf, attached_to: model) }

      it "generate same hash" do
        old_hash = my_cell.send(:cache_hash)

        expect(my_cell.send(:cache_hash)).to eq(old_hash)
      end

      context "and photos is unpublished" do
        it "generate same hash" do
          old_hash = my_cell.send(:cache_hash)
          allow(model).to receive(:photos).and_return([])
          expect(my_cell.send(:cache_hash)).not_to eq(old_hash)
        end
      end
    end
  end
end
