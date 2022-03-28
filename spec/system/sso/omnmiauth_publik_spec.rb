# frozen_string_literal: true

require "spec_helper"

describe "Omniauth Publik", type: :system do
  let(:organization) { create(:organization) }
  let(:questions) do
    {
      en: [{ "question" => "1+1", "answers" => "2" }]
    }
  end


  before do
    switch_to_host(organization.host)
    allow(Decidim::QuestionCaptcha).to receive(:config).and_return({ questions: questions,
                                                                     perform_textcaptcha: true,
                                                                     expiration_time: 20,
                                                                     raise_error: false,
                                                                     api_endpoint: false })
    allow(Decidim::QuestionCaptcha.config).to receive(:questions).and_return(questions)
    allow(Decidim::QuestionCaptcha.config).to receive(:api_endpoint).and_return(false)
    allow(Decidim::QuestionCaptcha.config).to receive(:perform_textcaptcha).and_return(true)
    allow(Decidim::QuestionCaptcha.config).to receive(:expiration_time).and_return(20)
    allow(Decidim::QuestionCaptcha.config).to receive(:raise_error).and_return(false)
    visit decidim.root_path
  end

  context "when using Publik" do
    let(:omniauth_hash) do
      OmniAuth::AuthHash.new(
        provider: "publik",
        uid: "123545",
        info: {
          nickname: "foobar",
          name: "Foo Bar",
          email: "foo@bar.com"
        }
      )
    end

    before do
      OmniAuth.config.test_mode = true
      OmniAuth.config.mock_auth[:publik] = omniauth_hash
      OmniAuth.config.add_camelization "publik", "Publik"
      OmniAuth.config.request_validation_phase = ->(env) {} if OmniAuth.config.respond_to?(:request_validation_phase)
    end

    after do
      OmniAuth.config.test_mode = false
      OmniAuth.config.mock_auth[:publik] = nil
      OmniAuth.config.camelizations.delete("publik")
    end

    context "when the user has confirmed the email in publik" do
      it "creates a new User without sending confirmation instructions" do
        find(".sign-up-link").click

        click_link "Sign in with Publik"

        expect(page).to have_content("Successfully")
        expect_user_logged
      end
    end
  end
end
