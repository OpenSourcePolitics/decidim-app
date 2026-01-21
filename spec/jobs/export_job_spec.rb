# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Admin
    describe ExportJob do
      let!(:component) { create(:component, manifest_name: "dummy") }
      let(:organization) { component.organization }
      let!(:user) { create(:user, organization:) }
      let!(:admin) { create(:user, :admin, organization:) }
      let(:serializer) { Decidim::Proposals::ProposalSerializer }
      let(:proposal) { create(:proposal) }
      let(:collection) { [proposal] }
      let(:export_manifest) do
        instance_double(
          "Decidim::ComponentExportManifest",
          name: :proposals,
          collection: ->(_component, _user, _resource_id) { collection },
          serializer: Decidim::Proposals::ProposalSerializer
        )
      end

      it "sends an email with the result of the export" do
        perform_enqueued_jobs { ExportJob.perform_now(user, component, "dummies", "CSV") }

        email = last_email
        expect(email.subject).to include("dummies")
        expect(last_email_body).to include("Your download is ready.")
      end

      describe "CSV" do
        it "uses the CSV exporter" do
          export_data = double(read: "", filename: "dummies")

          expect(Decidim::Exporters::CSV)
            .to(receive(:new).with(anything, Decidim::Dev::DummySerializer))
            .and_return(double(export: export_data))

          expect(ExportMailer)
            .to(receive(:export).with(user, kind_of(Decidim::PrivateExport)))
            .and_return(double(deliver_later: true))

          ExportJob.perform_now(user, component, "dummies", "CSV")
        end
      end

      describe "JSON" do
        it "uses the JSON exporter" do
          export_data = double(read: "", filename: "dummies")

          expect(Decidim::Exporters::JSON)
            .to(receive(:new).with(anything, Decidim::Dev::DummySerializer))
            .and_return(double(export: export_data))

          expect(ExportMailer)
            .to(receive(:export).with(user, kind_of(Decidim::PrivateExport)))
            .and_return(double(deliver_later: true))

          ExportJob.perform_now(user, component, "dummies", "JSON")
        end
      end

      describe "Admin export for processes" do
        let!(:admin_of_the_process) { create(:user, organization:) }
        let!(:participatory_process) { create(:participatory_process, organization:) }

        before do
          component.update!(participatory_space: participatory_process)
          create(:participatory_process_user_role, user: admin_of_the_process, participatory_process:, role: "admin")

          allow(component.manifest).to receive(:export_manifests).and_return([export_manifest])
        end

        it "allows admin to access admin_export" do
          export_data = double(read: "", filename: "proposals")

          expect(Decidim::Exporters::CSV)
            .to(receive(:new).with(anything, serializer))
            .and_return(double(admin_export: export_data))

          expect(ExportMailer)
            .to(receive(:export).with(admin, kind_of(Decidim::PrivateExport)))
            .and_return(double(deliver_later: true))

          ExportJob.perform_now(admin, component, "proposals", "CSV")
        end

        it "allows admin of the process to access admin_export" do
          export_data = double(read: "", filename: "proposals")

          expect(Decidim::Exporters::CSV)
            .to(receive(:new).with(anything, serializer))
            .and_return(double(admin_export: export_data))

          expect(ExportMailer)
            .to(receive(:export).with(admin_of_the_process, kind_of(Decidim::PrivateExport)))
            .and_return(double(deliver_later: true))

          ExportJob.perform_now(admin_of_the_process, component, "proposals", "CSV")
        end

        it "does not allow normal user to access admin_export" do
          export_data = double(read: "", filename: "proposals")

          expect(Decidim::Exporters::CSV)
            .to(receive(:new).with(anything, serializer))
            .and_return(double(export: export_data))

          expect(ExportMailer)
            .to(receive(:export).with(user, kind_of(Decidim::PrivateExport)))
            .and_return(double(deliver_later: true))

          ExportJob.perform_now(user, component, "proposals", "CSV")
        end
      end

      describe "export for assemblies" do
        let!(:assembly) { create(:assembly, organization:) }
        let!(:admin_of_the_assembly) { create(:user, organization:) }

        before do
          component.update!(participatory_space: assembly)
          create(:assembly_user_role, user: admin_of_the_assembly, assembly:, role: "admin")

          allow(component.manifest).to receive(:export_manifests).and_return([export_manifest])
        end

        it "sends an email with the result of the export" do
          export_data = double(read: "export content", filename: "proposals")

          allow(Decidim::Exporters::CSV)
            .to(receive(:new).with(anything, serializer))
            .and_return(double(export: export_data))

          perform_enqueued_jobs { ExportJob.perform_now(user, component, "proposals", "CSV") }

          email = last_email
          expect(email.subject).to include("proposals")
          expect(last_email_body).to include("Your download is ready.")
        end

        describe "admin export for assemblies" do
          it "allows admin to access admin_export" do
            export_data = double(read: "", filename: "proposals")

            expect(Decidim::Exporters::CSV)
              .to(receive(:new).with(anything, serializer))
              .and_return(double(admin_export: export_data))

            expect(ExportMailer)
              .to(receive(:export).with(admin, kind_of(Decidim::PrivateExport)))
              .and_return(double(deliver_later: true))

            ExportJob.perform_now(admin, component, "proposals", "CSV")
          end

          it "allows admin of the assembly to access admin_export" do
            export_data = double(read: "", filename: "proposals")

            expect(Decidim::Exporters::CSV)
              .to(receive(:new).with(anything, serializer))
              .and_return(double(admin_export: export_data))

            expect(ExportMailer)
              .to(receive(:export).with(admin_of_the_assembly, kind_of(Decidim::PrivateExport)))
              .and_return(double(deliver_later: true))

            ExportJob.perform_now(admin_of_the_assembly, component, "proposals", "CSV")
          end
        end
      end
    end
  end
end
