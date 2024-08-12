# frozen_string_literal: true

module ProposalSerializerExtend
  def author_metadata
    author_metadata = {
      name: "",
      nickname: "",
      email: "",
      phone_number: ""
    }

    if proposal.creator.decidim_author_type == "Decidim::UserBaseEntity"
      begin
        user = Decidim::User.find(proposal.creator_author.id)
        author_metadata[:name] = user.try(:name).presence || ""
        author_metadata[:nickname] = user.try(:nickname).presence || ""
        author_metadata[:email] = user.try(:email).presence || ""
        author_metadata[:phone_number] = phone_number(user.id)
      rescue ActiveRecord::RecordNotFound => e
        Rails.logger.error "User not found: #{e.message}"
        author_metadata[:name] = ""
        author_metadata[:nickname] = ""
        author_metadata[:email] = ""
        author_metadata[:phone_number] = ""
      end
    end

    author_metadata
  end
end

Decidim::PhoneAuthorizationHandler::Extends::ProposalSerializerExtend.prepend(ProposalSerializerExtend)
