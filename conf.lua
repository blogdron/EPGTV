-------------------------------------------------------------------------------
-- User configuration file, if you change value you override default value
-- if you delete some key+value for this pair used default value from main.lua
-- This file is optional, you can delete this config, if this config have syntax
-- error this config be ignored and used default values from main.lua src file
-------------------------------------------------------------------------------
local config =
{
   -- key binding -------------------------------------------------------------
   key_update_epg     = 'u',  -- manual upgrade EPG for current playlist
   key_preload_epg    = 'g',  -- manual load all tv cache and try find channel
   key_show_program   = 'h',  -- general show tv program information
   key_show_toggle    = 'y',  -- works like key_show_program but as switcher
   key_scroll_program = 'n',  -- scroll down current tv channel information
   key_close_program  = 'esc',-- manual close tv information
   -- manual show by update, preload, show, switch (scroll ignore it) ---------
   manual_show_mode   = 2,    -- mode 1 == manual detail, mode 2 == full detail
   manual_show_details= 2,    -- number programs if manual_show_mode == 1
   -- auto show ---------------------------------------------------------------
   auto_show_program  = true, -- show tv program if tv channel opened, changed
   auto_show_mode     = 2,    -- mode 1 == manual detail, mode 2 == full detail
   auto_show_details  = 2,    -- number programs if auto_show_mode == 1
   -- auto close --------------------------------------------------------------
   auto_close_program = true, -- autoclose tv program (scroll,toggle ignored it)
   auto_close_duration= 5,    -- sec to close tv program (scroll,toggle ignored it)
   -- update progress ---------------------------------------------------------
   update_visual_progress = true,-- enable redraw clock, progress bar / percent
   update_progress_duration = 5, -- sec to update clock, progress bar / percent
   -- time correction ---------------------------------------------------------
   ignore_tvg_shift   = true,  -- dont use additional shift time for EPG
   ignore_time_zone   = false, -- if need directly use EPG time as local time
   -- special -----------------------------------------------------------------
   ignore_noepg_m3u   = true, -- ignore playlist if M3U not contains EPG link
   -- system depend configuration ---------------------------------------------
   curl_path   = '/usr/bin/curl', -- set fullpath to you curl installation
   gzip_path   = '/usr/bin/gzip', -- set fullpath to you gzip installation
   ----------------------------------------------------------------------------
   -- visual/style, colors and font sizes (! use BGR colors, not RGB !)
   ----------------------------------------------------------------------------
   -- current tv program  --
   -------------------------
   title_color       = '00FBFE', -- now playing title color
   title_size        = '50',     -- now playing title font size
   description_color = '54E5B2', -- now playing description_color
   description_size  = '25',     -- now playing description size
   progress_size     = '40',     -- percentual progress font size
   -------------------------
   -- upcoming tv program --
   -------------------------
   upcoming_color       = 'FFFFFF',  -- upcoming title color
   upcoming_time_size   = '25',      -- upcoming broadcast time font size
   upcoming_title_size  = '35',      -- upcoming broadcast title font size
   upcoming_description_color = 'C9DBE0', -- this day description color
   upcoming_description_size  = '17',     -- this day description size
   -------------------------
   -- tomorrow tv program --
   -------------------------
   tomorrow_prefix_color = '3643FC', -- next day notice message color
   tomorrow_prefix_size  = '25',     -- next day notice message size
   -------------------------
   --  top bar and clock  --
   -------------------------
   clock_color = '00FBFE',        -- clock color on top right side
   clock_bold  = true,            -- set false if clock outside screen
   progress_bar_color = '00FBFE', -- progress bar line color
   -------------------------
   -- darkness background --
   -------------------------
   background_opacity = '40',    -- allow 20,40,60,80,100 percents opacity
   background_color   = '000000',-- change background color if you need it
   --------------------------
   --  message no tv info  --
   --------------------------
   no_epg_color = '002DD1',   -- no EPG message color
   no_epg_size  = '25',       -- no EPG message font size
}
-------------------------------------------------------------------------------
return config -- do not delete this line
-------------------------------------------------------------------------------

