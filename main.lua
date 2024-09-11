-------------------------------------------------------------------------------
--                        EPGTV - Fork of mpvEPG v0.3                        --
--        Lua script for mpv parses XMLTV data and displays scheduling       --
--         information for current and upcoming broadcast programming.       --
--                                                                           --
--            Dependency: SLAXML (https://github.com/Phrogz/SLAXML)          --
--                                                                           --
--               Copyright © 2020 Peter Žember; MIT Licensed                 --
--             See https://github.com/dafyk/mpvEPG for details.              --
--                                                                           --
--               Copyright © 2020 Peter Žember; MIT Licensed                 --
--               Copyright © 2024 Fedor Elizarov; MIT Licensed               --
--             See https://github.com/blogdron/EPGTV for details.            --
-------------------------------------------------------------------------------
--   libASS subtitle format see: https://aegisub.org/docs/latest/ass_tags/   --
-------------------------------------------------------------------------------
local config =
{
   -- key binding -------------------------------------------------------------
   key_update_epg     = 'u',  -- manual upgrade EPG for current playlist
   key_preload_epg    = 'g',  -- manual load all tv cache and try find channel
   key_show_program   = 'h',  -- general show tv program information
   key_scroll_program = 'n',  -- scroll down current tv channel information
   key_close_program  = 'esc',-- manual close tv information
   -- auto show ---------------------------------------------------------------
   auto_show_program  = true, -- show tv program if tv channel changed in mpv
   auto_show_mode     = 2,    -- mode 1 == manual detail, mode 2 == full detail
   auto_show_details  = 2,    -- number programs if auto_show_mode == 1
   -- auto close --------------------------------------------------------------
   auto_close_program = true, -- autoclose tv program (key_scroll ignored it)
   auto_close_duration= 5,    -- sec to close tv program (key_scroll ignored it)
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
   zcat_path   = '/usr/bin/zcat', -- set fullpath to you zcat installation
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
   upcoming_color       = 'FFFFFF',  -- upcoming list color
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
   background_opacity = '40', -- allow 20,40,60,80,100 percents opacity
   --------------------------
   --  message no tv info  --
   --------------------------
   no_epg_color = '002DD1',   -- no EPG message color
   no_epg_size  = '25',       -- no EPG message font size
}
-------------------------------------------------------------------------------
config.cache_file_head = 'EPGTV-CACHE'
-------------------------------------------------------------------------------
local translates =
{
    ['en_US.UTF-8'] =
    {
       no_desctiption    = 'No description';
       failed_create_dir = 'Failed create template directory';
       found_channel     = 'Found TV channel';
       found_stream      = 'Found stream';
       found_epg_source  = 'Found TV program source';
       found_cache       = 'Found cache';
       skip_download     = 'Skip download';
       unpack_tv_program = 'Unpack TV program';
       parse_tv_program  = 'Parse TV program';
       save_tv_to_cache  = 'Save TV program cache';
       load_tv_cache     = 'Load TV cache';
       tomorrow          = 'Tomorrow';
       skip              = 'Skip';
       download_tv_program = 'Download TV program';
       failed_get_data_from = 'Failed get data from';
       cache_allready_loaded = 'Cache allready loaded';
       no_have_cache     = 'No have cache for preload';
       no_have_tv_program= 'No have TV program for this channel';
       no_have_variable_linux   = "No have 'HOME' envilopment variable (Linux)";
       no_have_variable_windows = "No have 'LOCALAPPDATA' envilopment variable (Windows)";

    };
    ['ru_RU.UTF-8'] =
    {
       no_desctiption    = 'Нет описания';
       failed_create_dir = 'Не удалось создать каталог';
       found_channel     = 'Найден ТВ канал';
       found_stream      = 'Найден поток';
       found_epg_source  = 'Найден источник ТВ программ';
       found_cache       = 'Найден кэш';
       skip_download     = 'Пропуск загрузки';
       unpack_tv_program = 'Распаковка ТВ программ';
       parse_tv_program  = 'Разбор ТВ программ';
       save_tv_to_cache  = 'Сохранение ТВ программ в кэш';
       load_tv_cache     = 'Загрузка кэша ТВ программ';
       tomorrow          = 'Завтра';
       skip              = 'Пропуск';
       download_tv_program = 'Загрузка ТВ программ';
       failed_get_data_from = 'Не удалось получить данные из';
       cache_allready_loaded = 'Кэш уже загружен';
       no_have_cache     = 'Нет кэша для подгрузки';
       no_have_tv_program= 'Нет ТВ программы для этого канала';
       no_have_variable_linux   = "Нет переменной окружения 'HOME' (Linux)";
       no_have_variable_windows = "Нет переменной окружения 'LOCALAPPDATA' (Windows)";
    };
}
-------------------------------------------------------------------------------
-- Detect Language
-------------------------------------------------------------------------------
local msg_text = translates[os.getenv('LANG')] or translates['en_US.UTF-8']
-------------------------------------------------------------------------------
local os = require 'os'
local io = require 'io'
local mp = require 'mp'
local string  = require 'string'
local utils   = require 'mp.utils'
local assdraw = require 'mp.assdraw'
-------------------------------------------------------------------------------
local ov  = mp.create_osd_overlay('ass-events')
local ass = assdraw.ass_new()
local timer
-------------------------------------------------------------------------------
local curr_playlist = nil -- current path for check, this is IPTV m3u or not
local curr_playlist_time_shift = 0
local curr_program_list  = nil
local curr_program_start = 0
local curr_program_stop  = 0
local program_is_visible = false
-------------------------------------------------------------------------------
local list_epg_ids = {   }
local ihas_epg_ids = false
-------------------------
local list_url_ids = {   }
local ihas_url_ids = false
--------------------------
local list_epg_url = {   }
local ihas_epg_url = false
local list_epg_tab = {   }
-------------------------------------------------------------------------------
local function clear_epgtv_state()
   list_epg_ids = {   }
   ihas_epg_ids = false
   list_epg_url = {   }
   ihas_epg_url = false
   list_epg_tab = {   }
   collectgarbage('collect')
end
-------------------------------------------------------------------------------
-- Load XML parser
-------------------------------------------------------------------------------
local script_directory = mp.get_script_directory()
package.path = package.path ..';'.. script_directory..'/slaxml/?.lua'
local state,SLAXML = pcall(require,'slaxml')
if not state then
   error('Failled load SLAXML module, plese install this depend')
end
-------------------------------------------------------------------------------
-- Show information message in overlay UI and terminal
-------------------------------------------------------------------------------
local function message(msg)
    local w = mp.get_osd_size()
    if w and w > 0  then
       ass.text = ''
       ov:remove();
       mp.set_osd_ass(0, 0, '');
       io.write('EPGTV: ',msg or '???','\n')
       ass:new_event() --------------- progress bar background
       ass:pos(0, 0) -----------------
       ass:append('{\\bord2}') ------- border size
       ass:append('{\\1a&80&}') ------ alpha
       ass:append('{\\1c&000000&}') -- background color
       ass:append('{\\3c&000000&}') -- border color
       ass:append('{\\1a&80&}') ------ alpha
       ass:draw_start() --------------
       ass:round_rect_cw(0, 2,w,25,0)
       ass:draw_stop()----------------

       ass:new_event() --------------- progress bar background
       ass:append('{\\an8}') --------- text align
       ass:append('{\\q0}') ---------- text wrap mode
       ass:append('{\\bord2}') ------- border size
       ass:append('{\\shad0}') ------- shadow
       ass:append('{\\1c&54E5B2&}') -- background color
       ass:append('{\\3c&000000&}') -- border color
       ass:append('{\\fs15\\b1}') ---- font size
       ass:append(msg or '???')
       mp.set_osd_ass(0, 0, ass.text)
       ass.text = ''
    end
end
-------------------------------------------------------------------------------
-- Force create directory for cache
-- If Failed exit from script
-------------------------------------------------------------------------------
local home_linux_dir = os.getenv('HOME')
local home_windows_dir = os.getenv('LOCALAPPDATA')

if not home_linux_dir and not home_windows_dir then
   mp.set_osd_ass(0, 0, msg_text.no_have_variable_linux..'\n'..
                        msg_text.no_have_variable_windows..'\n');
   io.write(msg_text.no_have_variable_linux,'\n',
            msg_text.no_have_variable_windows,'\n');
   return
end

if home_linux_dir then
   config.epg_tmp_dir = home_linux_dir..'/.cache/EPGTV'
   local stat = utils.subprocess({
         cancellable    = false,
         capture_stdout = false,
         args = {'/usr/bin/mkdir','-p',config.epg_tmp_dir }
   })
   if stat.status ~= 0 then
      message(msg_text.failed_create_dir..' '..config.epg_tmp_dir)
      return
   end
elseif home_windows_dir then
   config.epg_tmp_dir = home_windows_dir..'\\EPGTV'
   os.execute('mkdir '..config.epg_tmp_dir)
   local info = utils.file_info(config.epg_tmp_dir)
   if not info.is_dir then
      message(msg_text.failed_create_dir..' '..config.epg_tmp_dir)
      return
   end
end
-------------------------------------------------------------------------------
-- Convert YYYYMMDDHHmm string to unix timestamp
-------------------------------------------------------------------------------
local function unixTimestamp(s)
   local fmt = '(%d%d%d%d)(%d%d)(%d%d)(%d%d)(%d%d)'
   local year,month,day,hour,min=s:match(fmt)
   return os.time({day=day,month=month,year=year,hour=hour,min=min})
end
-------------------------------------------------------------------------------
-- Calculate tv show progress in percents
-------------------------------------------------------------------------------
local function calculatePercentage(start,stop,now)
   start = tonumber(unixTimestamp(start))
   stop = tonumber(unixTimestamp(stop))
   now = tonumber(unixTimestamp(now))
   return string.format('%0.2f', (now-start)/(stop-start)*100)
end
-------------------------------------------------------------------------------
-- Show progress bar and actual system time
-------------------------------------------------------------------------------
local function progressBar()
  ass = assdraw.ass_new()
  if curr_program_start == 0 or
     curr_program_stop  == 0 then
     return 0
  end
  local progstart  = curr_program_start
  local progstop   = curr_program_stop
  local today_long = os.date('%Y%m%d%H%M')
  local percent = calculatePercentage(progstart,progstop,today_long)
  if tonumber(percent) > 100 then
     percent = 100
  end
  local w, h = mp.get_osd_size()
  local p = ((w-14)/100)*percent
  if w and w > 0  then
    ass:new_event() --------------- darkness background
    ass:pos(0, 0) ----------------- darkness background pose
    ass:append('{\\bord2}') ------- border size
    ass:append('{\\shad0}') ------- shadow
    ass:append('{\\1a&'..config.background_opacity..'&}') ------ alpha
    ass:append('{\\1c&000000&}') -- background color
    ass:append('{\\3c&000000&}') -- border color
    ass:draw_start()---------------
    ass:round_rect_cw(0, 0, w, h, 2)
    ass:draw_stop() ---------------

    ass:new_event() --------------- progress bar background
    ass:append('{\\bord2}') ------- border size
    ass:append('{\\1c&000000&}') -- background color
    ass:append('{\\3c&000000&}') -- border color
    ass:append('{\\1a&80&}') ------ alpha
    ass:pos(7, -5) ----------------
    ass:draw_start() --------------
    ass:round_rect_cw(0, 20, w-14, 10,1)
    ass:draw_stop() ---------------

    ass:new_event() --------------- progress bar
    ass:pos(7, -5) ----------------
    ass:append('{\\bord0}') ------- border size
    ass:append('{\\shad0}') ------- shadow
    ass:append('{\\1a&0&}') ------- alpha
    ass:append('{\\1c&'..config.progress_bar_color..'&}') -- background color
    ass:append('{\\3c&000000&}') -- border color
    ass:draw_start() --------------
    ass:rect_cw(1, 19, p, 11) -----
    ass:draw_stop() ---------------

    ass:new_event() --------------- clock background
    ass:pos(w-128, 21) ------------
    ass:append('{\\bord2}') ------- border size
    ass:append('{\\shad0}') ------- shadow
    ass:append('{\\1a&80&}') ------ alpha
    ass:append('{\\1c&000000&}') -- background color
    ass:append('{\\3c&000000&}') -- border color
    ass:draw_start()---------------
    ass:rect_cw(0, 0, 121, 48, 2)
    ass:draw_stop()----------------

    ass:new_event() --------------- clock
    ass:pos(w-117, 20) ------------
    local bold = config.clock_bold and 1 or 0
    ass:append('{\\bord2}') ------- border size
    ass:append('{\\shad0}') ------- shadow
    ass:append('{\\fs50\\b'..bold..'}') ---- font-size
    ass:append('{\\1c&'..config.clock_color..'&}') -- background color
    ass:append('{\\3c&000000&}') -- border color
    ass:append(os.date('%H:%M')) --
  end
  return percent
end
-------------------------------------------------------------------------------
-- Utilite for download data to file
-------------------------------------------------------------------------------
local function download_to_file(source_url,output_file,range_start,range_final)
      local args
      if range_start and range_final then
         assert(range_start <= range_final)
         args =
         {
             config.curl_path,
             '-L',
             '-s',
             '-r',
             range_start..'-'..range_final,
             source_url,
             '-o',
             output_file
         }
      else
         args =
         {
             config.curl_path,
             '-L',
             '-s',
             source_url,
             '-o',
             output_file
         }
      end
      local data = utils.subprocess(
      {
          cancellable    = false,
          capture_stdout = false,
          args = args
      })
      if data.status ~= 0 then
         return false
      end
      return true
end
-------------------------------------------------------------------------------
-- Utilite for load file from filesystem
-------------------------------------------------------------------------------
local function load_file_to_data(source_file,range_start,range_final)
    local filehndl = io.open(source_file)
    if not filehndl then
       return nil
    end
    if range_start and range_final then
       assert(range_start <= range_final)
       if range_start == range_final then
          range_final = range_final + 1
       end
       filehndl:seek('set',range_start)
       local data = filehndl:read(range_final-range_start)
       filehndl:close()
       return data
    end
    local data = filehndl:read('*all')
    filehndl:close()
    return data
end
-------------------------------------------------------------------------------
-- Utilite for download data in memory
-------------------------------------------------------------------------------
local function download_to_data(source_url,range_start,range_final)
      local args
      if range_start and range_final then
         assert(range_start <= range_final)
         args =
         {
             config.curl_path,
             '-L',
             '-s',
             '-r',
             range_start..'-'..range_final,
             source_url
         }
      else
         args =
         {
             config.curl_path,
             '-L',
             '-s',
             source_url
         }
      end
      local data = utils.subprocess(
      {
          capture_stdout = true ,
          capture_size = 1024*1024*1024,
          cancellable = false,
          args = args
      })
      if data.status ~= 0 then
         return nil
      end
      return data.stdout
end
-------------------------------------------------------------------------------
-- Stupid check, current file in mpv opened is playlist m3u file
-------------------------------------------------------------------------------
local function new_file_is_m3u()
   local path = curr_playlist
   if not path then
      return false
   end
   local data
   if path:sub(1,4) == 'http' then
      data = download_to_data(path,0,1024)
   else
      data = load_file_to_data(path,0,1024)
   end
   if not data then

      return false
   end
   if data:find('#EXTINF') and
      data:find('#EXTM3U') and
      data:find('url%-tvg') then
      return true
   end
   return false
end
-------------------------------------------------------------------------------
-- Utilite for extract gz archive in memory
-------------------------------------------------------------------------------
local function extract_file_to_data(source_file)
   if not source_file then
      return nil
   end
   local data = utils.subprocess(
   {
       capture_size   = 1024*1024*1024,
       cancellable    = false,
       capture_stdout = true ,
       args = { config.zcat_path, source_file }
   })
   if data.status ~= 0 then
      return nil
   end
   return data.stdout
end
-------------------------------------------------------------------------------
-- Read current M3U playlist for parse and find tvg-id, url-tvg and titles
-------------------------------------------------------------------------------
local function get_m3u_data()
   if not new_file_is_m3u() then
      return nil
   end
   local playlist = curr_playlist
   if playlist and playlist:sub(1,4) == 'http' then
      return download_to_data(playlist)
   end
   return load_file_to_data(playlist)
end
-------------------------------------------------------------------------------
-- Try find tvg-id aka TV channels identificators in M3U playlist
-------------------------------------------------------------------------------
local function get_epg_ids_from_m3u()
   local m3u_data = get_m3u_data()
   if not m3u_data then
      return
   end
   local curr_name = nil
   for line in m3u_data:gmatch('[^\n]+') do
       if line:find('#EXTINF') then
          local name = line:match('%,(.+)');
          local id   = line:match('tvg%-id="(.-)"')
          if name and id then
             message(msg_text.found_channel..' '..name)
             list_epg_ids[name]=id
             ihas_epg_ids = true
             curr_name = name
          elseif name then
             curr_name = name
          end
       elseif line:find('://') and not line:find(' ') and curr_name then
          message(msg_text.found_stream..' '..curr_name)
          list_url_ids[line]=curr_name
          ihas_url_ids = true
          curr_name = nil
       end
   end
   return ihas_epg_ids or ihas_url_ids
end
-------------------------------------------------------------------------------
-- Try find url-tvg links in M3U playlist
-- Try find tvg-shift time in M3U playlist
-------------------------------------------------------------------------------
local function get_epg_url_from_m3u()
   local m3u_data = get_m3u_data()
   if not m3u_data then
      return
   end
   for line in m3u_data:gmatch('[^\n]+') do
       if line:find('url%-tvg') then
          local epgline = line:match('url%-tvg="(.-)"')
          if epgline then
             for url in epgline:gmatch('[^, ]+') do
                 message(msg_text.found_epg_source..' '..url)
                 list_epg_url[#list_epg_url+1] = url
                 ihas_epg_url = true
             end
          end
          local tvg_shift = tonumber(line:match('tvg%-shift="(.-)"'))
          if tvg_shift then
             curr_playlist_time_shift = tonumber(tvg_shift)
          else
             curr_playlist_time_shift = 0
          end
       end
   end
   return ihas_epg_url
end
-------------------------------------------------------------------------------
-- Convert EPG source url or path to simple string and build path to cache dir
-------------------------------------------------------------------------------
local function url_to_cache_path(url)
    return utils.join_path(config.epg_tmp_dir,url:gsub('[/%.:]+',''))
end
-------------------------------------------------------------------------------
-- Check have cache file for url-tvg link from current M3U playlist
-------------------------------------------------------------------------------
local function check_epg_cache(url)
      if not url then
         return false
      end
      local filename = url_to_cache_path(url)
      local filehndl = io.open(filename)
      if filehndl then
         local head = filehndl:read(#config.cache_file_head)
         if head == config.cache_file_head then
            filehndl:close()
            message(msg_text.found_cache..' '..url..' '..msg_text.skip_download)
            return true
         end
         return false
      end
      return false
end
-------------------------------------------------------------------------------
-- Save table EPG channels data for reuse after
-------------------------------------------------------------------------------
local function save_epg_cache_to_file(source_table,output_file,source_url)
      if not source_url or not output_file or not source_table then
         return false
      end
      local filehndl = io.open(output_file,'w')
      if not filehndl then
         return false
      end
      filehndl:write(config.cache_file_head..'='..source_url,'\n')
      local fmts = '%s "%s" %s %s %s "%s" "%s"\n'
      for name,val in pairs(source_table) do
          for _,x in ipairs(val) do
              filehndl:write(fmts:format(name,x.name,x.start,x.stop,
                                             x.zone,x.title,x.desc))
          end
      end
      filehndl:flush()
      filehndl:close()
      return true
end
-------------------------------------------------------------------------------
-- Extract timezone value
-------------------------------------------------------------------------------
local function get_time_zone(timestring)
   local sign,hour = timestring:match('%d+%s-([+%-])(%d%d)%d%d')
   if not sign then
      return 0
   end
   if not hour then
      return 0
   end
   if sign == '+' then
      return tonumber(hour)
   end
   if sign == '-' then
      return -tonumber(hour)
   end
end
-------------------------------------------------------------------------------
-- Read EPG XML data to table
-------------------------------------------------------------------------------
local function parse_epg_data(data)
   if not data or #data == 0 then
      return { }
   end
   local programme    = {   }
   local channels     = {   }
   local is_programme = false
   local is_title     = false
   local is_desc      = false
   local is_channel   = false
   local is_display_name = false

   local start   = nil
   local stop    = nil
   local channel = nil
   local title   = nil
   local desc    = nil
   local display_name = nil
   local channel_id   = nil
   local parser = SLAXML:parser
   {
     startElement = function(name)
           if name == 'programme' then
              is_programme = true
           end
           if name == 'title' and is_programme then
              is_title = true
           end
           if name == 'desc' and is_programme then
              is_desc = true
           end
           if name == 'channel' then
              is_channel = true
           end
           if name == 'display-name' and is_channel then
              is_display_name = true
           end
     end;
     attribute  = function(name,value)
           if is_programme and name == 'start' then
              start = value
           end
           if is_programme and name == 'stop' then
              stop = value
           end
           if is_programme and name == 'channel' then
              channel = value
           end
           if is_channel and name == 'id' then
              channel_id = value
           end
     end;
     closeElement = function(name)
           if name == 'programme' then
              if start and stop and channel and title then
                 if not desc then
                    desc = msg_text.no_desctiption
                 end
                 if not programme[channel] then
                    programme[channel] = { }
                 end
                    programme[channel][#programme[channel]+1] =
                    {
                       title = title;
                        name = channels[channel] or '#';
                       start = start:match('(%d+)%s-');  -- del timezone
                        stop = stop:match('(%d+)%s-');   -- del timezone
                        desc = desc:gsub('[\n "]+',' '); -- only oneline
                        zone = get_time_zone(start);
                    }
                    title   = nil
                    start   = nil
                    stop    = nil
                    desc    = nil
                    channel = nil
              end
              is_programme = false
           end
           if name == 'channel' then
              io.write(channel_id,' # ',display_name,'\n')
              if channel_id and display_name then
                 channels[channel_id] = display_name
              end
              channel_id   = nil
              display_name = nil
              is_channel = false
           end
           if name == 'display_name' then
              is_display_name = false
           end
           if name == 'title' then
              is_title = false
           end
           if name == 'desc' then
              is_desc = false
           end
     end;
     text  = function(text)
           if is_title and is_programme then
              title = text
           end
           if is_desc and is_programme then
              desc = text
           end
           if is_display_name and is_channel then
              display_name = text
           end
     end;
   }
   if not (pcall(SLAXML.parse,parser,data,{stripWhitespace=true})) then
      return nil
   end
   return programme
end
-------------------------------------------------------------------------------
-- Get EPG programms data from prepared cache file
-------------------------------------------------------------------------------
local function load_epg_cache_from_file(source_file)
     if not source_file then
        return nil
     end
     local data = nil
     local fmts = '(.-)%s"(.-)"%s(.-)%s(.-)%s(%d+)%s"(.-)"%s"(.-)"$'
     for line in io.lines(source_file) do
         local channel,name,start,stop,zone,title,desc = line:match(fmts)
         if channel and name and start and stop and zone and title and desc then
            if not data then
               data = { }
            end
            if not data[channel] then
               data[channel] = { }
            end
            data[channel][#data[channel]+1] =
            {
                title = title;
                start = start;
                name  = name;
                stop  = stop;
                desc  = desc;
                zone  = tonumber(zone);
            }
            if data[channel][#data[channel]].name ~= '#' then
               data[data[channel][#data[channel]].name] = data[channel]
            end
         end
     end
     return data
end
-------------------------------------------------------------------------------
-- Get EPG data from url-tvg M3U link, EPG can be
-- * url  link with plain text XML data
-- * url  link with gz archive with zipped XML data
-- * file path with plain text XML data
-- * file path with gz archive with zipped XML data
-------------------------------------------------------------------------------
-- After give XML data, parse XML and save to cache
-------------------------------------------------------------------------------
local function get_epg_data(force_download)
    if ihas_epg_url then
       for _,url in pairs(list_epg_url) do
           local filename  = url_to_cache_path(url)
           local fileshort = filename:match('.+/(.-)$')
           if not check_epg_cache(url) or force_download then
              message(msg_text.download_tv_program..' '..url)
              local data;
              if url:find('%.gz$') or url:find('%.zip$') then
                 download_to_file(url,filename)
                 message(msg_text.unpack_tv_program)
                 data = extract_file_to_data(filename)
              else
                 data = download_to_data(url)
              end
              if data then
                 message(msg_text.parse_tv_program)
                 local tab = parse_epg_data(data)
                 if not tab then
                    message(msg_text.failed_get_data_from..' '..url)
                    return
                 end
                 list_epg_tab[filename] = tab
                 message(msg_text.save_tv_to_cache)
                 save_epg_cache_to_file(list_epg_tab[filename],filename,url)
              else
                 message(msg_text.failed_get_data_from..' '..url)
              end
           elseif not list_epg_tab[filename] then
             message(msg_text.load_tv_cache..' '..fileshort)
             local tab = load_epg_cache_from_file(filename)
             if tab then
                list_epg_tab[filename] = tab
             else
                message(msg_text.failed_get_data_from..' '..fileshort)
             end
           else
                message(msg_text.cache_allready_loaded)
           end
        end
    end
end
-------------------------------------------------------------------------------
-- Extract hours and minutes from xmltv timestamp and format to HH:MM
-------------------------------------------------------------------------------
local function formatTime(time)
    return string.sub(time, 9, 12):gsub(('.'):rep(2),'%1:'):sub(1,-2)
end
-------------------------------------------------------------------------------
-- Get difference beetwen current time zone and program time zone
-------------------------------------------------------------------------------
local function time_zone_shift(programm_time_zone)
   local local_time_zone = os.difftime(os.time(), os.time(os.date("!*t")))
   local_time_zone = math.floor(local_time_zone / 60 / 60)
   if programm_time_zone > local_time_zone then
      return -(programm_time_zone - local_time_zone)
   end
   if programm_time_zone < local_time_zone then
      return local_time_zone - programm_time_zone
   end
   return 0
end
-------------------------------------------------------------------------------
-- Convert tv program time to local user time
-------------------------------------------------------------------------------
local function translate_time(prog_time,prog_zone)
     return unixTimestamp(prog_time) + (time_zone_shift(prog_zone) * 60 * 60)
end
-------------------------------------------------------------------------------
-- Try find channel in EPG data table,make formated strings for mpv overlay
-------------------------------------------------------------------------------
local function get_tv_programm(el,channel)
  if not el or not el[channel] then
     return
  end
  local program = {}
  local program_next_day = {}
  local now =
  {
      title='',
  }
  local today_long  = os.date('%Y%m%d%H%M')
  local today_short = string.sub(today_long, 1, 8)
  local yesterday   = os.date('%Y%m%d',os.time()-24*60*60)
  local tomorrow    = os.date('%Y%m%d',os.time()+24*60*60)
  local local_zone  = os.difftime(os.time(), os.time(os.date("!*t"))) / 60 / 60
  local tvg_shift   = curr_playlist_time_shift
  for _,n in ipairs(el[channel]) do
      if config.ignore_tvg_shift then
         tvg_shift = 0
      end
      if config.ignore_time_zone then
         n.zone = local_zone
      end
      local tv_zone = n.zone + tvg_shift
      ---------------------------------------------------------------
      local progdate  = os.date("%Y%m%d",translate_time(n.start,tv_zone))
      if progdate == today_short or
         progdate == yesterday   or
         progdate == tomorrow then
         local progstart = os.date("%Y%m%d%H%M",translate_time(n.start,tv_zone))
         local progstop  = os.date("%Y%m%d%H%M",translate_time(n.stop, tv_zone))
         local start = formatTime(progstart)
         local stop  = formatTime(progstop)
        if progstart<=today_long and progstop>=today_long then
           curr_program_start = progstart
           curr_program_stop = progstop
           local progress = calculatePercentage(progstart,progstop,today_long)
           local fmts = '{\\b1\\bord2\\fs%s\\1c&H%s}%s {\\fs%s}(%s%%) (%s - %s)\\N'
           -- set current channel programme
           now.title = fmts:format(config.title_size,
                                   config.title_color,n.title,
                                   config.progress_size,progress,start,stop)
           -- inject programm description beetwen title and upcoming programms
          local fmts_description =
          '%s{\\a5\\q0\\bord2\\fs%s\\b1\\1c&%s&\\3c&000000&} %s\\N'
           now.title = fmts_description:format(now.title,
                                               config.description_size,
                                               config.description_color,n.desc)

        elseif progstart > today_long  then
           local fmts = '{\\b1\\be\\fs%s\\1c&H%s&}⦗%s – %s⦘{\\b0\\fs%s} %s'..
                        ' \n {\\1c&%s&\\b0\\bord0\\fs%s\\q3} %s\\N'
           -- set upcoming channel programmes
           local  prog = fmts:format(config.upcoming_time_size,
                                     config.upcoming_color,start,stop,
                                     config.upcoming_title_size,
                                     n.title,
                                     config.upcoming_description_color,
                                     config.upcoming_description_size,
                                     n.desc:gsub('\n',''))

           if progdate == tomorrow then
              local fmts_tomorrow = '{\\b1\\be\\fs%s\\1c&H%s&}%s %s'
              program_next_day[#program_next_day+1] =
              fmts_tomorrow:format(config.tomorrow_prefix_size,
                                   config.tomorrow_prefix_color,
                                   msg_text.tomorrow,prog)
           else
              program[#program+1] = prog
           end
        end
     end
  end
  table.insert(program,1,"") -- this empty element for correct scroll down
  table.insert(program,2,now.title) -- first empty element, next curr program
  for _,prog in ipairs(program_next_day) do
  table.insert(program,prog)
  end
  if #program == 0 then
     return nil
  end
  return program
end
-------------------------------------------------------------------------------
-- After prepare M3U and EPG data we try find 'tvg-id' from 'media-title'
-- if found, we try find TV programms in EPG data, if found, prepare and show
-------------------------------------------------------------------------------
local function show_epg(mode)
  if not new_file_is_m3u() then
     return
  end
  if not ihas_epg_url and config.ignore_noepg_m3u then
     return
  end
  if timer then
     timer:kill()
     timer = nil
  end
  local data
  local channelID
  -- try find from normal tvg-id channel name
  local channel   = mp.get_property('media-title')
  channelID = list_epg_ids[channel]
  if channelID and list_epg_tab then
     for _,tvdata in pairs(list_epg_tab) do
         data = get_tv_programm(tvdata,channelID)
         if data then
            break
         end
     end
  end
  -- try find from media title, if no have tvg-id
  if not data then
     local stream = mp.get_property('stream-open-filename')
     channelID = list_url_ids[stream]
     if channelID and list_epg_tab then
        for _,tvdata in pairs(list_epg_tab) do
            data = get_tv_programm(tvdata,channelID)
            if data then
               break
            end
        end
    end
  end
  -- try find from stream url slice, if no have other info
  if not data then
     local slice = mp.get_property('stream-open-filename') or ''
     channelID = slice:match('[^/]+$')
     if channelID and list_epg_tab then
        for _,tvdata in pairs(list_epg_tab) do
            data = get_tv_programm(tvdata,channelID)
            if data then
               break
            end
        end
    end
  end

  local mode_manual = 1;
  local mode_auto   = 2;
  if config.auto_show_details <= 0 then
     config.auto_show_details  = 1
  end
  local detail_level = config.auto_show_details + 1

  if not channelID or not data then
     local fmts = '{\\an8\\fs%s\\b1\\1c&H%s&}%s'
     ov.data = fmts:format(config.no_epg_size,
                           config.no_epg_color,
                           msg_text.no_have_tv_program)
     ass.text = ''
     curr_program_list = nil
     program_is_visible = false
  else
     if mode == mode_manual then
        ov.data = table.concat({table.unpack(data,1,detail_level)})
     elseif mode == mode_auto then
        ov.data = table.concat(data)
     else
        ov.data = table.concat(data)
     end
     curr_program_list = data
     progressBar()
     program_is_visible = true
  end
  ov:update()
  local w, h = mp.get_osd_size()
  progressBar()
  mp.set_osd_ass(w, h, ass.text)
  if config.auto_close_program then
     timer = mp.add_timeout(config.auto_close_duration, function()
         ov:remove();
         program_is_visible = false
         mp.set_osd_ass(0, 0, '');
     end)
  end
end
-------------------------------------------------------------------------------
-- Scroll TV programs to down
-------------------------------------------------------------------------------
local function next_programms()
    if not curr_program_list then
       return
    end
    if #curr_program_list == 0 then
       local full_detail = 2
       show_epg(full_detail)
    end
    if timer then
       timer:kill()
       timer = nil
    end
    table.remove(curr_program_list,1)
    ov.data = table.concat(curr_program_list)
    ov:update()
    progressBar()
    local w, h = mp.get_osd_size()
    mp.set_osd_ass(w, h, ass.text)
    program_is_visible = true
end
-------------------------------------------------------------------------------
-- Get m3u data, find channels tvg-id and url-tvg EPG link, download EPG and
-- save to cache, if EPG is `gz` archive unpack, XML data once parsing and
-- save as plain text to cache, if cache data found, load cache data
-------------------------------------------------------------------------------
local function load_epg()
    local playlist = mp.get_property('playlist-path')
    if not playlist then
       return
    end
    if playlist == curr_playlist then
       return
    end
    curr_playlist = playlist
    if new_file_is_m3u() then
       clear_epgtv_state()
       if get_epg_ids_from_m3u() then
          if get_epg_url_from_m3u() then
             get_epg_data()
          end
       end
    end
    local full_detail = 2
    show_epg(full_detail)
end
-------------------------------------------------------------------------------
-- Force update EPG data for current M3U
-------------------------------------------------------------------------------
local function update_current_epg()
   local force_update = true
   if new_file_is_m3u() then
       clear_epgtv_state()
       if get_epg_ids_from_m3u() then
          if get_epg_url_from_m3u() then
             get_epg_data(force_update)
          end
       end
    end
    local full_detail = 2
    show_epg(full_detail)
end
-------------------------------------------------------------------------------
-- For find channels use all EPG data from all cached sources
-------------------------------------------------------------------------------
local function load_all_epg_cache()
    local filelist = utils.readdir(config.epg_tmp_dir,'files')
    if filelist and #filelist > 0 then
       for _,file in pairs(filelist) do
           local fullpath = utils.join_path(config.epg_tmp_dir,file)
           if not list_epg_tab[fullpath] then
              message(msg_text.load_tv_cache..' '..file)
              local tab = load_epg_cache_from_file(fullpath)
              if tab then
                 list_epg_tab[fullpath] = tab
              else
                message(msg_text.skip..' '..file)
              end
           else
               message(msg_text.cache_allready_loaded)
           end
       end
    else
        message(msg_text.no_have_cache)
    end
    local full_detail = 2
    show_epg(full_detail)
end
-------------------------------------------------------------------------------
-- Set key bindings
-------------------------------------------------------------------------------
if config.key_close_program then
   mp.add_key_binding(config.key_close_program,function()
       if timer then
          timer:kill()
          timer = nil
       end
       ov:remove();
       program_is_visible = false
       curr_program_list  = {}
       mp.set_osd_ass(0, 0, '');
   end)
end
---
if config.key_show_program then
   mp.add_key_binding(config.key_show_program,function()
       local full_detail = 2
       show_epg(full_detail)
   end)
end
---
if config.key_close_program then
   mp.add_key_binding(config.key_scroll_program,next_programms)
end
---
if config.key_preload_epg then
   mp.add_key_binding(config.key_preload_epg,load_all_epg_cache)
end
---
if config.key_update_epg then
   mp.add_key_binding(config.key_update_epg,update_current_epg)
end
-------------------------------------------------------------------------------
-- Check all loaded files if is IPTV M3U playlist, load him and handle, if not
-- reset all tv information and ignore, if again IPTV M3U playlist load again
-------------------------------------------------------------------------------
mp.register_event('file-loaded', load_epg)
-------------------------------------------------------------------------------
-- Show or not epg after change channel
-------------------------------------------------------------------------------
if config.auto_show_program then
   mp.register_event('file-loaded',function()
       show_epg(config.auto_show_mode)
   end)
end
-------------------------------------------------------------------------------
-- If selected every source or playlist source hide all visual
-------------------------------------------------------------------------------
mp.register_event('start-file',function()
    if timer then
       timer:kill()
       timer = nil
    end
    program_is_visible = false
    curr_program_list  = {   }
    ov:remove();
    mp.set_osd_ass(0, 0, '');
end)
-------------------------------------------------------------------------------
-- If window size changed resize progress bar and clock, every 1 ses check it
-------------------------------------------------------------------------------
local wx
mp.add_periodic_timer(1,function()
  local ww,hh = mp.get_osd_size()
  if ww ~= wx and program_is_visible  then
     progressBar()
     mp.set_osd_ass(ww, hh, ass.text)
     wx = ww
  end
end)
-------------------------------------------------------------------------------
-- If tv program visible update clock, progress bar and percent value for title
-------------------------------------------------------------------------------
if config.update_visual_progress then
mp.add_periodic_timer(config.update_progress_duration,function()
   if program_is_visible and type(curr_program_stop) == 'string' then
      local today_long = os.date('%Y%m%d%H%M')
      if today_long > curr_program_stop then
         local full_detail = 2
         if timer then
            show_epg(full_detail)
         else
            show_epg(full_detail)
            timer:kill()
            timer = nil
         end
      else
         local w,h = mp.get_osd_size()
         local percent = progressBar()

         local id = 1
         if curr_program_list[1] and #curr_program_list[1] == 0 then
            id = id + 1
         end
         -- if on top current tv title
         -- update percent number value
         -- and refresh program tv list
         if curr_program_list[id] then
            local title,ch =
            curr_program_list[id]:gsub('(%()(.-)(%%)(%))','%1'..percent..'%3%4')
            if ch == 1 then -- only one replace can be
               curr_program_list[id] = title
               ov.data = table.concat(curr_program_list)
               ov:update()
            end
         end
         mp.set_osd_ass(w, h, ass.text)
      end
   end
end)
end
-------------------------------------------------------------------------------
