# frozen_string_literal: true

require "spec_helper"

describe "rake decidim:repair:nickname", type: :task do
  let!(:organization) { create(:organization) }
  let(:task_cmd) { :"decidim:repair:nickname" }

  let!(:valid_user) { create(:user, nickname: "Azerty_Uiop123", organization: organization) }
  let(:invalid_user_1) { build(:user, nickname: "Foo bar", organization: organization) }
  let(:invalid_user_2) { build(:user, nickname: "Foo M. bar", organization: organization) }
  let(:invalid_user_3) { build(:user, nickname: "Foo-Bar_fooo$", organization: organization) }
  let(:invalid_user_4) { build(:user, nickname: "foo.bar.foo", organization: organization) }
  let(:invalid_user_5) { build(:user, nickname: ".foobar.foo_bar.", organization: organization) }
  let(:invalid_user_6) { build(:user, nickname: "Foo  bar", organization: organization) }
  let(:invalid_user_7) { build(:user, nickname: "Foo   bar", organization: organization) }

  context "when executing task" do
    before do
      invalid_user_1.save(validate: false)
      invalid_user_2.save(validate: false)
      invalid_user_3.save(validate: false)
      invalid_user_4.save(validate: false)
      invalid_user_5.save(validate: false)
      invalid_user_6.save(validate: false)
      invalid_user_7.save(validate: false)
    end

    after do
      ENV["REPARE_NICKNAME_FORCE"] = nil
    end

    context "when user accepts update" do
      before do
        ENV["REPARE_NICKNAME_FORCE"] = "1"
      end

      it "updates invalid nicknames" do
        Rake::Task[task_cmd].invoke

        expect(invalid_user_1.reload.nickname).to eq("foobar")
        expect(invalid_user_2.reload.nickname).to eq("foombar")
        expect(invalid_user_3.reload.nickname).to eq("foo-bar_fooo")
        expect(invalid_user_4.reload.nickname).to eq("foobarfoo")
        expect(invalid_user_5.reload.nickname).to eq("foobarfoo_bar")
        expect(invalid_user_6.reload.nickname).to eq("foobar#{invalid_user_6.id}")
        expect(invalid_user_7.reload.nickname).to eq("foobar#{invalid_user_7.id}")
        expect(valid_user.reload.nickname).to eq("Azerty_Uiop123")
      end
    end

    context "when user refuses update" do
      before do
        ENV["REPARE_NICKNAME_FORCE"] = nil
      end

      it "updates invalid nicknames" do
        Rake::Task[task_cmd].invoke

        expect(invalid_user_1.reload.nickname).to eq("Foo bar")
        expect(invalid_user_2.reload.nickname).to eq("Foo M. bar")
        expect(invalid_user_3.reload.nickname).to eq("Foo-Bar_fooo$")
        expect(invalid_user_4.reload.nickname).to eq("foo.bar.foo")
        expect(invalid_user_5.reload.nickname).to eq(".foobar.foo_bar.")
        expect(invalid_user_6.reload.nickname).to eq("Foo  bar")
        expect(invalid_user_7.reload.nickname).to eq("Foo   bar")
        expect(valid_user.reload.nickname).to eq("Azerty_Uiop123")
      end
    end
  end
end
