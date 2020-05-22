module BibleApi
  require 'net/http'

  def fetch_verse_text(verse)
    puts "trying to fetch verse: #{verse} text from GetBible API"
    uri = URI ENV["BIBLE_API_URL"]
    uri.query = URI.encode_www_form verse
    fetch uri, 5
  end

  private

  def fetch(uri, limit = 10)
    Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == "https") do |http|
      req = Net::HTTP::Get.new uri
      res = http.request req
      case res
      when Net::HTTPSuccess
        puts "successfully fetched verse text form GetBible's API"
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
