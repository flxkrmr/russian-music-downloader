#!/usr/bin/env ruby

require "tk"
require "tkextlib/tkimg" 	# to open jpg images
#require "tkextlib/title"

main_win = TkRoot.new {	title "Russian Music Downloader" }

# full frame
content = Tk::Tile::Frame.new(main_win) { padding "3 3 12 12" }.grid(:sticky => 'nsew')
# frame will expand on window resize
TkGrid.columnconfigure main_win, 0, :weight => 1
TkGrid.rowconfigure main_win, 0, :weight => 1

# upper frame
u_content = Tk::Tile::Frame.new(content) { padding "3 3 12 12" }.grid(:sticky => 'nsew')
TkGrid.columnconfigure content, 0, :weight => 1
TkGrid.rowconfigure content, 0, :weight => 1

$url = TkVariable.new

url_entry = Tk::Tile::Entry.new(u_content) { width 30; textvariable $url}.grid( :column => 1, :row => 0, :sticky => 'w')
Tk::Tile::Label.new(u_content) { text "URL:" }.grid( :column => 0, :row => 0, :sticky => 'w')

TkWinfo.children(u_content).each { |w| TkGrid.configure w, :padx => 5, :pady => 5 }

# lower frame
l_content = Tk::Tile::Frame.new(content) { padding "3 3 12 12" }.grid(:sticky => 'nsew')
TkGrid.columnconfigure content, 0, :weight => 1
TkGrid.rowconfigure content, 0, :weight => 1

# cover preview
Tk::Tile::Frame.new(l_content) { 
	width 80; height 80; borderwidth 5; relief 'sunken' 
}.grid( :column => 0, :row => 0, :sticky => 'w' )
album_cover = TkPhotoImage.new( open("album_cover.jpg", "rb").read)
# title list with check boxes
# TODO

# buttons
button_content = Tk::Tile::Frame.new(l_content) { padding "3 3 12 12" }.grid( :column => 3, :row => 0)
TkGrid.columnconfigure content, 0, :weight => 1
TkGrid.rowconfigure content, 0, :weight => 1

btn_open = Tk::Tile::Button.new(button_content) { text "open" }.grid(:column => 0, :row => 0, :sticky => 'e')
btn_download = Tk::Tile::Button.new(button_content) { text "download"; state "disabled"}.grid(:column => 0, :row => 1, :sticky => 'w')

TkWinfo.children(button_content).each { |w| TkGrid.configure w, :padx => 5, :pady => 5 }

TkWinfo.children(l_content).each { |w| TkGrid.configure w, :padx => 5, :pady => 5 }

url_entry.focus


# open GUI
Tk.mainloop
