# frozen_string_literal: true

module ProposalAnswerCreatorExtends
  def notify
    # If the initial state is set to nil, then it will be set to "" as it is a non-answered proposal.
    # We still want to use further in the process and cannot read nil values.
    state = initial_state || ""
    ::Decidim::Proposals::Admin::NotifyProposalAnswer.call(resource, state)
  end
end

Decidim::Proposals::Import::ProposalAnswerCreator.class_eval do
  prepend(ProposalAnswerCreatorExtends)
end
