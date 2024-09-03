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
local prev_playlist = nil -- saved previos path for back if curr check failed
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
    };
}
-------------------------------------------------------------------------------
-- Detect Language
-------------------------------------------------------------------------------
local msg_text = translates[os.getenv('LANG')] or translates['en_US.UTF-8']
-------------------------------------------------------------------------------
local home_dir = os.getenv('HOME')
if not home_dir then
   mp.set_osd_ass(0, 0, "EPGTV Error: No have 'HOME' envilopment variable");
   io.write("EPGTV Error: No have 'HOME' envilopment variable","\n");
   return
end
local cache_dir = home_dir..'/.cache/EPGTV'
-------------------------------------------------------------------------------
local config = {
        curlPath  = '/usr/bin/curl',
        zcatPath  = '/usr/bin/zcat',
        epgTmpDir =  cache_dir,-- epg data cache location for user
       titleColor = '00FBFE',  -- now playing title color
       clockColor = '00FBFE',  -- clock color
    upcomingColor = 'FFFFFF',  -- upcoming list color
    noEpgMsgColor = '002DD1',  -- no EPG message color

        titleSize = '50', -- now playing title font size
     progressSize = '40', -- percentual progress font size
 upcomingTimeSize = '25', -- upcoming broadcast time font size
upcomingTitleSize = '35', -- upcoming broadcast title font size

         duration = 5, -- hide EPG after this time, defined in seconds
    cacheFileHead = 'EPGTV-CACHE'
}
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
-- Show progress bar and actual system time
-------------------------------------------------------------------------------
local function progressBar(percent)
  ass = assdraw.ass_new()
  local w, h = mp.get_osd_size()
  local p = ((w-14)/100)*percent
  if w and w > 0 and h and h > 0 then
    ass:new_event() --------------- darkness background
    ass:pos(0, 0) ----------------- darkness background pose
    ass:append('{\\bord2}') ------- border size
    ass:append('{\\shad0}') ------- shadow
    ass:append('{\\1a&40&}') ------ alpha
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
    ass:append('{\\1c&00FBFE&}') -- background color
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
    ass:round_rect_cw(0, 0, 121, 48, 2)
    ass:draw_stop()----------------

    ass:new_event() --------------- clock
    ass:pos(w-128, 20) ------------
    ass:append('{\\bord2}') ------- border size
    ass:append('{\\shad0}') ------- shadow
    ass:append('{\\fs50\\b1}') ---- font-size
    ass:append('{\\1c&00FBFE&}') -- background color
    ass:append('{\\3c&000000&}') -- border color
    ass:append(os.date('%H:%M')) --
  end
