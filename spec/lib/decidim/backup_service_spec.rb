# frozen_string_literal: true

require "spec_helper"

describe Decidim::BackupService do
  subject { described_class.new(options) }

  let(:options) do
    {
      scope: scope,
      timestamp_in_filename: timestamp_in_filename,
      backup_dir: backup_dir,
      disk_space_limit: disk_space_limit,
      s3sync: s3sync,
      s3retention: s3retention,
      keep_local_files: keep_local_files,
      db_conf: db_conf
    }
  end
  let(:keep_local_files) { true }
  let(:s3sync) { false }
  let(:s3retention) { false }
  let(:scope) { :git }
  let(:timestamp_in_filename) { true }
  let(:backup_dir) { "tmp/test/backup" }
  let(:disk_space_limit) { 256 }
  let(:db_conf) do
    {
      host: "123.domain.org",
      username: "postgres",
      password: "mysecretpassword",
      database: "decidim_test"
    }
  end

  describe "#check_scope?" do
    context "with valid scope" do
      it "returns true" do
        expect(subject.send(:check_scope?, scope)).to be true
      end
    end

    context "with invalid scope" do
      it "returns false" do
        expect(subject.send(:check_scope?, :invalid)).to be false
      end
    end
  end

  describe "#timestamp" do
    it "returns a timestamp" do
      expect(subject.send(:timestamp)).to be_a(String)
    end
  end

  describe "#need_timestamp?" do
    it "is truthy" do
      expect(subject.send(:need_timestamp?)).to be_truthy
    end

    context "when options is provided" do
      let(:timestamp_in_filename) { false }

      it "is falsey" do
        expect(subject.send(:need_timestamp?)).to be_falsey
      end
    end

    describe "#has_backup_directory?" do
      before do
        FileUtils.remove_dir(backup_dir) if File.directory?(backup_dir)
      end

      after do
        FileUtils.remove_dir(backup_dir) if File.directory?(backup_dir)
      end

      it "returns true" do
        expect(subject.send(:has_backup_directory?)).to be_truthy
      end

      context "when directory already exists" do
        before do
          FileUtils.mkdir_p(backup_dir)
        end

        it "returns true" do
          expect(subject.send(:has_backup_directory?)).to be_truthy
        end

        context "and is not writable" do
          before do
            FileUtils.chmod(0o000, backup_dir)
          end

          after do
            FileUtils.chmod(0o755, backup_dir)
          end

          it "returns false" do
            expect(subject.send(:has_backup_directory?)).to be_falsey
          end
        end
      end
    end
  end

  describe "#generate_backup_file_path" do
    let(:name) { "dummy" }
    let(:ext) { "extension" }

    it "returns path" do
      expect(subject.send(:generate_backup_file_path, name, ext)).to match(%r{tmp/test/backup/decidim-backup-dummy-\d{4}-\d{2}-\d{2}-\d{6}.extension})
    end

    context "when time stamp is not needed" do
      let(:timestamp_in_filename) { false }

      it "returns path" do
        expect(subject.send(:generate_backup_file_path, name, ext)).to eq("tmp/test/backup/decidim-backup-dummy.extension")
      end
    end
  end

  describe "#execute_backup_command" do
    let(:file_path) { "tmp/backup/dummy.ext" }
    let(:cmd) { "exit 0" }

    it "stores the file path" do
      s = subject
      expect(subject.send(:execute_backup_command, file_path, cmd)).to eq(true)
      expect(s.instance_variable_get(:@local_files)).to eq([file_path])
    end

    context "when command failed" do
      let(:cmd) { "exit 1" }

      it "doesn't stores the file path" do
        s = subject
        expect(subject.send(:execute_backup_command, file_path, cmd)).to eq(false)
        expect(s.instance_variable_get(:@local_files)).to eq([])
      end
    end
  end

  describe "clean_local_files" do
    let(:file_path) { "#{backup_dir}/test_file.txt" }

    before do
      FileUtils.mkdir_p(backup_dir)
      File.write(file_path, "")
    end

    after do
      FileUtils.remove_dir(backup_dir) if File.directory?(backup_dir)
    end

    it "cleans local files" do
      s = subject
      s.instance_variable_set(:@local_files, [file_path])

      subject.send(:clean_local_files)
      expect(File).not_to exist(file_path)
    end
  end

  describe "#available_space" do
    before do
      allow(Sys::Filesystem).to receive(:stat).and_return(Struct.new(:block_size, :blocks_available).new(4096, 256_000_000))
    end

    it "returns available space" do
      expect(subject.send(:available_space)).to eq(976)
    end
  end

  describe "#has_enough_disk_space?" do
    before do
      allow(Sys::Filesystem).to receive(:stat).and_return(Struct.new(:block_size, :blocks_available).new(4096, 256_000_000))
    end

    it "returns true" do
      expect(subject.send(:has_enough_disk_space?)).to be_truthy
    end
  end

  describe "#generate_timestamp_file" do
    before do
      FileUtils.mkdir_p(backup_dir)
    end

    after do
      FileUtils.remove_dir(backup_dir) if File.directory?(backup_dir)
    end

    it "adds the file to local_files" do
      s = subject
      s.send(:generate_timestamp_file)
      generated_file = s.instance_variable_get(:@local_files).first
      expect(generated_file).to eq("tmp/test/backup/timestamp-backup.log")
      expect(File.read(generated_file)).to match(/\d{4}-\d{2}-\d{2}-\d{6}/)
    end
  end

  describe "#can_connect_to_db?" do
    it "returns true" do
      expect(subject.send(:can_connect_to_db?)).to be_truthy
    end
  end

  describe "#create_backup_dir" do
    before do
      FileUtils.remove_dir(backup_dir) if File.directory?(backup_dir)
    end

    after do
      FileUtils.remove_dir(backup_dir) if File.directory?(backup_dir)
    end

    it "returns backup_dir" do
      expect(subject.create_backup_dir).to eq([Rails.root.join(backup_dir).to_s])
    end

    context "when file already exists" do
      before do
        FileUtils.mkdir_p(backup_dir)
      end

      it "returns backup_dir" do
        expect(subject.create_backup_dir).to eq([Rails.root.join(backup_dir).to_s])
      end
    end
  end

  describe "#backup_database" do
    let(:expected_file_path) { "tmp/test/backup/decidim-backup-db-2023-06-15-114630.dump" }

    before do
      # rubocop:disable RSpec/SubjectStub
      allow(subject).to receive(:generate_backup_file_path).with("db", "dump").and_return(expected_file_path)
      allow(subject).to receive(:execute_backup_command).with(expected_file_path, "PGPASSWORD=#{db_conf[:password]} pg_dump -Fc -h '#{db_conf[:host]}' -U '#{db_conf[:username]}' -d '#{db_conf[:database]}' -f '#{expected_file_path}'").and_return(true)
      # rubocop:enable RSpec/SubjectStub
    end

    it "returns true" do
      expect(subject.backup_database).to be_truthy
    end

    context "when database is not connected" do
      before do
        # rubocop:disable RSpec/SubjectStub
        allow(subject).to receive(:can_connect_to_db?).and_return(false)
        # rubocop:enable RSpec/SubjectStub
      end

      it "returns false" do
        expect(subject.backup_database).to be_falsey
      end
    end
  end

  describe "#backup_uploads" do
    let(:expected_file_path) { "tmp/test/backup/decidim-backup-storage-2023-06-15-140432.tar.bz2" }

    before do
      # rubocop:disable RSpec/SubjectStub
      allow(subject).to receive(:file_exists?).with("storage").and_return(true)
      allow(subject).to receive(:generate_backup_file_path).with("storage", "tar.bz2").and_return(expected_file_path)
      allow(subject).to receive(:execute_backup_command).with(expected_file_path, "tar -jcf #{expected_file_path} storage").and_return(true)
      # rubocop:enable RSpec/SubjectStub
    end

    it "returns true" do
      expect(subject.backup_uploads).to be_truthy
    end

    context "when file doesn't exist" do
      before do
        # rubocop:disable RSpec/SubjectStub
        allow(subject).to receive(:file_exists?).with("storage").and_return(false)
        # rubocop:enable RSpec/SubjectStub
      end

      it "returns false" do
        expect(subject.backup_uploads).to be_falsey
      end
    end
  end

  describe "#backup_git" do
    let(:expected_file_path) { "tmp/test/backup/decidim-backup-git-2023-06-15-142721.tar.bz2" }
    let(:expected_git_file_list) { %w(.git/HEAD .git/ORIG_HEAD dummy.rb dummy2.rb) }

    before do
      # rubocop:disable RSpec/SubjectStub
      allow(subject).to receive(:file_exists?).with(".git").and_return(true)
      allow(subject).to receive(:git_file_list).and_return(expected_git_file_list)
      allow(subject).to receive(:generate_backup_file_path).with("git", "tar.bz2").and_return(expected_file_path)
      allow(subject).to receive(:execute_backup_command).with(expected_file_path, "tar -jcf #{expected_file_path} #{expected_git_file_list.join(" ")}").and_return(true)
      # rubocop:enable RSpec/SubjectStub
    end

    it "returns true" do
      expect(subject.backup_git).to be_truthy
    end

    context "when file doesn't exist" do
      before do
        # rubocop:disable RSpec/SubjectStub
        allow(subject).to receive(:file_exists?).with(".git").and_return(false)
        # rubocop:enable RSpec/SubjectStub
      end

      it "returns false" do
        expect(subject.backup_git).to be_falsey
      end
    end
  end

  describe "#backup_env" do
    let(:expected_file_path) { "tmp/test/backup/decidim-backup-env-2023-06-15-143803.tar.bz2" }

    before do
      # rubocop:disable RSpec/SubjectStub
      allow(subject).to receive(:file_exists?).with(".env").and_return(true)
      allow(subject).to receive(:generate_backup_file_path).with("env", "tar.bz2").and_return(expected_file_path)
      allow(subject).to receive(:execute_backup_command).with(expected_file_path, "tar -jcf #{expected_file_path} .env").and_return(true)
      # rubocop:enable RSpec/SubjectStub
    end

    it "returns true" do
      expect(subject.backup_env).to be_truthy
    end

    context "when file doesn't exist" do
      before do
        # rubocop:disable RSpec/SubjectStub
        allow(subject).to receive(:file_exists?).with(".env").and_return(false)
        # rubocop:enable RSpec/SubjectStub
      end

      it "returns false" do
        expect(subject.backup_env).to be_falsey
      end
    end
  end

  describe "#create_backup_export" do
    context "when scope is all" do
      let(:scope) { :all }

      it "calls all backup methods" do
        # rubocop:disable RSpec/SubjectStub
        expect(subject).to receive(:backup_database).and_return(true)
        expect(subject).to receive(:backup_uploads).and_return(true)
        expect(subject).to receive(:backup_git).and_return(true)
        expect(subject).to receive(:backup_env).and_return(true)
        # rubocop:enable RSpec/SubjectStub
        subject.create_backup_export
      end
    end

    context "when scope is db" do
      let(:scope) { :db }

      it "calls backup_database method" do
        # rubocop:disable RSpec/SubjectStub
        expect(subject).to receive(:backup_database).and_return(true)
        expect(subject).not_to receive(:backup_uploads)
        expect(subject).not_to receive(:backup_git)
        expect(subject).not_to receive(:backup_env)
        # rubocop:enable RSpec/SubjectStub
        subject.create_backup_export
      end
    end

    context "when scope is uploads" do
      let(:scope) { :uploads }

      it "calls backup_uploads method" do
        # rubocop:disable RSpec/SubjectStub
        expect(subject).not_to receive(:backup_database)
        expect(subject).to receive(:backup_uploads).and_return(true)
        expect(subject).not_to receive(:backup_git)
        expect(subject).not_to receive(:backup_env)
        # rubocop:enable RSpec/SubjectStub
        subject.create_backup_export
      end
    end

    context "when scope is git" do
      let(:scope) { :git }

      it "calls backup_git method" do
        # rubocop:disable RSpec/SubjectStub
        expect(subject).not_to receive(:backup_database)
        expect(subject).not_to receive(:backup_uploads)
        expect(subject).to receive(:backup_git).and_return(true)
        expect(subject).not_to receive(:backup_env)
        # rubocop:enable RSpec/SubjectStub
        subject.create_backup_export
      end

      context "when scope is env" do
        let(:scope) { :env }

        it "calls backup_env method" do
          # rubocop:disable RSpec/SubjectStub
          expect(subject).not_to receive(:backup_database)
          expect(subject).not_to receive(:backup_uploads)
          expect(subject).not_to receive(:backup_git)
          expect(subject).to receive(:backup_env).and_return(true)
          # rubocop:enable RSpec/SubjectStub
          subject.create_backup_export
        end
      end
    end
  end

  describe "#execute" do
    before do
      # rubocop:disable RSpec/SubjectStub
      allow(subject).to receive(:create_backup_dir).and_return([Rails.root.join(backup_dir).to_s])
      # rubocop:enable RSpec/SubjectStub
    end

    context "when has_enough_disk_space? returns true" do
      before do
        # rubocop:disable RSpec/SubjectStub
        allow(subject).to receive(:has_enough_disk_space?).and_return(true)
        allow(subject).to receive(:create_backup_export).and_return(true)
        # rubocop:enable RSpec/SubjectStub
      end

      context "when s3sync is true" do
        let(:s3sync) { true }

        it "returns true" do
          expect(Decidim::S3SyncService).to receive(:run).and_return(true)
          # rubocop:disable RSpec/SubjectStub
          expect(subject).not_to receive(:clean_local_files)
          # rubocop:enable RSpec/SubjectStub
          expect(subject.execute).to be_truthy
        end
      end

      context "when s3retention is true" do
        let(:s3retention) { true }

        it "returns true" do
          expect(Decidim::S3RetentionService).to receive(:run).and_return(true)
          # rubocop:disable RSpec/SubjectStub
          expect(subject).not_to receive(:clean_local_files)
          # rubocop:enable RSpec/SubjectStub
          expect(subject.execute).to be_truthy
        end
      end

      context "when keep_local_files is true" do
        let(:keep_local_files) { false }

        it "returns true" do
          # rubocop:disable RSpec/SubjectStub
          expect(subject).to receive(:clean_local_files).and_return(true)
          # rubocop:enable RSpec/SubjectStub
          expect(subject.execute).to be_truthy
        end
      end
    end

    context "when has_enough_disk_space? returns false" do
      before do
        # rubocop:disable RSpec/SubjectStub
        allow(subject).to receive(:has_enough_disk_space?).and_return(false)
        # rubocop:enable RSpec/SubjectStub
      end

      it "returns false" do
        expect(subject.execute).to be_falsey
      end
    end
  end
end
