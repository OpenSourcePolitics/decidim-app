# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Forms
    describe Answer do
      subject { answer }

      let(:organization) { create(:organization) }
      let(:user) { create(:user, organization:) }
      let(:participatory_process) { create(:participatory_process, organization:) }
      let(:questionnaire) { create(:questionnaire, questionnaire_for: participatory_process) }
      let(:question) { create(:questionnaire_question, questionnaire:) }
      let(:answer) { create(:answer, questionnaire:, question:, user:) }

      it { is_expected.to be_valid }

      it "has an association of questionnaire" do
        expect(subject.questionnaire).to eq(questionnaire)
      end

      it "has an association of question" do
        expect(subject.question).to eq(question)
      end

      it "has an association of user" do
        expect(subject.user).to eq(user)
      end

      context "when the user does not belong to the same organization" do
        it "is not valid" do
          subject.user = create(:user)
          expect(subject).not_to be_valid
        end
      end

      context "when question does not belong to the questionnaire" do
        it "is not valid" do
          subject.question = create(:questionnaire_question)
          expect(subject).not_to be_valid
        end
      end

      context "when a duplicate answer already exists (answer_extends.rb)" do
        let!(:existing_answer) { create(:answer, questionnaire:, question:, user:) }

        it "is not valid for the same user answering the same question again" do
          duplicate = build(:answer, questionnaire:, question:, user:)
          expect(duplicate).not_to be_valid
          expect(duplicate.errors[:decidim_question_id]).to be_present
        end

        context "and it is a different user" do
          let(:other_user) { create(:user, organization:) }

          it "is valid" do
            other_answer = build(:answer, questionnaire:, question:, user: other_user)
            expect(other_answer).to be_valid
          end
        end

        context "and it is a different question" do
          let(:other_question) { create(:questionnaire_question, questionnaire:) }

          it "is valid" do
            other_answer = build(:answer, questionnaire:, question: other_question, user:)
            expect(other_answer).to be_valid
          end
        end
      end

      context "when two unregistered answers share the same session_token" do
        let(:session_token) { "session-token-abc" }
        let!(:existing_answer) { create(:answer, questionnaire:, question:, user: nil, session_token:) }

        it "is not valid for a second answer with the same session_token on the same question" do
          duplicate = build(:answer, questionnaire:, question:, user: nil, session_token:)
          expect(duplicate).not_to be_valid
        end

        it "is valid for a different session_token" do
          other_answer = build(:answer, questionnaire:, question:, user: nil, session_token: "session-token-xyz")
          expect(other_answer).to be_valid
        end
      end
    end
  end
end
