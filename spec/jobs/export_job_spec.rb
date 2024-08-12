# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Admin
    describe ExportJob do
      let!(:component) { create(:component, manifest_name: "dummy") }
      let(:organization) { component.organization }
      let!(:user) { create(:user, organization: organization) }
      let!(:admin) { create(:user, :admin, organization: organization) }
      let!(:admin_of_the_process) { create(:user, organization: organization) }
      let!(:participatory_process) { create(:participatory_process, organization: organization) }
      let(:proposal) { create(:proposal) }
      let(:collection) { [proposal] } # Use an array with the instance_double
      let(:export_manifest) do
        instance_double(
          # rubocop:disable RSpec/VerifiedDoubleReference
          "Decidim::ComponentExportManifest",
          # rubocop:enable RSpec/VerifiedDoubleReference
          name: :proposals,
          collection: ->(_component, _user, _resource_id) { collection },
          serializer: Decidim::Proposals::ProposalSerializer
        )
      end

      before do
        component.update!(participatory_space: participatory_process)
        create(:participatory_process_user_role, user: admin_of_the_process, participatory_process: participatory_process, role: "admin")

        allow(component.manifest).to receive(:export_manifests).and_return([export_manifest])
      end

      it "sends an email with the result of the export" do
        ExportJob.perform_now(user, component, "proposals", "CSV")

        email = last_email
        expect(email.subject).to include("proposals")
        attachment = email.attachments.first

        expect(attachment.read.length).to be_positive
        expect(attachment.mime_type).to eq("application/zip")
        expect(attachment.filename).to match(/^proposals-[0-9]+-[0-9]+-[0-9]+-[0-9]+\.zip$/)
      end

      describe "CSV" do
        it "uses the CSV exporter" do
          export_data = double

          expect(Decidim::Exporters::CSV)
            .to(receive(:new).with(anything, Decidim::Proposals::ProposalSerializer))
            .and_return(double(export: export_data))

          expect(ExportMailer)
            .to(receive(:export).with(user, anything, export_data))
            .and_return(double(deliver_now: true))

          ExportJob.perform_now(user, component, "proposals", "CSV")
        end
      end

      describe "JSON" do
        it "uses the JSON exporter" do
          export_data = double

          expect(Decidim::Exporters::JSON)
            .to(receive(:new).with(anything, Decidim::Proposals::ProposalSerializer))
            .and_return(double(export: export_data))

          expect(ExportMailer)
            .to(receive(:export).with(user, anything, export_data))
            .and_return(double(deliver_now: true))

          ExportJob.perform_now(user, component, "proposals", "JSON")
        end
      end

      describe "Admin export" do
        let(:serializer) { Decidim::Proposals::ProposalSerializer }

        before do
          allow(Decidim::Exporters::CSV)
            .to(receive(:new).with(anything, serializer))
            .and_return(double(export: "normal export data"))
        end

        it "allows admin to access admin_export" do
          expect(Decidim::Exporters::CSV)
            .to(receive(:new).with(anything, serializer))
            .and_return(double(admin_export: "admin export data"))

          expect(ExportMailer)
            .to(receive(:export).with(admin, anything, "admin export data"))
            .and_return(double(deliver_now: true))

          ExportJob.perform_now(admin, component, "proposals", "CSV")
        end

        it "allows admin of the process to access admin_export" do
          expect(Decidim::Exporters::CSV)
            .to(receive(:new).with(anything, serializer))
            .and_return(double(admin_export: "admin export data"))

          expect(ExportMailer)
            .to(receive(:export).with(admin_of_the_process, anything, "admin export data"))
            .and_return(double(deliver_now: true))

          ExportJob.perform_now(admin_of_the_process, component, "proposals", "CSV")
        end

        it "does not allow normal user to access admin_export" do
          expect(Decidim::Exporters::CSV)
            .to(receive(:new).with(anything, serializer))
            .and_return(double(export: "normal export data"))

          expect(ExportMailer)
            .to(receive(:export).with(user, anything, "normal export data"))
            .and_return(double(deliver_now: true))

          ExportJob.perform_now(user, component, "proposals", "CSV")
        end
      end
    end
  end
end
