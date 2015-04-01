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
#TODO disable with argument
require "colorize"

class MusicSearcher
  URL_BASE = "musicmp3.ru"
  URL_PAGE = "/search.html?text="
  URL_OPTION_ALBUMS = "&all=album"
  URL_OPTION_SONGS = "&all=songs"
  URL_OPTION_ARTISTS = "&all=artists"

  
  def search(s)
    url_page = URL_PAGE + parse_args(s)

		http = Net::HTTP.new(URL_BASE, 80)

		http_response = http.get(url_page)

		unless http_response.code == "200"
			#puts "Couldn't load page, response " + http_response.code.to_s
			#exit
			return "Couldn't load page, response " + http_response.code.to_s
		end

    #TODO: parse http_response.body
    html = Nokogiri::HTML(http_response.body)

    albums_unp = html.css("a[class='tags__item__link']")
    albums = []

    if albums_unp.empty?
      puts "nothing found"
      exit
    end

    albums_unp.each do |a|
      albums << {"name" => a.content, "link" => a['href']}
      a.text
    end

    #print menu
    albums.each_with_index do |a, i|
      puts "[#{i.to_s.yellow}] - #{a["name"]}"
    end
  end
  

  private

    def parse_args(argv = nil)
      unless argv.is_a? String
        raise ArgumentError, "url must be a string"
      end

      URI.escape(argv.gsub(" ","+"))
    end
end

if ARGV[0].nil?
	raise ArgumentError, "Please give me a search"
end

search = ARGV[0]

ms = MusicSearcher.new
ms.search(search)
