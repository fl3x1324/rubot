class WebhookController < ApplicationController
  include ReadUtils
  include BibleApi
  include Messaging

  def initialize
    super
    @json = ActiveSupport::JSON
  end

  def process_event
    event = @json.decode request.body.read
    if event && event["object"] && event["object"] == "page"
      messages = event["entry"][0]["messaging"]
      messages.each do |msg|
        if msg.dig("message", "text") && msg.dig("message", "text").downcase.include?("стих за деня")
          puts "Got new message: #{msg.dig("message", "text")} from sender id: #{msg.dig("sender", "id")}"
          text_and_location = verse_text_and_location
          send_text_message msg.dig("sender", "id"), "RESPONSE", text_and_location[:location]
          send_text_message msg.dig("sender", "id"), "RESPONSE", text_and_location[:text]
        end
      end
      hist_rec = HistoryRecord.new request_dump: request.body.read
      puts "History record persisted? #{hist_rec.save ? 'Yes' : 'No'}."
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
