# frozen_string_literal: true

require "spec_helper"

describe "Explore meetings", :slow, type: :system do
  include_context "with a component"
  let(:manifest_name) { "meetings" }

  let(:meetings_count) { 5 }
  let!(:meetings) do
    create_list(:meeting, meetings_count, :not_official, component: component)
  end

  before do
    component_scope = create :scope, parent: participatory_process.scope
    component_settings = component["settings"]["global"].merge!(scopes_enabled: true, scope_id: component_scope.id)
    component.update!(settings: component_settings)
  end

  describe "index" do
    it "shows all meetings for the given process" do
      visit_component
      expect(page).to have_selector(".card--meeting", count: meetings_count)

      meetings.each do |meeting|
        expect(page).to have_content(translated(meeting.title))
      end
    end

    context "with hidden meetings" do
      let(:meeting) { meetings.last }

      before do
        create :moderation, :hidden, reportable: meeting
      end

      it "does not list the hidden meetings" do
        visit_component

        expect(page).to have_selector(".card.card--meeting", count: meetings_count - 1)

        expect(page).to have_no_content(translated(meeting.title))
      end
    end

    context "when comments have been moderated" do
      let(:meeting) { create(:meeting, component: component) }
      let!(:comments) { create_list(:comment, 3, commentable: meeting) }
      let!(:moderation) { create :moderation, reportable: comments.first, hidden_at: 1.day.ago }

      it "displays unhidden comments count" do
        visit_component

        within("#meeting_#{meeting.id}") do
          within(".card__status") do
            within(".card-data__item:last-child") do
              expect(page).to have_content(2)
            end
          end
        end
      end
    end

    context "when filtering" do
      context "when filtering by origin" do
        let!(:component) do
          create(:meeting_component,
                 :with_creation_enabled,
                 participatory_space: participatory_process)
        end

        let!(:official_meeting) { create(:meeting, :official, component: component, author: organization) }
        let!(:user_group_meeting) { create(:meeting, :user_group_author, component: component) }

        context "with 'official' origin" do
          it "lists the filtered meetings" do
            visit_component

            within ".origin_check_boxes_tree_filter" do
              uncheck "All"
              check "Official"
            end

            expect(page).to have_no_content("6 MEETINGS")
            expect(page).to have_content("1 MEETING")
            expect(page).to have_css(".card--meeting", count: 1)

            within ".card--meeting" do
              expect(page).to have_content("Official meeting")
            end
          end
        end

        context "with 'groups' origin" do
          it "lists the filtered meetings" do
            visit_component

            within ".origin_check_boxes_tree_filter" do
              uncheck "All"
              check "Groups"
            end

            expect(page).to have_no_content("6 MEETINGS")
            expect(page).to have_content("1 MEETING")
            expect(page).to have_css(".card--meeting", count: 1)
            within ".card--meeting" do
              expect(page).to have_content(user_group_meeting.normalized_author.name)
            end
          end
        end

        context "with 'citizens' origin" do
          it "lists the filtered meetings" do
            visit_component

            within ".origin_check_boxes_tree_filter" do
              uncheck "All"
              check "Citizens"
            end

            expect(page).to have_no_content("6 MEETINGS")
            expect(page).to have_css(".card--meeting", count: meetings_count)
            expect(page).to have_content("#{meetings_count} MEETINGS")
          end
        end
      end

      it "allows filtering by date" do
        past_meeting = create(:meeting, component: component, start_time: 1.day.ago)
        visit_component

        within ".date_check_boxes_tree_filter" do
          uncheck "All"
          check "Past"
        end

        expect(page).to have_css(".card--meeting", count: 1)
        expect(page).to have_content(translated(past_meeting.title))

        within ".date_check_boxes_tree_filter" do
          uncheck "All"
          check "Upcoming"
        end

        expect(page).to have_css(".card--meeting", count: 5)
      end

      it "allows filtering by scope" do
        scope = create(:scope, organization: organization)
        meeting = meetings.first
        meeting.scope = scope
        meeting.save

        visit_component

        within ".scope_id_check_boxes_tree_filter" do
          check "All"
          uncheck "All"
          check translated(scope.name)
        end

        expect(page).to have_css(".card--meeting", count: 1)
      end
    end

    context "when no upcoming meetings scheduled" do
      let!(:meetings) do
        create_list(:meeting, 2, component: component, start_time: Time.current - 4.days, end_time: Time.current - 2.days)
      end

      it "only shows the past meetings" do
        visit_component
        expect(page).to have_css(".card--meeting", count: 2)
      end

      it "shows the correct warning" do
        visit_component
        within ".callout" do
          expect(page).to have_content("no scheduled meetings")
        end
      end
    end

    context "when no meetings scheduled" do
      let!(:meetings) { [] }

      it "shows the correct warning" do
        visit_component
        within ".callout" do
          expect(page).to have_content("any meeting scheduled")
        end
      end
    end

    context "when paginating" do
      before do
        Decidim::Meetings::Meeting.destroy_all
      end

      let!(:collection) { create_list :meeting, collection_size, component: component }
      let!(:resource_selector) { ".card--meeting" }

      it_behaves_like "a paginated resource"
    end
  end
end
