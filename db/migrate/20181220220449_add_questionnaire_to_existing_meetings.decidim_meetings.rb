# frozen_string_literal: true

# This migration comes from decidim_meetings (originally 20181107175558)

class AddQuestionnaireToExistingMeetings < ActiveRecord::Migration[5.2]
  class Decidim::Meetings::Meeting
    self.table_name = :decidim_meetings_meetings

    include Decidim::Forms::HasQuestionnaire
  end

  def change
    Decidim::Meetings::Meeting.transaction do
      Decidim::Meetings::Meeting.find_each do |meeting|
        if meeting.questionnaire.blank?
          meeting.update!(
            questionnaire: Decidim::Forms::Questionnaire.new
          )
        end
      end
    end
  end
end
