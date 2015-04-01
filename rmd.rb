#!/usr/bin/env ruby
#
# Copyright (C) 2014 Felix Kramer. All rights reserved.
#
# felixkramerroki@aol.com
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
#

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

        # TODO rename to init_download
	def download_page(url)
		unless url.is_a? String
			#raise ArgumentError, "url must be a string"
			return "url must be a string"
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
			#raise ArgumentError, "I can only download from \"musicmp3.ru\""
			return "Only URLs from \"musicmp3.ru\" are supported"
		end

		page = "/" + url_edit[1].split("#")[0]

		# get page
		http = Net::HTTP.new(url_edit[0], 80)

		http_response = http.get(page)

		unless http_response.code == "200"
			#puts "Couldn't load page, response " + http_response.code.to_s
			#exit
			return "Couldn't load page, response " + http_response.code.to_s
		end

		all_cookies = http_response.get_fields("set-cookie")

		unless all_cookies != nil
			#puts "No Cookies on received"
			#exit
			return "No Cookies on received"
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
		
		return ""
	end
	
	# download song with given index
	def download_song(index)
		t = tracks[index]
		url = create_url(t[2], t[1]).to_s
		file_name = @artist + " - " + ("%02d" % (index + 1)) + " - " + t[0] + ".mp3"
		mp3 = URI("http://" + url)
		mp3_data = Net::HTTP.get(mp3)
		one_file = File.open(@album_folder + "/" + file_name, "w")
		one_file.write(mp3_data)
		one_file.close
	end	

	# prepare environment for download_song()
	def prepare_song_download
		# create folders
		# can't create folders with "/" in the name
		artist = @artist.sub("/", "-")
		album_name = @album_name.sub("/", "-")

		unless Dir.exists? artist
			Dir.mkdir artist
		end

		@album_folder = artist + "/" + album_name

		unless Dir.exists? (@album_folder)
			Dir.mkdir (@album_folder)
		else
			# what if album already exists
			album_num = 1
			while Dir.exists? (@album_folder + " " + album_num.to_s)
				album_num = album_num + 1
			end
			@album_folder = @album_folder + " " + album_num.to_s
			Dir.mkdir (@album_folder)
		end
	end

	# download all songs, older function	
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

if ARGV[0].nil?
	raise ArgumentError, "Please give me an URL!"
end

url = ARGV[0]

session = MusicMp3_Session.new
session.download_page(url)
puts "Downloading Album \"#{session.album_name}\" by \"#{session.artist}\""

session.download_songs
exit
