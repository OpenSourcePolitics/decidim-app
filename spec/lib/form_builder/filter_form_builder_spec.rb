# frozen_string_literal: true

require "spec_helper"
require "nokogiri"

module Decidim
  describe FilterFormBuilder do
    let(:helper) { Class.new(ActionView::Base).new(ActionView::LookupContext.new(nil)) }
    let(:categories) do
      create_list(:category, 3)
      Category.all
    end
    let(:scopes) { create_list(:scope, 3) }

    let(:resource) do
      Class.new do
        attr_reader :order_start_time, :scope_id, :category_id
      end.new
    end

    let(:builder) { FilterFormBuilder.new(:resource, resource, helper, {}) }

    shared_examples "fieldset_wrapper" do
      it "wraps fields in a fieldset inside a div with class 'filters__section'" do
        expect(parsed.css(".filters__section fieldset")).not_to be_empty
      end

      it "adds a legend tag with a mini-title class inside with value provided by 'legend' option" do
        expect(parsed.css("legend.mini-title").first.text).to eq("Date")
      end
    end

    describe "#collection_radio_buttons" do
      let(:output) do
        builder.collection_radio_buttons :order_start_time, [%w(asc asc), %w(desc desc)], :first, :last, legend_title: "Date"
      end
      let(:parsed) { Nokogiri::HTML(output) }

      include_examples "fieldset_wrapper"

      it "renders the radio buttons inside its labels" do
        expect(parsed.css("label input")).not_to be_empty
      end
    end

    describe "#collection_check_boxes" do
      let(:output) do
        builder.collection_check_boxes :scope_id, scopes, :id, :name, legend_title: "Date"
      end
      let(:parsed) { Nokogiri::HTML(output) }

      include_examples "fieldset_wrapper"

      it "renders the check boxes inside its labels" do
        expect(parsed.css("label input")).not_to be_empty
      end
    end

    describe "#categories_select" do
      let(:output) do
        builder.categories_select :category_id, categories, legend_title: "Date", disable_parents: false, label: false, include_blank: true
      end
      let(:parsed) { Nokogiri::HTML(output) }

      include_examples "fieldset_wrapper"
    end

    describe "#digest" do
      it "returns a digest of the given parameter" do
        expect(builder.send(:digest, %w(a b c))).to eq("3a63b1c5da9cd4c9227c9d1ab4d67449")
        expect(builder.send(:digest, "a")).to eq("0cc175b9c0f1b6a831c399e269772661")
        expect(builder.send(:digest, 1)).to eq("c4ca4238a0b923820dcc509a6f75849b")
      end
    end
  end
end
