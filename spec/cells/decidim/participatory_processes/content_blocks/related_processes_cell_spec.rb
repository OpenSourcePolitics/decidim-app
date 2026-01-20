# frozen_string_literal: true

require "spec_helper"

describe Decidim::ParticipatoryProcesses::ContentBlocks::RelatedProcessesCell, type: :cell do
  subject { cell(content_block.cell, content_block) }

  controller Decidim::ParticipatoryProcesses::ParticipatoryProcessesController

  let(:organization) { double("Organization") }
  let(:content_block) { double("ContentBlock", cell: "decidim/participatory_processes/content_blocks/related_processes", manifest_name:, settings:, scoped_resource_id: resource.id) }
  let(:manifest_name) { :related_processes }
  let(:settings) { double("Settings", try: nil) }
  let(:resource) { double("ParticipatoryProcess", id: 1, class: double(name: "Decidim::ParticipatoryProcess"), is_a?: true) }
  let(:related_processes) { Array.new(8) { |i| create_process_double(i) } }
  let(:linked_processes_relation) { double("ActiveRecord::Relation", published: double("ActiveRecord::Relation", all: related_processes)) }
  let(:cell_instance) { described_class.new(content_block) }

  before do
    allow(content_block).to receive(:settings).and_return(settings)
    allow(cell_instance).to receive(:resource).and_return(resource)
    allow(resource).to receive(:linked_participatory_space_resources).with(:participatory_processes, "related_processes").and_return(linked_processes_relation)
    allow(resource).to receive(:is_a?).with(Decidim::ParticipatoryProcess).and_return(true)
    allow(cell_instance).to receive(:render).and_return("<div class='card__grid'>Mock Content</div>".html_safe)
  end

  def create_process_double(index)
    process = double("ParticipatoryProcess_#{index}", id: index + 10)

    case index
    when 0, 6
      setup_upcoming_process(process, index)
    when 1, 4
      setup_active_process_with_end_date(process, index)
    when 2, 5
      setup_past_process(process, index)
    when 3, 7
      setup_active_process_without_end_date(process, index)
    end

    process
  end

  def setup_upcoming_process(process, index)
    allow(process).to receive(:active?).and_return(false)
    allow(process).to receive(:past?).and_return(false)
    allow(process).to receive(:upcoming?).and_return(true)
    allow(process).to receive(:start_date).and_return(index == 0 ? 1.day.from_now : 3.days.from_now)
    allow(process).to receive(:end_date).and_return(nil)
  end

  def setup_active_process_with_end_date(process, index)
    allow(process).to receive(:active?).and_return(true)
    allow(process).to receive(:past?).and_return(false)
    allow(process).to receive(:upcoming?).and_return(false)
    allow(process).to receive(:start_date).and_return(index == 1 ? 1.day.ago : 2.days.ago)
    allow(process).to receive(:end_date).and_return(index == 1 ? 1.day.from_now : 5.days.from_now)
  end

  def setup_past_process(process, index)
    allow(process).to receive(:active?).and_return(false)
    allow(process).to receive(:past?).and_return(true)
    allow(process).to receive(:upcoming?).and_return(false)
    allow(process).to receive(:start_date).and_return(index == 2 ? 10.days.ago : 15.days.ago)
    allow(process).to receive(:end_date).and_return(index == 2 ? 1.day.ago : 5.days.ago)
  end

  def setup_active_process_without_end_date(process, index)
    allow(process).to receive(:active?).and_return(true)
    allow(process).to receive(:past?).and_return(false)
    allow(process).to receive(:upcoming?).and_return(false)
    allow(process).to receive(:start_date).and_return(index == 3 ? 5.days.ago : 3.days.ago)
    allow(process).to receive(:end_date).and_return(nil)
  end

  describe "#show" do
    context "when there are related processes" do
      it "renders when total_count is positive" do
        expect(cell_instance.show).not_to be_nil
      end
    end

    context "when there are no related processes" do
      before do
        empty_relation = double("EmptyRelation", published: double("PublishedRelation", all: []))
        allow(resource).to receive(:linked_participatory_space_resources).and_return(empty_relation)
      end

      it "does not render when total_count is zero" do
        expect(cell_instance.show).to be_nil
      end
    end
  end

  describe "#related_processes" do
    context "when sorting is disabled" do
      before do
        allow(Decidim::Env).to receive(:new).with("DECIDIM_PARTICIPATORY_PROCESSES_SORT_BY_DATE", true).and_return(double(to_boolean_string: "false"))
      end

      it "returns processes without sorting" do
        expect(cell_instance.related_processes).to eq(related_processes)
      end
    end

    context "when sorting is enabled" do
      before do
        allow(Decidim::Env).to receive(:new).with("DECIDIM_PARTICIPATORY_PROCESSES_SORT_BY_DATE", true).and_return(double(to_boolean_string: "true"))
      end

      it "sorts the processes" do
        sorted_processes = cell_instance.related_processes
        active_with_end_date = [related_processes[1], related_processes[4]]
        active_without_end_date = [related_processes[3], related_processes[7]]
        upcoming = [related_processes[0], related_processes[6]]
        past = [related_processes[2], related_processes[5]]

        expected_sorted = active_with_end_date.sort_by(&:end_date) +
                          active_without_end_date +
                          upcoming.sort_by(&:start_date) +
                          past.sort_by { |p| -p.end_date.to_time.to_i }

        expect(sorted_processes).to eq(expected_sorted)
      end
    end
  end

  describe "#filtered_processes" do
    context "when no limit is set" do
      it "returns all processes" do
        expect(cell_instance.filtered_processes.size).to eq(8)
      end
    end

    context "when limit is set" do
      before do
        allow(settings).to receive(:try).with(:max_results).and_return(3)
      end

      it "returns the limited number of processes" do
        expect(cell_instance.filtered_processes.size).to eq(3)
      end

      it "uses take method to limit processes" do
        related_processes_array = cell_instance.related_processes
        limited_processes = related_processes_array.take(3)
        expect(limited_processes.size).to eq(3)
      end
    end
  end

  describe "#sort_processes_from" do
    let(:active_processes) { related_processes.select(&:active?) }
    let(:active_with_end_date) { active_processes.reject { |p| p.end_date.nil? } }
    let(:active_without_end_date) { active_processes.select { |p| p.end_date.nil? } }
    let(:upcoming_processes) { related_processes.select(&:upcoming?) }
    let(:past_processes) { related_processes.select(&:past?) }

    it "sorts active processes with end date by end date" do
      sorted = cell_instance.sort_processes_from(related_processes)
      expect(sorted[0..1]).to eq(active_with_end_date.sort_by(&:end_date))
    end

    it "puts active processes without end date after active processes with end date" do
      sorted = cell_instance.sort_processes_from(related_processes)
      expect(sorted[2..3].to_set).to eq(active_without_end_date.to_set)
    end

    it "sorts upcoming processes by start date and puts them after active processes" do
      sorted = cell_instance.sort_processes_from(related_processes)
      first_upcoming_index = sorted.index(upcoming_processes.first)
      expect(sorted[first_upcoming_index..(first_upcoming_index + 1)]).to eq(upcoming_processes.sort_by(&:start_date))
    end

    it "sorts past processes by end date descending and puts them last" do
      sorted = cell_instance.sort_processes_from(related_processes)
      first_past_index = sorted.index(past_processes.first)
      expect(sorted[first_past_index..(first_past_index + 1)]).to eq(past_processes.sort_by { |p| -p.end_date.to_time.to_i })
    end
  end

  describe "#processes_without_end_date" do
    it "returns only processes without end date" do
      active_processes = related_processes.select(&:active?)

      without_end_date = cell_instance.processes_without_end_date(active_processes)
      expect(without_end_date.count).to eq(2)
      expect(without_end_date).to include(related_processes[3])
      expect(without_end_date).to include(related_processes[7])
    end
  end

  describe "#total_count" do
    it "returns the number of related processes" do
      expect(cell_instance.total_count).to eq(8)
    end

    context "when there are no related processes" do
      before do
        empty_relation = double("EmptyRelation", published: double("PublishedRelation", all: []))
        allow(resource).to receive(:linked_participatory_space_resources).and_return(empty_relation)
      end

      it "returns zero" do
        expect(cell_instance.total_count).to eq(0)
      end
    end
  end

  describe "#link_name" do
    context "when resource is a participatory process" do
      it "returns 'related_processes'" do
        expect(cell_instance.send(:link_name)).to eq("related_processes")
      end
    end

    context "when resource is not a participatory process" do
      let(:assembly_resource) { double("Assembly", id: 2, class: double(name: "Decidim::Assembly")) }

      before do
        allow(cell_instance).to receive(:resource).and_return(assembly_resource)
        allow(assembly_resource).to receive(:is_a?).with(Decidim::ParticipatoryProcess).and_return(false)
      end

      it "returns 'included_participatory_processes'" do
        expect(cell_instance.send(:link_name)).to eq("included_participatory_processes")
      end
    end
  end
end
