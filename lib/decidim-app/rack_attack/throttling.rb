module DecidimApp
  module RackAttack
    module Throttling
      AUTHORIZED_THROTTLING_PATHS = ["/decidim-packs", "/rails/active_storage", "/admin/"]

      # If true: request must not be taken in account by Rack Attack Throttling
      def self.authorized_path?(path)
        AUTHORIZED_THROTTLING_PATHS.map { |authorized| path.start_with?(authorized) }.include?(true)
      end

      def self.name
        "req/ip"
      end

      def self.max_requests
        Rails.application.secrets.dig(:decidim, :rack_attack, :throttle, :max_requests)
      end

      def self.period
        Rails.application.secrets.dig(:decidim, :rack_attack, :throttle, :period)
      end

      # Define how many time user is throttled
      # If no match_data_h keys found
      # returns Int (default: 60)
      def self.time_limit_for(match_data_h)
        return 60 if match_data_h.blank? || match_data_h[:epoch_time].blank? || match_data_h[:period].blank?

        now = match_data_h[:epoch_time]
        limit = now + (match_data_h[:period] - (now % match_data_h[:period]))

        limit - now
      end

      def self.deactivate_decidim_throttling!(&block)
        return unless block_given?

        Rails.application.config.after_initialize do
          block.call
        end
      end

      def self.html_template(until_period, organization_name)
        name = organization_name.presence || "our platform"

        "
<!DOCTYPE html>
<html>
<head>
  <title>Too many requests</title>
  <meta name='viewport' content='width=device-width,initial-scale=1'>
  <style>
  .rails-default-error-page {
    background-color: #EFEFEF;
    color: #2E2F30;
    text-align: center;
    font-family: arial, sans-serif;
    margin: 0;
  }

  .rails-default-error-page div.dialog {
    width: 95%;
    max-width: 33em;
    margin: 4em auto 0;
  }

  .rails-default-error-page div.dialog > div {
    border: 1px solid #CCC;
    border-right-color: #999;
    border-left-color: #999;
    border-bottom-color: #BBB;
    border-top: #B00100 solid 4px;
    border-top-left-radius: 9px;
    border-top-right-radius: 9px;
    background-color: white;
    padding: 7px 12% 0;
    box-shadow: 0 3px 8px rgba(50, 50, 50, 0.17);
  }

  .rails-default-error-page h1 {
    font-size: 100%;
    color: #730E15;
    line-height: 1.5em;
  }

  .rails-default-error-page div.dialog > p {
    margin: 0 0 1em;
    padding: 1em;
    background-color: #F7F7F7;
    border: 1px solid #CCC;
    border-right-color: #999;
    border-left-color: #999;
    border-bottom-color: #999;
    border-bottom-left-radius: 4px;
    border-bottom-right-radius: 4px;
    border-top-color: #DADADA;
    color: #666;
    box-shadow: 0 3px 8px rgba(50, 50, 50, 0.17);
  }
  </style>
</head>

<body class='rails-default-error-page'>
  <div class='dialog'>
    <div>
      <b>#{I18n.t("rack_attack.too_many_requests.title", organization_name: name)}</b>
      <br>
      <h1>429 - Too many requests</h1>
      <p>#{I18n.t("rack_attack.too_many_requests.message")}</p>

      <b>#{I18n.t("rack_attack.too_many_requests.time")}</b>

      <br>
      <b class='counter'><span id='timer'>#{until_period}</span> #{I18n.t("rack_attack.too_many_requests.time_unit")}</b>
    </div>
  </div>

<script>
    let timer = document.getElementById('timer')
    let total = timer.textContent

    const interval = setInterval(updateTimer, 1000)

    function updateTimer() {
        if (total <= 0) {
            clearInterval(interval)
            location.reload()
        } else {
            console.log(total)
            timer.innerHTML = total
            total -= 1
        }
    }
</script>

</body>
</html>

"
      end
    end
  end
end