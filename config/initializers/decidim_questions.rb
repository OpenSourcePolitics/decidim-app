# frozen_string_literal: true

Decidim::QuestionCaptcha.configure do |config|
  # Type: Hash
  # List of localized questions
  config.questions = if Rails.env.test?
                       {
                         en: [
                           { "question" => "99+1", "answers" => "100" }
                         ],
                         fr: [
                           { "question" => "49+1", "answers" => "50" }
                         ]
                       }
                     else
                       {
                         en: [
                           { "question" => "1+1", "answers" => "2,two" },
                           { "question" => "The green hat is what color?", "answers" => "green" }
                         ],
                         fr: [
                           { "question" => "1+2", "answers" => "3,tres" },
                           { "question" => "El sombrero verde es de qué color?", "answers" => "verde" }
                         ]
                       }
                     end

  # Type: String
  # URL of a question API instance
  config.api_endpoint = nil

  # Type: Boolean
  # if the text captcha should be performed or not
  config.perform_textcaptcha = true

  # Type: Integer
  # Expiration of the captcha between form submission
  config.expiration_time = 10

  # Type: Boolean
  # Raise an error if something wrong happens (Wrong API response, timeout etc...)
  config.raise_error = false
end
