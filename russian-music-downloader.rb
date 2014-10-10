#!/usr/bin/env ruby

require "net/http"
require "nokogiri"

class MusicMp3_Session
	@cookie

	attr_accessor :cookie

	def boo(d)
		a = 1234554321
		c = 7
		b = 305419896
		e = 0

		while e < d.size
			f = d[e].ord & 255
			a = a^((a&63)+c)*f+(a<<8)
			b = b + (b<<8^a)
			c = c + f
			e = e + 1
		end
		a = a & -2147483649
		b = b & -2147483649
		d = a.to_s(16)
		c = b.to_s(16)

		ret_a = ("0000" + a.to_s(16))
		ret_a = ret_a[ (d.size-4) ... ret_a.size ]

		ret_b = ("0000" + b.to_s(16))
		ret_b = ret_b[ (c.size-4) ... ret_b.size ]

		ret_a + ret_b
	end

	def create_url(tn, rel) # originally creates an array with all urls of the album
		start_url = "listen.musicmp3.ru" #normally dynamic: $('.tracklist').data('url')
		
		#tn = "track1" # must be $track.prop('id')	
		#cookie = "bieau2ka95f58854" # getCookie('SessionId').substring(8)) ; currently my cookie viewed in firefox
					    # needs to be dynamic for each loaded page
		#rel = "26e6b0df0ccebf1b" # $this.find('.js_play_btn').prop('rel')
		item = start_url + "/" + boo( tn[5...tn.size] + @cookie[8...@cookie.size] ) + "/" + rel
	end
end


if ARGV == nil
	raise ArgumentError, "Please give me an URL!"
end

url = ARGV[0]
url_edit = url
url_edit = url_edit.sub("http://", "")
url_edit = url_edit.sub("https://", "")
url_edit = url_edit.sub("www.", "")
url_edit = url_edit.split("/")

# won't accept different pages than these:
unless url_edit[0] == "musicmp3.ru"
	raise ArgumentError, "I can only download from \"musicmp3.ru\""
end

page = "/" + url_edit[1].split("#")[0]

puts page

# get page
http = Net::HTTP.new(url_edit[0], 80)

http_response = http.get(page)

unless http_response.code == "200"
	puts "Couldn't load page, response " + http_response.code.to_s
	exit
end

all_cookies = http_response.get_fields("set-cookie")

unless all_cookies != nil
	puts "No Cookies on received"
	exit
end

# TODO dirty code..fix this!
# get session id from cookies
session_id = all_cookies[0].split("; ")[0].split("=")[1]

# parsing artist and album name
page = Nokogiri::HTML(http_response.body)

full_title = page.css("title").text.split(" - ")
artist = full_title[1]
album_name = full_title[0].sub("Listen to ", "")

puts "Downloading Album \"#{album_name}\" by \"#{artist}\""

# parsing songs
track_table = page.css("tr")
tracks = Array.new

track_table.each do |track|
	track_rel = track.css("a[title='Play track']")[0]["rel"]
	track_name = track.css("span[itemprop='name']")[0].text
	track_name.sub!("/", "-")
	track_id = track["id"]
	tracks << [track_name, track_rel, track_id]
end

session = MusicMp3_Session.new
session.cookie = session_id


index = 1

# TODO threads
tracks.each do |t|
	url = session.create_url(t[2], t[1]).to_s
	puts t[0].to_s + ": " + url
	file_name = artist + " - " + ("%02d" % index) + " - " + t[0] + ".mp3"
	puts "Downloading \"#{file_name}\"..."
	mp3 = URI("http://" + url)
	mp3_data = Net::HTTP.get(mp3)
	one_file = File.open(file_name, "w")
	one_file.write(mp3_data)
	one_file.close
	puts "File done"
	index = index + 1
end


