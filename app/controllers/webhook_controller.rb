class WebhookController < ApplicationController
  require 'net/http'

  def initialize
    super
    @json = ActiveSupport::JSON
    @books_english = {
        "Филипяни" => "Philippians",
        "Матей" => "Matthew",
    }
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

  def test_verse
    verse = read_verses_from_sheet
    res = fetch_verse_text verse
    text = ""
    if res
      body = res.body
      json = @json.decode body.gsub("(", "").gsub(")", "").gsub(";", "")
      puts json
      json["book"].each do |book|
        book["chapter"].each do |k, v|
          text += "#{k}. #{v["verse"]}\n"
        end
      end
    end
    render plain: text, status: 200
  end

  private

  def read_verses_from_sheet
    xlsx = Roo::Excelx.new ENV["VERSES_FILE_PATH"]
    sheet = xlsx.sheet Date.today.year.to_s
    rows = sheet.parse(year: "Година", day: "Ден", verses: "Стихове", version: "Версия", comments: "Допълнително")
    filtered = rows.select { |row| row[:day] == Date.today }
    if (verses = filtered.first[:verses])
      match_data = /^\s*(\d*\s*\W+?)\s*(\d+)\s*:\s*(\d*)\s*-*\s*(\d*)/.match verses
      puts %(
        Book: #{match_data[1].gsub " ", ""},
        Chapter: #{match_data[2]},
        Starting verse: #{match_data[3]}
        Ending verse: #{match_data[4]}.
      )
      verse = {p: "#{@books_english[match_data[1].gsub " ", ""]}#{match_data[2]}:#{match_data[3]}", v: "bulgarian1940"}
      if match_data[4]
        verse[:p] += "-#{match_data[4]}"
        verse
      end
    end
  end

  def fetch_verse_text(verse)
    uri = URI ENV["BIBLE_API_URL"]
    uri.query = URI.encode_www_form verse
    fetch uri, 5
  end

  def fetch(uri, limit = 10)
    Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == "https") do |http|
      req = Net::HTTP::Get.new uri
      res = http.request req
      case res
      when Net::HTTPSuccess
        res
      when Net::HTTPRedirection
        location = res["location"]
        fetch URI(location), limit - 1
      else
        res.value
      end
    end
  end
end
