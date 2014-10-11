##!/usr/bin/env ruby

require "net/http"
require "nokogiri"

class MusicMp3_Session
	@cookie
	@url
	@album_name
	@artist
	@tracks

	attr_reader :cookie, :url, :artist, 
	            :album_name, :tracks

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
	
		# code from javascript of homepage		
		#tn =  $track.prop('id')	
		#cookie = getCookie('SessionId').substring(8))
		#rel =  $this.find('.js_play_btn').prop('rel')

		item = start_url + "/" + boo( tn[5...tn.size] + @cookie[8...@cookie.size] ) + "/" + rel
	end

	def download_page(url)
		unless url.is_a? String
			raise ArgumentError, "url must be a string"
		end

		@url = url

		# parse given URL
		url_edit = @url
		url_edit = url_edit.sub("http://", "")
		url_edit = url_edit.sub("https://", "")
		url_edit = url_edit.sub("www.", "")
		url_edit = url_edit.split("/")

		# won't accept different pages than these:
		unless url_edit[0] == "musicmp3.ru"
			raise ArgumentError, "I can only download from \"musicmp3.ru\""
		end

		page = "/" + url_edit[1].split("#")[0]

		# get page
		http = Net::HTTP.new(url_edit[0], 80)

		http_response = http.get(page)

		unless http_response.code == "200"
			#TODO raise error
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
		@cookie = session_id

		# parsing artist and album name
		page = Nokogiri::HTML(http_response.body)

		full_title = page.css("title").text.split(" - ")
		@artist = full_title[1]
		@album_name = full_title[0].sub("Listen to ", "")

		# parsing songs
		track_table = page.css("tr")
		@tracks = Array.new

		track_table.each do |track|
			track_rel = track.css("a[title='Play track']")[0]["rel"]
			track_name = track.css("span[itemprop='name']")[0].text
			track_name.sub!("/", "-")
			track_id = track["id"]
			@tracks << [track_name, track_rel, track_id]
		end

	end
	def download_songs
		# create folders
		# can't create folders with "/" in the name
		artist = @artist.sub("/", "-")
		album_name = @album_name.sub("/", "-")

		unless Dir.exists? artist
			Dir.mkdir artist
		end

		album_folder = artist + "/" + album_name

		unless Dir.exists? (album_folder)
			Dir.mkdir (album_folder)
		else
			# what if album already exists
			album_num = 1
			while Dir.exists? (album_folder + " " + album_num.to_s)
				album_num = album_num + 1
			end
			album_folder = album_folder + " " + album_num.to_s
			Dir.mkdir (album_folder)
		end
		index = 1

		# TODO threads
		@tracks.each do |t|
			url = create_url(t[2], t[1]).to_s
			#puts t[0].to_s + ": " + url
			file_name = @artist + " - " + ("%02d" % index) + " - " + t[0] + ".mp3"
			puts "Downloading \"#{file_name}\"..."
			mp3 = URI("http://" + url)
			mp3_data = Net::HTTP.get(mp3)
			one_file = File.open(album_folder + "/" + file_name, "w")
			one_file.write(mp3_data)
			one_file.close
			index = index + 1
		end
	end
end


##############################################################################
#######     MAIN    ##########################################################
##############################################################################

#TODO add console support
=begin
if ARGV == nil
	raise ArgumentError, "Please give me an URL!"
end

url = ARGV[0]

session = MusicMp3_Session.new
session.download_page(url)
puts "Downloading Album \"#{session.album_name}\" by \"#{session.artist}\""

session.download_songs
exit
=end
