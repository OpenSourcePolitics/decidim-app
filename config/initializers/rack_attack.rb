# frozen_string_literal: true

# Enabled by default in production
# Can be deactivated with 'ENABLE_RACK_ATTACK=0'
return if Rails.application.secrets.dig(:decidim, :rack_attack, :enabled) == 0

Rack::Attack.enabled = (Rails.application.secrets.dig(:decidim, :rack_attack, :enabled) == 1) || Rails.env.production?
Rack::Attack.throttled_response_retry_after_header = true

# By default use the memory store for inspecting requests
# Better to use MemCached or Redis in production mode
Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new if !ENV["MEMCACHEDCLOUD_SERVERS"] || Rails.env.test?

# Remove the original throttle fron decidim-core
# see https://github.com/decidim/decidim/blob/release/0.26-stable/decidim-core/config/initializers/rack_attack.rb#L19
Rails.application.config.after_initialize do
  Rack::Attack.throttles.delete("requests by ip")
end

Rack::Attack.throttled_responder = lambda do |request|
  rack_logger = Logger.new(Rails.root.join("log/rack_attack.log"))

  request_uuid = request.env["action_dispatch.request_id"]
  params = {
    "ip" => request.ip,
    "path" => request.path,
    "get" => request.GET,
    "host" => request.host,
    "referer" => request.referer
  }

  rack_logger.warn("[#{request_uuid}] #{params}")

  [429, { "Content-Type" => "text/html" }, [html_template(10, request.env["decidim.current_organization"]&.name)]]
end

Rack::Attack.throttle("req/ip",
                      limit: Rails.application.secrets.dig(:decidim, :rack_attack, :throttle, :max_requests),
                      period: Rails.application.secrets.dig(:decidim, :rack_attack, :throttle, :period)) do |req|
  req.ip unless req.path.start_with?("/decidim-packs") || req.path.start_with?("/rails/active_storage") || req.path.start_with?("/admin/")
end

if Rails.application.secrets.dig(:decidim, :rack_attack, :fail2ban, :enabled) == 1
  # Block suspicious requests made for pentesting
  # After 1 forbidden request, block all requests from that IP for 1 hour.
  Rack::Attack.blocklist("fail2ban pentesters") do |req|
    # `filter` returns truthy value if request fails, or if it's from a previously banned IP
    # so the request is blocked
    Rack::Attack::Fail2Ban.filter("pentesters-#{req.ip}", maxretry: 0, findtime: 10.minutes, bantime: 1.hour) do
      # The count for the IP is incremented if the return value is truthy
      req.path.include?("/etc/passwd") ||
        req.path.include?("/wp-admin/") ||
        req.path.include?("/wp-login/") ||
        req.path.include?("SELECT") ||
        req.path.include?("CONCAT") ||
        req.path.include?("UNION%20SELECT") ||
        req.path.include?("/.git/")
    end
  end
end

def html_template(until_period, organization_name)
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
