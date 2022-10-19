# frozen_string_literal: true

module MeetingsControllerExtends
  private

  def meetings
    @meetings ||= paginate(search.results.order(start_time: filter_by_past_date? ? :desc : :asc))
  end

  def filter_by_past_date?
    params.dig("filter", "date")&.include?("past")
  end
end

Decidim::Meetings::MeetingsController.class_eval do
  prepend(MeetingsControllerExtends)
end
