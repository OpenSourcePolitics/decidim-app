# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Proposals
    describe ApplicationHelper do
      describe "#humanize_proposal_state" do
        subject { helper.humanize_proposal_state(state) }

        context "when it is accepted" do
          let(:state) { "accepted" }

          it { is_expected.to eq("Accepted") }
        end

        context "when it is rejected" do
          let(:state) { "rejected" }

          it { is_expected.to eq("Rejected") }
        end

        context "when it is nil" do
          let(:state) { nil }

          it { is_expected.to eq("Not answered") }
        end

        context "when it is withdrawn" do
          let(:state) { "withdrawn" }

          it { is_expected.to eq("Withdrawn") }
        end
      end

      describe "#render_proposal_body" do
        subject { helper.render_proposal_body(proposal) }

        before do
          allow(helper).to receive(:present).with(proposal).and_return(Decidim::Proposals::ProposalPresenter.new(proposal))
          allow(helper).to receive(:current_organization).and_return(proposal.organization)

          helper.request.env["warden"] = double(
            "Warden::Proxy",
            authenticate: nil,
            authenticate!: nil,
            authenticate?: false,
            user: nil
          )

          helper.instance_variable_set(:@proposal, proposal)
        end

        let(:body) { "<ul><li>First</li><li>Second</li><li>Third</li></ul><script>alert('OK');</script>" }
        let(:proposal_trait) { :participant_author }
        let(:proposal) { create(:proposal, proposal_trait, body: { "en" => body }) }

        it "renders a sanitized body" do
          expect(subject).to eq(
            <<~HTML.strip
              <p>• First
              <br />• Second
              <br />• Third
              </p>
            HTML
          )
        end

        context "with official proposal" do
          let(:proposal_trait) { :official }

          it "renders a sanitized body" do
            expect(subject).to eq(
              <<~HTML.sub(/\n$/, "")
                <div class="rich-text-display">
                <ul>
                <li>First</li>
                <li>Second</li>
                <li>Third</li>
                </ul>alert('OK');</div>
              HTML
            )
          end

          context "when the body includes images and iframes" do
            let(:body) do
              <<~HTML.strip
                <p><img src="/path/to/image.jpg" alt="Image"></p>
                <div class="editor-content-videoEmbed">
                  <div>
                    <iframe src="https://example.org/video/xyz" title="Video" frameborder="0" allowfullscreen="true"></iframe>
                  </div>
                </div>
              HTML
            end

            it "renders the image and iframe embed" do
              expect(subject).to eq(
                <<~HTML.strip
                  <div class="rich-text-display">
                  <p><img src="/path/to/image.jpg" alt="Image"></p>
                  <div class="editor-content-videoEmbed">
                    <div>
                      <div class="disabled-iframe"><!-- <iframe src="https://example.org/video/xyz" title="Video" frameborder="0" allowfullscreen="true" scrolling="no"></iframe> --></div>
                    </div>
                  </div>
                  </div>
                HTML
              )
            end
          end
        end
      end

      describe "#filter_proposals_state_values" do
        let(:component) { create(:proposal_component) }
        let!(:state1) { create(:proposal_state, component:, token: "accepted", weight: 2) }
        let!(:state2) { create(:proposal_state, component:, token: "rejected", weight: 1) }
        let!(:state3) { create(:proposal_state, component:, token: "evaluating", weight: 3) }
        let!(:state_not_answered) { create(:proposal_state, component:, token: "not_answered", weight: 0) }

        before do
          allow(helper).to receive(:current_component).and_return(component)
          allow(helper).to receive(:translated_attribute).and_call_original
          allow(helper).to receive(:t).and_call_original
        end

        it "returns a TreeNode structure" do
          result = helper.filter_proposals_state_values
          expect(result).to be_a(Decidim::CheckBoxesTreeHelper::TreeNode)
        end

        it "includes 'state_not_published' as second element" do
          result = helper.filter_proposals_state_values
          all_values = result.values.flatten.map(&:value)
          expect(all_values[1]).to eq("state_not_published")
        end

        it "orders proposal states by weight" do
          result = helper.filter_proposals_state_values
          all_values = result.values.flatten.map(&:value)
          main_states = all_values.select { |v| !v.match?(/_\d+$/) && v != "state_not_published" && v != "" }

          expect(main_states).to eq(%w(evaluating accepted rejected))
        end

        it "excludes 'not_answered' token from the list" do
          result = helper.filter_proposals_state_values
          all_values = result.values.flatten.map(&:value)

          expect(all_values).not_to include("not_answered")
        end

        it "includes all non-'not_answered' states" do
          result = helper.filter_proposals_state_values
          all_values = result.values.flatten.map(&:value)
          state_values = all_values.select { |v| !v.match?(/_\d+$/) && v != "state_not_published" && v != "" }

          expect(state_values).to include("accepted", "rejected", "evaluating")
        end

        context "when there are no proposal states" do
          let(:empty_component) { create(:proposal_component) }

          before do
            allow(helper).to receive(:current_component).and_return(empty_component)
          end

          it "returns state_not_published in values" do
            result = helper.filter_proposals_state_values
            all_values = result.values.flatten.map(&:value)

            expect(all_values).to include("state_not_published")
          end
        end

        context "when states have the same weight" do
          let!(:state4) { create(:proposal_state, component:, token: "custom_state", weight: 1) }

          it "includes all states with the same weight" do
            result = helper.filter_proposals_state_values
            all_values = result.values.flatten.map(&:value)
            state_values = all_values.select { |v| !v.match?(/_\d+$/) && v != "state_not_published" && v != "" }

            expect(state_values).to include("rejected", "custom_state")
          end
        end

        context "with weight ordering behavior" do
          it "places lower weight states first" do
            result = helper.filter_proposals_state_values
            all_values = result.values.flatten.map(&:value)
            main_states = all_values.select { |v| !v.match?(/_\d+$/) && v != "state_not_published" && v != "" }

            expect(main_states.first).to eq("evaluating")
          end

          it "places higher weight states last" do
            result = helper.filter_proposals_state_values
            all_values = result.values.flatten.map(&:value)
            main_states = all_values.select { |v| !v.match?(/_\d+$/) && v != "state_not_published" && v != "" }

            expect(main_states.last).to eq("rejected")
          end
        end
      end
    end
  end
end
