# frozen_string_literal: true

module UpdateInitiativeAnswerExtends
  def call
    return broadcast(:invalid) if form.invalid?

    @initiative = Decidim.traceability.update!(
      initiative,
      current_user,
      attributes
    )
    notify_initiative_is_extended if @notify_extended
    notify_initiative_is_answered if @notify_answered
    broadcast(:ok, initiative)
  rescue ActiveRecord::RecordInvalid
    broadcast(:invalid, initiative)
  end

  private

  def attributes
    attrs = {
      answer: form.answer,
      answer_url: form.answer_url
    }

    attrs[:answered_at] = Time.current if form.answer.present?

    if form.signature_dates_required?
      attrs[:signature_start_date] = form.signature_start_date
      attrs[:signature_end_date] = form.signature_end_date

      if initiative.published? && form.signature_end_date != initiative.signature_end_date &&
         form.signature_end_date > initiative.signature_end_date
        @notify_extended = true
      end
    end

    @notify_answered = form.answer != initiative.answer && !form.answer.values.all?(&:blank?)

    attrs
  end

  def notify_initiative_is_answered
    Decidim::EventsManager.publish(
      event: "decidim.events.initiatives.initiative_answered",
      event_class: Decidim::Initiatives::AnswerInitiativeEvent,
      resource: initiative,
      followers: initiative.followers
    )
  end
end

Decidim::Initiatives::Admin::UpdateInitiativeAnswer.class_eval do
  prepend UpdateInitiativeAnswerExtends
end
