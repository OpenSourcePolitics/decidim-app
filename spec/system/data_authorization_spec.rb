# frozen_string_literal: true

require "spec_helper"

describe "Data authorization" do
  let(:organization) { create(:organization, available_authorizations: ["data_authorization_handler"]) }
  let(:user) { create(:user, :confirmed, organization:) }
  let(:firstname) { "John" }
  let(:lastname) { "Doe" }
  let(:phone) { "0605040302" }
  let(:postal_code) { "75001" }
  let(:city) { "Paris 1er Arrondissement" }
  let(:gdpr) { true }
  let(:minimum_age) { true }
  let(:response_body) do
    JSON.dump([{ "75001" => "Paris 1er Arrondissement" }])
  end
  let(:stubbed_request) do
    stub_request(:get, "/postal-code-autocomplete/75001").to_return(status: 200, body: response_body, headers: {})
    stub_request(:get, "https://apicarto.ign.fr/api/codes-postaux/communes/75001").to_return(status: 200, body: response_body, headers: {})
  end

  before do
    switch_to_host(organization.host)
    login_as user, scope: :user
    visit decidim_verifications.authorizations_path
    click_link_or_button("Data Sharing Process")
    stubbed_request
  end

  context "when the form is filled in correctly" do
    before do
      fill_in :authorization_handler_firstname, with: firstname
      fill_in :authorization_handler_lastname, with: lastname
      fill_in :authorization_handler_phone, with: phone
      fill_in :authorization_handler_postal_code, with: postal_code
      fill_in :authorization_handler_city, with: city
      check :authorization_handler_gdpr
      check :authorization_handler_minimum_age
      click_on "I continue"
    end

    shared_examples_for "is a valid firstname" do
      it "is valid" do
        expect(page).to have_content("successfully")
      end
    end

    context "when the firstname is valid" do
      let(:firstname) { "John" }

      it_behaves_like "is a valid firstname"
    end

    context "when the firstname contains ' or -" do
      let(:firstname) { "Jo-hn's" }

      it_behaves_like "is a valid firstname"
    end

    context "when the firstname contains a space" do
      let(:firstname) { "John Doe" }

      it_behaves_like "is a valid firstname"
    end

    context "when the firstname contains an accent" do
      let(:firstname) { "Jöhn Tâylot" }

      it_behaves_like "is a valid firstname"
    end

    shared_examples_for "is a valid lastname" do
      it "is valid" do
        expect(page).to have_content("successfully")
      end
    end

    context "when the lastname is valid" do
      let(:lastname) { "Doe" }

      it_behaves_like "is a valid lastname"
    end

    context "when the lastname contains ' or -" do
      let(:lastname) { "Do-e's" }

      it_behaves_like "is a valid lastname"
    end

    context "when the lastname contains a space" do
      let(:lastname) { "Doe John" }

      it_behaves_like "is a valid lastname"
    end

    context "when the lastname contains accents" do
      let(:lastname) { "Maël-Taylôr" }

      it_behaves_like "is a valid lastname"
    end

    it "authorizes the user" do
      expect(page).to have_content("successfully")
    end
  end

  context "when the form is filled in incorrectly" do
    before do
      fill_in :authorization_handler_firstname, with: firstname
      fill_in :authorization_handler_lastname, with: lastname
      fill_in :authorization_handler_phone, with: phone
      fill_in :authorization_handler_postal_code, with: postal_code
      fill_in :authorization_handler_city, with: city
      check :authorization_handler_gdpr
      check :authorization_handler_minimum_age
    end

    shared_examples_for "is an invalid firstname" do
      it "is invalid" do
        expect(page).to have_content("contains an error")
      end
    end

    context "when the firstname contains number" do
      let(:firstname) { "John1" }

      before do
        click_on "I continue"
      end

      it_behaves_like "is an invalid firstname"
    end

    context "when the firstname contains special characters" do
      let(:firstname) { "John@" }

      before do
        click_on "I continue"
      end

      it_behaves_like "is an invalid firstname"
    end

    shared_examples_for "is an invalid lastname" do
      it "is invalid" do
        expect(page).to have_content("contains an error")
      end
    end

    context "when the lastname contains number" do
      let(:lastname) { "Doe1" }

      before do
        click_on "I continue"
      end

      it_behaves_like "is an invalid lastname"
    end

    context "when the lastname contains special characters" do
      let(:lastname) { "Doe@" }

      before do
        click_on "I continue"
      end

      it_behaves_like "is an invalid lastname"
    end

    describe "when the name is empty" do
      let(:lastname) { "" }

      before do
        click_on "I continue"
      end

      it "does not authorize the user" do
        expect(page).to have_content("error")
      end
    end

    describe "when the firstname is empty" do
      let(:firstname) { "" }

      before do
        click_on "I continue"
      end

      it "does not authorize the user" do
        expect(page).to have_content("error")
      end
    end

    describe "when the phone number is empty" do
      let(:phone) { "" }

      before do
        click_on "I continue"
      end

      it "does not authorize the user" do
        expect(page).to have_content("error")
      end
    end

    describe "when no postal code is entered" do
      let(:postal_code) { "" }

      before do
        click_on "I continue"
      end

      it "does not authorize the user" do
        expect(page).to have_content("error")
      end
    end

    describe "when the postal_code is invalid" do
      let(:postal_code) { "1234" }

      before do
        click_on "I continue"
      end

      it "does not authorize the user" do
        expect(page).to have_content("error")
      end
    end

    describe "when the city is empty" do
      let(:city) { "" }

      before do
        click_on "I continue"
      end

      it "does not authorize the user" do
        expect(page).to have_content("error")
      end
    end

    describe "when gdpr is not checked" do
      before do
        uncheck :authorization_handler_gdpr
        click_on "I continue"
      end

      it "does not authorize the user" do
        expect(page).to have_content("must be accepted")
      end
    end

    describe "when minimum age is not checked" do
      before do
        uncheck :authorization_handler_minimum_age
        click_on "I continue"
      end

      it "does not authorize the user" do
        expect(page).to have_content("must be accepted")
      end
    end
  end
end
