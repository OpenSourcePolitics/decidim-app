# frozen_string_literal: true

require "spec_helper"

describe "rake decidim:repare:nickname", type: :task do
  let!(:organization) { create(:organization) }
  let(:task_cmd) { :"decidim:repare:nickname" }

  let!(:valid_user) { create(:user, nickname: "Azerty_Uiop123", organization: organization) }
  let(:invalid_user_1) { build(:user, nickname: "Foo bar", organization: organization) }
  let(:invalid_user_2) { build(:user, nickname: "Foo M. bar", organization: organization) }
  let(:invalid_user_3) { build(:user, nickname: "Foo-Bar_fooo$", organization: organization) }
  let(:invalid_user_4) { build(:user, nickname: "foo.bar.foo", organization: organization) }
  let(:invalid_user_5) { build(:user, nickname: ".foobar.foo_bar.", organization: organization) }
  let(:invalid_user_6) { build(:user, nickname: "Foo  bar", organization: organization) }

  context "when executing task" do
    before do
      invalid_user_1.save(validate: false)
      invalid_user_2.save(validate: false)
      invalid_user_3.save(validate: false)
      invalid_user_4.save(validate: false)
      invalid_user_5.save(validate: false)
      invalid_user_6.save(validate: false)
    end

    after do
      ENV["REPARE_NICKNAME_FORCE"] = nil
    end

    context "when user accepts update" do
      before do
        ENV["REPARE_NICKNAME_FORCE"] = "1"
      end

      it "updates invalid nicknames" do
        expect { Rake::Task[task_cmd].invoke }.to change(invalid_user_1, :nickname).from("Foo bar").to("foobar")

        invalid_user_1.reload
        expect(invalid_user_1.nickname).to eq("foobar")
        invalid_user_2.reload
        expect(invalid_user_2.nickname).to eq("foombar")
        invalid_user_3.reload
        expect(invalid_user_3.nickname).to eq("foobarfooo")
        invalid_user_4.reload
        expect(invalid_user_4.nickname).to eq("foobarfoo")
        invalid_user_5.reload
        expect(invalid_user_5.nickname).to eq("foobarfoobar")
        invalid_user_6.reload
        expect(invalid_user_6.nickname).to eq("foobar1")

        valid_user.reload
        expect(valid_user.nickname).to eq("Azerty_Uiop123")
      end
    end

    context "when user refuses update" do
      before do
        ENV["REPARE_NICKNAME_FORCE"] = nil
      end

      it "updates invalid nicknames" do
        allow($stdin).to receive(:gets).and_return("n")

        expect { Rake::Task[task_cmd].invoke }.not_to change(invalid_user_1, :nickname)

        invalid_user_1.reload
        expect(invalid_user_1.nickname).to eq("Foo bar")
        invalid_user_2.reload
        expect(invalid_user_2.nickname).to eq("Foo M. bar")
        invalid_user_3.reload
        expect(invalid_user_3.nickname).to eq("Foo-Bar_fooo$")
        invalid_user_4.reload
        expect(invalid_user_4.nickname).to eq("foo.bar.foo")
        invalid_user_5.reload
        expect(invalid_user_5.nickname).to eq(".foobar.foo_bar.")
        invalid_user_6.reload
        expect(invalid_user_6.nickname).to eq("Foo  bar")

        valid_user.reload
        expect(valid_user.nickname).to eq("Azerty_Uiop123")
      end
    end
  end
end
