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

require "tk"
require "tkextlib/tkimg" 	# to open jpg images

load "musicmp3_session.rb"

################### GUI #########################################

main_win = TkRoot.new {	title "Russian Music Downloader" }
$session = MusicMp3_Session.new


### full frame ###
content = Tk::Tile::Frame.new(main_win) { padding "3 3 12 12" }.grid(:sticky => 'nsew')
# frame will expand on window resize
TkGrid.columnconfigure main_win, 0, :weight => 1
TkGrid.rowconfigure main_win, 0, :weight => 1


### upper frame ###
u_content = Tk::Tile::Frame.new(content) { padding "3 3 12 12" }.grid(:sticky => 'nsew')
TkGrid.columnconfigure content, 0, :weight => 1
TkGrid.rowconfigure content, 0, :weight => 1

$url = TkVariable.new

url_entry = Tk::Tile::Entry.new(u_content) { width 30; textvariable $url}.grid( :column => 1, :row => 0, :sticky => 'w')
Tk::Tile::Label.new(u_content) { text "URL:" }.grid( :column => 0, :row => 0, :sticky => 'w')

TkWinfo.children(u_content).each { |w| TkGrid.configure w, :padx => 5, :pady => 5 }


### lower frame ###
l_content = Tk::Tile::Frame.new(content) { padding "3 3 12 12" }.grid(:sticky => 'nsew')
TkGrid.columnconfigure content, 0, :weight => 1
TkGrid.rowconfigure content, 0, :weight => 1


### cover preview ###
$cover_content = Tk::Tile::Frame.new(l_content) { padding "3 3 12 12" }.grid( :column => 1, :row => 0)
TkGrid.columnconfigure content, 0, :weight => 1
TkGrid.rowconfigure content, 0, :weight => 1

Tk::Tile::Frame.new($cover_content) { 
	width 80; height 80; borderwidth 5; relief 'sunken' 
}.grid( :column => 0, :row => 2, :sticky => 'w' )
#album_cover = TkPhotoImage.new( open("album_cover.jpg", "rb").read)


### title list with check boxes ###
$tracks_content = Tk::Tile::Frame.new(l_content) { padding "3 3 12 12" }.grid( :column => 2, :row => 0)
TkGrid.columnconfigure content, 0, :weight => 1
TkGrid.rowconfigure content, 0, :weight => 1

### buttons ###
button_content = Tk::Tile::Frame.new(l_content) { padding "3 3 12 12" }.grid( :column => 3, :row => 0)
TkGrid.columnconfigure content, 0, :weight => 1
TkGrid.rowconfigure content, 0, :weight => 1

$btn_download = Tk::Tile::Button.new(button_content) { 
	text "download"
	command {b_download} 
	state "disabled" 
}.grid(:column => 0, :row => 1, :sticky => 'w')

$btn_open = Tk::Tile::Button.new(button_content) { 
	text "open"
	command {b_open}
}.grid(:column => 0, :row => 0, :sticky => 'e')

TkWinfo.children(button_content).each { |w| TkGrid.configure w, :padx => 5, :pady => 5 }

TkWinfo.children(l_content).each { |w| TkGrid.configure w, :padx => 5, :pady => 5 }

url_entry.focus


### functions ###
def b_open
	ret = $session.download_page($url.to_s)

	# error in download_page()
	unless ret == ""
		msgBox = Tk.messageBox(
			'type'    => "ok",  
			'icon'    => "info", 
			'title'   => "Error",
			'message' => ret
		)
		return
	end

	$btn_download.state("!disabled") 

	# add artist and album name to gui
	if $artist_label != nil or $album_name_label != nil
		$artist_label.text("")
		$album_name_label.text("")
	end
		
	$artist_label = Tk::Tile::Label.new($cover_content) { text $session.artist }.grid(:column => 0, :row => 0, :sticky => 'w')
	$album_name_label = Tk::Tile::Label.new($cover_content) { text $session.album_name }.grid(:column => 0, :row => 1, :sticky => 'w')

	# add tracks to gui
	#TODO checkboxes
	if $song_labels != nil
		$song_labels.each{ |s| s.text("") }
	end

	track_num = 1

	$song_labels = []

	$session.tracks.each { |t|
		str = track_num.to_s + " - " + t[0]
		$song_labels << Tk::Tile::Label.new($tracks_content) {
			text str
		}.grid(:column => 0, :row => track_num-1, :sticky => 'w')
		track_num = track_num + 1
	}
end


def b_download
	$btn_download.state("disabled")
	$btn_open.state("disabled")

	$session.prepare_song_download
	song_num = $session.tracks.size	

	Thread.new do
		(0...song_num).each do |i|
			$song_labels[i].foreground = "blue"
			$session.download_song(i)
			$song_labels[i].foreground = "black"
		end
		puts "finished downloading"
		$btn_download.state("!disabled")
		$btn_open.state("!disabled")
	end
end

# open GUI
Tk.mainloop

