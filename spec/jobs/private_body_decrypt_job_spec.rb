# frozen_string_literal: true

require "spec_helper"

describe PrivateBodyDecryptJob, type: :job do
  let!(:proposal_with_private_body) { create(:awesome_proposal_extra_fields, proposal: create(:extended_proposal), private_body: '<xml><dl><dt name="something">Something</dt></dl></xml>', decrypted_private_body: nil) }
  let!(:proposal_without_private_body) { create(:awesome_proposal_extra_fields, proposal: create(:extended_proposal), private_body: nil, decrypted_private_body: nil) }
  let!(:proposal_with_both_bodies_defined) { create(:awesome_proposal_extra_fields, proposal: create(:extended_proposal), private_body: '<xml><dl><dt name="something">Something</dt></dl></xml>', decrypted_private_body: '<xml><dl><dt name="something">Something</dt></dl></xml>') }
  let!(:proposal_without_extra_fields) { create(:awesome_proposal_extra_fields, proposal: create(:extended_proposal)) }

  before do
    allow(Rails.logger).to receive(:info)
  end

  context "when extra fields are present" do
    context "with private body defined and decrypted_private_body nil" do
      it "logs and updates the decrypted body" do
        # rubocop:disable Rails/SkipsModelValidations
        proposal_with_private_body.update_columns(decrypted_private_body: nil)
        # rubocop:enable Rails/SkipsModelValidations
        expect(proposal_with_private_body.decrypted_private_body).to be_nil
        described_class.perform_now
        expect(proposal_with_private_body.reload.decrypted_private_body).to eq('<xml><dl><dt name="something">Something</dt></dl></xml>')
      end
    end

    context "with private body nil, and decrypted_private_body nil" do
      it "does not log or update anything" do
        expect(proposal_without_private_body.decrypted_private_body).to be_nil
        expect(proposal_without_private_body.private_body).to be_nil
        expect(Rails.logger).not_to receive(:info).with("Extra fields to update: 1")
        expect(Rails.logger).not_to receive(:info).with("Extra fields updated: 1")
        described_class.perform_now
        expect(proposal_without_private_body.reload.decrypted_private_body).to be_nil
      end
    end

    context "with private body and decrypted_private_body defined" do
      it "does not log or update anything" do
        expect(proposal_with_both_bodies_defined.decrypted_private_body).not_to be_nil
        expect(proposal_with_both_bodies_defined.private_body).not_to be_nil
        expect(Rails.logger).not_to receive(:info).with("Extra fields to update: 1")
        expect(Rails.logger).not_to receive(:info).with("Extra fields updated: 1")
        described_class.perform_now
        expect(proposal_with_both_bodies_defined.reload.decrypted_private_body).to eq('<xml><dl><dt name="something">Something</dt></dl></xml>')
      end
    end

  end

  context "when extra fields are missing" do
    it "does not log or update" do
      expect(Rails.logger).not_to receive(:info).with("Extra fields to update: 1")
      expect(Rails.logger).not_to receive(:info).with("Extra fields updated: 1")
      described_class.perform_now
      expect(proposal_without_extra_fields.reload.decrypted_private_body).to eq(nil)
    end
  end
end
