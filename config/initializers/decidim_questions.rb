# frozen_string_literal: true

Decidim::QuestionCaptcha.configure do |config|
  config.questions = {
    en: [
      { "question" => "1+5", "answers" => "6,six" },
      { "question" => "The blue hat is what color?", "answers" => "blue" },
      { "question" => "The green hat is what color?", "answers" => "green" },
      { "question" => "The yellow hat is what color?", "answers" => "yellow" },
      { "question" => "The red hat is what color?", "answers" => "red" }

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
end