end
-------------------------------------------------------------------------------
-- Force create directory for cache
-- If Failed exit from script
-------------------------------------------------------------------------------
local stat = utils.subprocess({
      cancellable    = false,
      capture_stdout = false,
      args = {'/usr/bin/mkdir','-p',config.epgTmpDir }
})
if stat.status ~= 0 then
   message(msg_text.failed_create_dir..' '..config.epgTmpDir)
   return
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
             config.curlPath,
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
             config.curlPath,
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
             config.curlPath,
             '-L',
             '-s',
             '-r',
             range_start..'-'..range_final,
             source_url
         }
      else
         args =
         {
             config.curlPath,
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
-- Stupid check, current file in mpv opened is playlist file
-- no use playlist-path and not use playlist properties becouse
-- if mpv give URL source without extension we dont know
-- this input data is m3u or not, this is strange but, well okey...
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
      if data:find('#EXTINF') or data:find('#EXTM3U') then
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
          args = { config.zcatPath, source_file }
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
   return ihas_epg_ids or ihas_url_ids --FIXME: refra
end
-------------------------------------------------------------------------------
-- Try find url-tvg links in M3U playlist
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
       end
   end
   return ihas_epg_url
end
-------------------------------------------------------------------------------
-- Convert EPG source url or path to simple string and build path to cache dir
-------------------------------------------------------------------------------
local function url_to_path(url)
     return config.epgTmpDir..'/'..url:gsub('[/%.:]+','')
end
-------------------------------------------------------------------------------
-- Check have cache file for url-tvg link from current M3U playlist
-------------------------------------------------------------------------------
local function check_epg_cache(url)
      if not url then
         return false
      end
      local filename = url_to_path(url)
      local filehndl = io.open(filename)
      if filehndl then
         local head = filehndl:read(#config.cacheFileHead)
         if head == config.cacheFileHead then
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
      filehndl:write(config.cacheFileHead..'='..source_url,'\n')
      local fmts = '%s "%s" %s %s "%s" "%s"\n'
      for name,val in pairs(source_table) do
          for _,x in ipairs(val) do
              filehndl:write(fmts:format(name,x.name,x.start,x.stop,
                                                    x.title,x.desc))
          end
      end
      filehndl:flush()
      filehndl:close()
      return true
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
-- Give EPG programms data from prepared cache file
-------------------------------------------------------------------------------
local function load_epg_cache_from_file(source_file)
     if not source_file then
        return nil
     end
     local data = nil
     local fmts = '(.-)%s"(.-)"%s(.-)%s(.-)%s"(.-)"%s"(.-)"$'
     for line in io.lines(source_file) do
         local channel,name,start,stop,title,desc = line:match(fmts)
         if channel and name and start and stop and title and desc then
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
           local filename = url_to_path(url)
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
             message(msg_text.load_tv_cache..' '..filename)
             local tab = load_epg_cache_from_file(filename)
             if tab then
                list_epg_tab[filename] = tab
             else
                message(msg_text.failed_get_data_from..' '..filename)
             end
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
-- Time Zone shift
-------------------------------------------------------------------------------



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
  local yesterday = os.date('%Y%m%d',os.time()-24*60*60)
  local tomorrow  = os.date('%Y%m%d',os.time()+24*60*60)
  for _,n in ipairs(el[channel]) do
      local progdate = string.sub(n.start, 1, 8)
      if progdate == today_short or
         progdate == yesterday   or
         progdate == tomorrow then
         local progstart = string.sub(n.start, 1, 12)
         local progstop  = string.sub(n.stop, 1, 12)
         local start = formatTime(n.start)
         local stop  = formatTime(n.stop)
        if progstart<=today_long and progstop>=today_long then
           local progress = calculatePercentage(progstart,progstop,today_long)
           local fmts = '{\\b1\\bord2\\fs%s\\1c&H%s}%s {\\fs%s}(%s%%)\\N'
           -- set current channel programme
           now.title = fmts:format(config.titleSize,
                                   config.titleColor,n.title,
                                   config.progressSize,progress)
           -- show progress bar
           progressBar(progress)
           -- inject programm description beetwen title and upcoming programms
           now.title = now.title ..
          '{\\a5\\q0\\bord2\\fs25\\b1\\1c&54E5B2&\\3c&000000&}'..n.desc..'\\N'
        elseif progstart > today_long  then
           local fmts = '{\\b1\\be\\fs%s\\1c&H%s&}⦗%s – %s⦘{\\b0\\fs%s} %s'..
                        ' \n {\\1c&Hc9dbe0&\\b0\\bord0\\fs17\\q3} %s\\N'
           -- set upcoming channel programmes
           local  prog = fmts:format(config.upcomingTimeSize,
                                     config.upcomingColor,start,stop,
                                     config.upcomingTitleSize,
                                     n.title,n.desc:gsub('\n',''))

           if progdate == tomorrow then
              program_next_day[#program_next_day+1] =
              '{\\b1\\be\\fs25\\1c&H3643cf&}'..msg_text.tomorrow..' '..prog
           else
              program[#program+1] = prog
           end

        end
     end
  end
  table.sort(program)
  table.insert(program,1,now.title)
  for _,prog in ipairs(program_next_day) do
  table.insert(program,prog)
  end
  if #program == 0 then
     return nil
  end
  return program
end
-------------------------------------------------------------------------------
-- Scroll TV programs to down
-------------------------------------------------------------------------------
local current_program_list
local function next_programms()
    if not current_program_list then
       return
    end
    if timer then
       timer:kill()
       timer = nil
    end
    table.remove(current_program_list,1)
    ov.data = table.concat(current_program_list)
    ov:update()
    local w, h = mp.get_osd_size()
    mp.set_osd_ass(w, h, ass.text)
end
-------------------------------------------------------------------------------
-- After prepare M3U and EPG data we try find 'tvg-id' from 'media-title'
-- if found, we try find TV programms in EPG data, if found, prepare and show
-------------------------------------------------------------------------------
local function show_epg()
  if not new_file_is_m3u() then
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
  if not channelID or not data then
     local fmts = '{\\an8\\fs50\\b1\\1c&H%s}%s'
     ov.data = fmts:format(config.noEpgMsgColor,msg_text.no_have_tv_program)
     ass.text = ''
     current_program_list = nil
  else
     ov.data = table.concat(data)
     current_program_list = data
  end
  ov:update()
  local w, h = mp.get_osd_size()
  mp.set_osd_ass(w, h, ass.text)
  timer = mp.add_timeout(config.duration, function()
      ov:remove();
      mp.set_osd_ass(0, 0, '');
  end)
end

-------------------------------------------------------------------------------
-- Get m3u data, find channels tvg-id and url-tvg EPG link, download EPG and
-- save to cache, if EPG is `gz` archive unpack, XML data once parsing and
-- save as plain text to cache, if cache data found, load cache data
-------------------------------------------------------------------------------
local tmp_list = config.epgTmpDir..'/lastlist.m3u'
local function load_epg()
    local path = mp.get_property('path')
    local playlist = mp.get_property('playlist-path')
    if not playlist then
       playlist = path
       prev_playlist = curr_playlist
       curr_playlist = path
       if not new_file_is_m3u() then
          curr_playlist = prev_playlist
          return
       end
       if playlist:sub(1,4) == 'http' then
          download_to_file(playlist,tmp_list)
          mp.commandv('loadfile',tmp_list)
       else
          local data = download_to_data(playlist)
          local filehndl = io.open(tmp_list,'w')
          if not data or not filehndl then
             curr_playlist = prev_playlist
             return
          end
          filehndl:write(data)
          filehndl:flush()
          filehndl:close()
          mp.commandv('loadfile',tmp_list)
       end
    end

    if playlist == curr_playlist and playlist ~= tmp_list then
       return
    end

    if not curr_playlist then
       curr_playlist = playlist
       prev_playlist = curr_playlist
    else
       prev_playlist = curr_playlist
       curr_playlist = playlist
    end
    if new_file_is_m3u() then
       --clear_epgtv_state() -- reset all tv information
       if get_epg_ids_from_m3u() then
          if get_epg_url_from_m3u() then
             get_epg_data()
          else
             curr_playlist = prev_playlist
          end
       else
          curr_playlist = prev_playlist
       end
    else
       curr_playlist = prev_playlist
    end
    show_epg()
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
    show_epg()
end
-------------------------------------------------------------------------------
-- For find channels use all EPG data from all cached sources
-------------------------------------------------------------------------------
local function load_all_epg_cache()
    local filelist = utils.readdir(config.epgTmpDir,'files')
    if filelist and #filelist > 0 then
       for _,file in pairs(filelist) do
           local fullpath = config.epgTmpDir..'/'..file
           if not list_epg_tab[fullpath] then
              message(msg_text.load_tv_cache..' '..fullpath)
              local tab = load_epg_cache_from_file(fullpath)
              if tab then
                 list_epg_tab[fullpath] = tab
              else
                message(msg_text.skip..' '..fullpath)
              end
           else
               message(msg_text.cache_allready_loaded)
           end
       end
    else
        message(msg_text.no_have_cache)
    end
    show_epg()
end
-------------------------------------------------------------------------------
-- Set key bindings and events handlers
-------------------------------------------------------------------------------
mp.add_key_binding('esc',function()
    if timer then
       timer:kill()
       timer = nil
    end
    ov:remove();
    mp.set_osd_ass(0, 0, '');
end)
-------------------------------------------------------------------------------
mp.add_key_binding('h', show_epg)
mp.add_key_binding('n', next_programms)
mp.add_key_binding('g', load_all_epg_cache)
mp.add_key_binding('u', update_current_epg)
mp.register_event('file-loaded', load_epg)
mp.register_event('file-loaded', show_epg)
-------------------------------------------------------------------------------
mp.register_event('start-file',function()
    if timer then
       timer:kill()
       timer = nil
    end
    ov:remove();
    mp.set_osd_ass(0, 0, '');
end)
-------------------------------------------------------------------------------
