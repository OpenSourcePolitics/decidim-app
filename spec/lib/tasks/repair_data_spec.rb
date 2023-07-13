# frozen_string_literal: true

require "spec_helper"

describe "rake decidim:repair:nickname", type: :task do
  let!(:organization) { create(:organization) }
  let(:task_cmd) { :"decidim:repair:nickname" }

  let!(:valid_user) { create(:user, nickname: "Azerty_Uiop123", organization: organization) }
  let(:invalid_user1) { build(:user, nickname: "Foo bar", organization: organization) }
  let(:invalid_user2) { build(:user, nickname: "Foo M. bar", organization: organization) }
  let(:invalid_user3) { build(:user, nickname: "Foo-Bar_fooo$", organization: organization) }
  let(:invalid_user4) { build(:user, nickname: "foo.bar.foo", organization: organization) }
  let(:invalid_user5) { build(:user, nickname: ".foobar.foo_bar.", organization: organization) }
  let(:invalid_user6) { build(:user, nickname: "Foo  bar", organization: organization) }
  let(:invalid_user7) { build(:user, nickname: "Foo   bar", organization: organization) }

  let(:repair_nick_name_force) { "1" }

  let(:environment) do
    {
      "REPAIR_NICKNAME_FORCE" => repair_nick_name_force
    }
  end

  before do
    invalid_user1.save(validate: false)
    invalid_user2.save(validate: false)
    invalid_user3.save(validate: false)
    invalid_user4.save(validate: false)
    invalid_user5.save(validate: false)
    invalid_user6.save(validate: false)
    invalid_user7.save(validate: false)

    Rake::Task[task_cmd].reenable
  end

  it "updates invalid nicknames" do
    with_modified_env(environment) do
      Rake::Task[task_cmd].invoke

      expect(invalid_user1.reload.nickname).to eq("foobar")
      expect(invalid_user2.reload.nickname).to eq("foombar")
      expect(invalid_user3.reload.nickname).to eq("foo-bar_fooo")
      expect(invalid_user4.reload.nickname).to eq("foobarfoo")
      expect(invalid_user5.reload.nickname).to eq("foobarfoo_bar")
      expect(invalid_user6.reload.nickname).to eq("foobar#{invalid_user6.id}")
      expect(invalid_user7.reload.nickname).to eq("foobar#{invalid_user7.id}")
      expect(valid_user.reload.nickname).to eq("Azerty_Uiop123")
    end
  end

  context "when user refuses update" do
    let(:repair_nick_name_force) { "0" }

    it "updates invalid nicknames" do
      with_modified_env(environment) do
        Rake::Task[task_cmd].invoke

        expect(invalid_user1.reload.nickname).to eq("Foo bar")
        expect(invalid_user2.reload.nickname).to eq("Foo M. bar")
        expect(invalid_user3.reload.nickname).to eq("Foo-Bar_fooo$")
        expect(invalid_user4.reload.nickname).to eq("foo.bar.foo")
        expect(invalid_user5.reload.nickname).to eq(".foobar.foo_bar.")
        expect(invalid_user6.reload.nickname).to eq("Foo  bar")
        expect(invalid_user7.reload.nickname).to eq("Foo   bar")
        expect(valid_user.reload.nickname).to eq("Azerty_Uiop123")
      end
    end
  end
end
