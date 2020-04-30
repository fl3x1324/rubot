class WebhookController < ApplicationController
  require 'net/http'

  def initialize
    super
    @json = ActiveSupport::JSON
  end

  def process_event
    event = @json.decode request.body.read
    if event && event["object"] && event["object"] == "page"
      puts "JSON: #{request.body.read}"
      messages = event["entry"][0]["messaging"]
      messages.each do |msg|
        puts "Got new message: #{msg.dig("message", "text")} from sender id: #{msg.dig("sender", "id")}"
        reply = {
            messaging_type: "RESPONSE",
            recipient: {
                id: msg.dig("sender", "id"),
            },
            message: {
                text: "Слава Богу!",
            },
        }
        uri = URI ENV["SEND_API_URL"]
        req = Net::HTTP::Post.new uri
        req["Content-Type"] = "application/json"
        req.body = reply.to_json
        Net::HTTP.start(uri.host, uri.port, :use_ssl => true) do |http|
          puts "Replying with message: #{reply.to_json}"
          http.request req
        end if msg.dig("message", "text")
      end
      hist_rec = HistoryRecord.new request_dump: request.body.read
      puts "History record persisted? #{hist_rec.save}"
      render plain: "EVENT_RECEIVED"
    else
      render plain: "ERROR!", status: :bad_request
    end
  end

  def verify_token
    hub_mode = params["hub.mode"]
    hub_verify_token = params["hub.verify_token"]
    hub_challenge = params["hub.challenge"]
    if hub_mode == "subscribe" && hub_verify_token == ENV["FBBOT_VERIFYTOKEN"]
      render plain: hub_challenge
    else
      render status: :forbidden
    end
  end
end
