module ReadUtils
  require 'roo'
  require 'csv'

  def read_verses_from_sheet
    puts "reading from xlsx file..."
    xlsx = Roo::Excelx.new ENV["VERSES_FILE_PATH"]
    sheet = xlsx.sheet Date.today.year.to_s
    rows = sheet.parse(year: "Година", day: "Ден", verses: "Стихове", version: "Версия", comments: "Допълнително")
    filtered = rows.select { |row| row[:day] == Date.today }
    if (verses = filtered.first[:verses])
      match_data = /^\s*(\d*\s*\W+?)\s*(\d+)\s*:\s*(\d*)\s*-*\s*(\d*)/.match verses
      puts %(
        Book: #{match_data[1]},
        Chapter: #{match_data[2]},
        Starting verse: #{match_data[3]}
        Ending verse: #{match_data[4]}.
      )
      books_dict = books_dictionary
      verse = {p: "#{books_dict[match_data[1].downcase]}#{match_data[2]}:#{match_data[3]}", v: "bulgarian1940"}
      if match_data[4]
        verse[:p] += "-#{match_data[4]}"
        verse
      end
    end
  end

  def verse_text_and_location
    verse = read_verses_from_sheet
    res = fetch_verse_text verse
    text = ""
    if res
      body = res.body
      json = @json.decode body.gsub("(", "").gsub(")", "").gsub(";", "")
      puts json
      json["book"].each do |book|
        book["chapter"].each do |k, v|
          text += "#{k}. #{v["verse"]}"
        end
      end
    end
    {text: text, location: verse[:p]}
  end

  private

  def books_dictionary
    rows = CSV.read("resources/books.csv")
    books_hash = {}
    rows.each do |row|
      books_hash[row[0]] = row[-1]
    end
    books_hash
  end
end