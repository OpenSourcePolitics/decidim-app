# frozen_string_literal: true

require "spec_helper"

describe PrivateBodyDecryptJob, type: :job do
  let!(:extra_fields) { create(:awesome_proposal_extra_fields, proposal: create(:extended_proposal)) }

  before do
    extra_fields.private_body = { "en" => '<xml><dl><dt name="something">Something</dt></dl></xml>' }
    extra_fields.save!

    allow(Rails.logger).to receive(:info)
  end

  it "logs and updates the decrypted body if extra fields are present" do
    extra_fields.update_columns(decrypted_private_body: nil)
    expect(extra_fields.decrypted_private_body).to be_nil
    expect(Rails.logger).to receive(:info).with("Extra fields to update: 1")
    expect(Rails.logger).to receive(:info).with("Extra fields updated: 1")
    described_class.perform_now
    expect(extra_fields.reload.decrypted_private_body).to eq('{"en"=>"<xml><dl><dt name=\"something\">Something</dt></dl></xml>"}')
  end

  it "does not log or update if no extra fields are present" do
    extra_fields.update(decrypted_private_body: extra_fields.private_body.to_s)
    expect(extra_fields.reload.decrypted_private_body).not_to be_nil
    expect(Rails.logger).not_to receive(:info).with("Extra fields to update: 1")
    expect(Rails.logger).not_to receive(:info).with("Extra fields updated: 1")
    described_class.perform_now
  end
end
