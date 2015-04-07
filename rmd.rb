#!/usr/bin/env ruby
#
# Copyright (C) 2015 Felix Kramer. All rights reserved.
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
require "optparse"
#TODO disable with argument
require "colorize"

URL_BASE = "musicmp3.ru"
URL_LISTEN_BASE = "listen.musicmp3.ru"

class UserInterface
  URL_PAGE = "/search.html?text="

  attr_reader :options

  def parseArgv
    @options = {}

    optparse = OptionParser.new do |opts|
      opts.banner = "Usage: blablba"

      @options[:colorize] = false
      opts.on( '-c', "--colorize", "Generate coloured output in shell") do
        @options[:colorize] = true
      end

      @options[:url] = nil
      opts.on( "-u", "--url URL", "Download directly from URL") do |url|
        unless @options[:search].nil?
          puts "-u and --url can only be used without -s and --search"
          puts opts
          exit
        end
        @options[:url] = url
      end

      @options[:search] = nil
      opts.on( "-s", "--search SEARCH", "Search an Album") do |search|
        unless @options[:url].nil?
          puts "-s and --search can only be used without -u and --url"
          puts opts
          exit
        end
        @options[:search] = search
      end

      opts.on( "-h", "--help", "Print this help screen") do
        puts opts
        exit
      end
    end

    optparse.parse!
  end


  def searchArtists
    # get page and check return code
    http = Net::HTTP.new(URL_BASE, 80)
    # make the search string URL save
    s_urlsave = URI.escape(options[:search].gsub(" ","+"))
    http_response = http.get(URL_PAGE + s_urlsave)
    unless http_response.code == "200"
      puts "Couldn't load page, response " + http_response.code.to_s
      exit
    end

    # parse everything with Nokogiri
    html = Nokogiri::HTML(http_response.body)

    # <li> includes the whole artist-genre-albums package
    artists_unp = html.css("li[class='artist_preview']")

    # albums will be an array of hashes, including artist name,
    # album name, and link
    albums = []

    # check if search was successful
    if artists_unp.empty?
      puts "Nothing found, sorry!"
      exit
    end

    # start parsing
    artists_unp.each do |art|
      artist = art.css("a[class='artist_preview__title']").text
      art.css("a[class='tags__item__link']").each do |alb|
        albums << { "artist" => artist,
                    "name" => alb.content,
                    "link" => alb['href'] }
      end
    end

    # print results
    current_artist = ""
    albums.each_with_index do |a, i|
      # each artist is only printed once
      unless current_artist == a["artist"]
        current_artist = a["artist"]
        puts "+++ #{current_artist} +++"
      end
      #TODO put this in if sequence to exclude String.yellow if needed
      puts "[#{i.to_s.yellow}] - #{a["name"]}"
    end
  end
end

class MusicMp3Session
  @cookie
  @url
  @album_name
  @artist
  @tracks

  attr_reader :cookie, :url, :artist,
              :album_name, :tracks

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
    unless url_edit[0] == URL_BASE
      puts "I can only download from \"musicmp3.ru\""
      exit
    end

    page = "/" + url_edit[1].split("#")[0]

    # get page
    http = Net::HTTP.new(url_edit[0], 80)

    http_response = http.get(page)

    unless http_response.code == "200"
      puts "Couldn't load page, response " + http_response.code.to_s
      exit
      #return "Couldn't load page, response " + http_response.code.to_s
    end

    all_cookies = http_response.get_fields("set-cookie")

    unless all_cookies != nil
      puts "No cookies received"
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
      @tracks << { "name" => track_name,
                   "rel"  => track_rel,
                   "id"   => track_id }
    end
  end

  # download song with given index
  def download_song(index)
    t = @tracks[index]
    #url = create_url(t[2], t[1]).to_s

    # create the very secred url. code stolen from javascript of the homepage
    #tn =  $track.prop('id')
    #cookie = getCookie('SessionId').substring(8))
    #rel =  $this.find('.js_play_btn').prop('rel')
    url = URL_LISTEN_BASE + "/" +
          boo(t["id"][5...t["id"].size] + @cookie[8...@cookie.size]) +
          "/" + t["rel"]

    file_name = @artist + " - " + ("%02d" % (index + 1)) + " - " + t["name"] + ".mp3"
    mp3 = URI("http://" + url)

    # get the file
    # TODO check answer
    mp3_data = Net::HTTP.get(mp3)
    mp3_file = File.open(@album_folder + "/" + file_name, "w")
    mp3_file.write(mp3_data)
    mp3_file.close
  end

  # prepare data environment for download_song (folders and stuff)
  def prepare_songs_download
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

  private

  # strange hash function, also stolen from the homepage
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
end


##############################################################################
#######     MAIN    ##########################################################
##############################################################################

ui = UserInterface.new
ui.parseArgv

unless ui.options[:url].nil?
  url = ui.options[:url]
  session = MusicMp3Session.new
  session.download_page(url)
  session.prepare_songs_download
  puts "Downloading Album \"#{session.album_name}\" by \"#{session.artist}\":"

  session.tracks.each_with_index do |t, i|
    # show the user that something is going on
    puts "Downloading #{"%02d" % (i + 1)} - \"#{t["name"]}\"..."
    session.download_song(i)
  end

  exit
end

unless ui.options[:search].nil?
  ui.searchArtists

  exit
end

exit
