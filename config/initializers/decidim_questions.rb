# frozen_string_literal: true

Decidim::QuestionCaptcha.configure do |config|
  # Type: Hash
  # List of localized questions
  config.questions = {
    en: [
      { "question" => "1+1", "answers" => "2,two" },
      { "question" => "The green hat is what color?", "answers" => "green" }
    ],
    es: [
      { "question" => "1+2", "answers" => "3,tres" },
      { "question" => "El sombrero verde es de qué color?", "answers" => "verde" }
    ],
    ca: [
      { "question" => "2+2", "answers" => "4,quatre" },
      { "question" => "El barret verd és de quin color?", "answers" => "verd" }
    ]
  }

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
