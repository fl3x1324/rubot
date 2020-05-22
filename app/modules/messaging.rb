module Messaging
  require 'net/http'

  def send_text_message(recipient, type, text)
    reply = {
        messaging_type: type,
        recipient: {
            id: recipient,
        },
        message: {
            text: text,
        },
    }
    uri = URI ENV["SEND_API_URL"]
    req = Net::HTTP::Post.new uri
    req["Content-Type"] = "application/json"
    req.body = reply.to_json
    Net::HTTP.start(uri.host, uri.port, :use_ssl => true) do |http|
      puts "Replying with message: #{reply.to_json}"
      http.request req
    end
  end
end
