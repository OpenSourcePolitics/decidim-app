# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Forms
    describe UserAnswersSerializer do
      subject do
        described_class.new(questionnaire.answers)
      end

      let!(:questionable) { create(:dummy_resource) }
      let!(:questionnaire) { create(:questionnaire, questionnaire_for: questionable) }
      let!(:user) { create(:user, organization: questionable.organization) }
      let!(:questions) { create_list(:questionnaire_question, 3, questionnaire:) }
      let!(:answers) do
        questions.map do |question|
          create(:answer, questionnaire:, question:, user:)
        end
      end

      let!(:multichoice_question) { create(:questionnaire_question, questionnaire:, question_type: "multiple_option") }
      let!(:multichoice_answer_options) { create_list(:answer_option, 2, question: multichoice_question) }
      let!(:multichoice_answer) do
        create(:answer, questionnaire:, question: multichoice_question, user:, body: nil)
      end
      let!(:multichoice_answer_choices) do
        multichoice_answer_options.map do |answer_option|
          create(:answer_choice, answer: multichoice_answer, answer_option:, body: answer_option.body[I18n.locale.to_s])
        end
      end

      let!(:singlechoice_question) { create(:questionnaire_question, questionnaire:, question_type: "single_option") }
      let!(:singlechoice_answer_options) { create_list(:answer_option, 2, question: singlechoice_question) }
      let!(:singlechoice_answer) do
        create(:answer, questionnaire:, question: singlechoice_question, user:, body: nil)
      end
      let!(:singlechoice_answer_choice) do
        answer_option = singlechoice_answer_options.first
        create(:answer_choice, answer: singlechoice_answer, answer_option:, body: answer_option.body[I18n.locale.to_s], custom_body: "Free text")
      end

      let!(:matrixmultiple_question) { create(:questionnaire_question, questionnaire:, question_type: "matrix_multiple") }
      let!(:matrixmultiple_answer_options) { create_list(:answer_option, 3, question: matrixmultiple_question) }
      let!(:matrixmultiple_rows) { create_list(:question_matrix_row, 3, question: matrixmultiple_question) }
      let!(:matrixmultiple_answer) do
        create(:answer, questionnaire:, question: matrixmultiple_question, user:, body: nil)
      end
      let!(:matrixmultiple_answer_choices) do
        matrixmultiple_rows.map do |row|
          [
            create(:answer_choice, answer: matrixmultiple_answer, answer_option: matrixmultiple_answer_options.first, matrix_row: row, body: matrixmultiple_answer_options.first.body[I18n.locale.to_s]),
            create(:answer_choice, answer: matrixmultiple_answer, answer_option: matrixmultiple_answer_options.last, matrix_row: row, body: matrixmultiple_answer_options.last.body[I18n.locale.to_s])
          ]
        end.flatten
      end

      let!(:files_question) { create(:questionnaire_question, questionnaire:, question_type: "files") }
      let!(:files_answer) do
        create(:answer, :with_attachments, questionnaire:, question: files_question, user:, body: nil)
      end

      before do
        questions.each_with_index do |question, idx|
          question.update!(position: idx)
        end
      end

      describe "#serialize" do
        let(:serialized) { subject.serialize }

        it "includes the answer for each question" do
          questions.each_with_index do |question, idx|
            expect(serialized).to include(
              "#{question.position + 1}. #{translated(question.body, locale: I18n.locale)}" => answers[idx].body
            )
          end

          serialized_matrix_answer = matrixmultiple_rows.to_h do |row|
            key = translated(row.body, locale: I18n.locale)
            choices = matrixmultiple_answer_options.map do |option|
              matrixmultiple_answer_choices.find { |choice| choice.matrix_row == row && choice.answer_option == option }
            end

            [key, choices.map { |choice| choice&.body }]
          end

          serialized_files_blobs = files_answer.attachments.map(&:file).map(&:blob)

          expect(serialized).to include(
            "#{multichoice_question.position + 1}. #{translated(multichoice_question.body, locale: I18n.locale)}" => [multichoice_answer_choices.first.body, multichoice_answer_choices.last.body]
          )

          expect(serialized).to include(
            "#{singlechoice_question.position + 1}. #{translated(singlechoice_question.body, locale: I18n.locale)}" => ["#{translated(singlechoice_answer_choice.body)} (Free text)"]
          )

          expect(serialized).to include(
            "#{matrixmultiple_question.position + 1}. #{translated(matrixmultiple_question.body, locale: I18n.locale)}" => serialized_matrix_answer
          )

          expect(serialized["#{files_question.position + 1}. #{translated(files_question.body, locale: I18n.locale)}"]).to include_blob_urls(
            *serialized_files_blobs
          )
        end

        context "and includes the attributes" do
          let(:an_answer) { answers.first }

          it "the id of the answer" do
            key = I18n.t(:id, scope: "decidim.forms.user_answers_serializer")
            expect(serialized[key]).to eq an_answer.session_token
          end

          it "the creation of the answer" do
            key = I18n.t(:created_at, scope: "decidim.forms.user_answers_serializer")
            expect(serialized[key]).to eq an_answer.created_at.to_fs(:db)
          end

          it "the IP hash of the user" do
            key = I18n.t(:ip_hash, scope: "decidim.forms.user_answers_serializer")
            expect(serialized[key]).to eq an_answer.ip_hash
          end

          it "the user status" do
            key = I18n.t(:user_status, scope: "decidim.forms.user_answers_serializer")
            expect(serialized[key]).to eq "Registered"
          end

          it "includes email" do
            key = I18n.t(:email, scope: "decidim.forms.user_answers_serializer")
            expect(serialized[key]).to eq user.email
          end

          it "includes name" do
            key = I18n.t(:name, scope: "decidim.forms.user_answers_serializer")
            expect(serialized[key]).to eq user.name
          end

          context "when user is not registered" do
            before do
              questionnaire.answers.first.update!(decidim_user_id: nil)
            end

            it "the user status is unregistered" do
              key = I18n.t(:user_status, scope: "decidim.forms.user_answers_serializer")
              expect(serialized[key]).to eq "Unregistered"
            end

            it "does not include email" do
              key = I18n.t(:email, scope: "decidim.forms.user_answers_serializer")
              expect(serialized[key]).to eq ""
            end

            it "does not include name" do
              key = I18n.t(:name, scope: "decidim.forms.user_answers_serializer")
              expect(serialized[key]).to eq ""
            end
          end
        end

        context "when conditional question is not answered by user" do
          let!(:conditional_question) { create(:questionnaire_question, :conditioned, questionnaire:, position: 4) }

          it "includes conditional question as empty" do
            expect(serialized).to include("5. #{translated(conditional_question.body, locale: I18n.locale)}" => "")
          end
        end

        context "when the questionnaire body is very long" do
          let!(:questionnaire) { create(:questionnaire, questionnaire_for: questionable, description: questionnaire_description) }
          let(:questionnaire_description) do
            Decidim::Faker::Localized.wrapped("<p>", "</p>") do
              Decidim::Faker::Localized.localized { "a" * 1_000_000 }
            end
          end
          let!(:users) { create_list(:user, 100, organization: questionable.organization) }

          before do
            users.each do |user|
              questions.each do |question|
                create(:answer, questionnaire:, question:, user:)
              end
            end
          end

          it "does not load the questionnaire description to memory every time when iterating an answer" do
            # NOTE:
            # For this test it is important to fetch the single user "answer
            # sets" to an array and store them there because this is the same
            # way the answers are loaded e.g. in the survey component export
            # functionality. The export had previously a memory leak because the
            # questionnaire is fetched individually for each "answer set" and if
            # it has a very long description, it caused the description to be
            # stored multiple times within the array (for each "answer set"
            # separately) causing a out of memory errors when there is a large
            # amount of answers.
            all_answers = Decidim::Forms::QuestionnaireUserAnswers.for(questionnaire)

            initial_memory = memory_usage
            all_answers.each do |answer_set|
              described_class.new(answer_set).serialize
            end
            expect(memory_usage - initial_memory).to be < 10_000
          end

          def memory_usage
            `ps -o rss #{Process.pid}`.lines.last.to_i
          end
        end
      end

      describe "questions_hash" do
        it "generates a hash of questions ordered by position" do
          questions.shuffle!
          expect(subject.instance_eval { questions_hash }.keys.map { |key| key[0].to_i }.uniq).to eq(questions.sort_by(&:position).map { |question| question.position + 1 })
        end
      end
    end
  end
end
