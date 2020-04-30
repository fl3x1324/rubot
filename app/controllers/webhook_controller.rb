class WebhookController < ApplicationController
  def initialize
    super
    @json = ActiveSupport::JSON
  end

  def process_event
    event = @json.decode request.body.read
    if event && event["object"] && event["object"] == "page"
      messages = event["entry"][0]["messaging"]
      messages.each do |msg|
        puts "Got new message: #{msg["message"]["text"]} from sender id: #{msg["sender"]["id"]}"
        puts "JSON: #{request.body.read}"
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
