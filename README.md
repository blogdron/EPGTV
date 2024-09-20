# EPGTV - TV program viewer for mpv player

```diff
-(Work In Progress) Only Linux or maybe some other *NIX is supported
```

## [README на Русском языке](README.RU.md)

Simple `EPG` information for `IPTV M3U` playlist in [mpv](https://mpv.io).
`EPGTV` is simple extended fork of [mpvEPG v0.3](https://github.com/dafyk/mpvEPG)
`EPGTV` open `M3U` file or `URL` and automatically load/download `EPG` data to cache.
After save cache, show TV program information for twoo days if available.
If available `EPGTV` show TV programs descriptions. First start can be slowly
becouse cache not prepared, other starts faster and reuse cache.

  * Worked on `mpv 0.38.0`

## Alternative

* https://codeberg.org/liya/yuki-iptv

## Screenshot

![screenshot](.screenshot/screenshot.png)


## Dependency

 * `mpv`  This script work inside `mpv` player
 * `curl` Need for download `EPG` data
 * `gzip` Need for unpack `zip/gzip` archives

```
apt install mpv curl gzip
```

## Installing

You need install `EPGTV` **directory** inside `$HOME/.config/mpv/scripts/`

```
git clone https://github.com/blogdron/EPGTV  $HOME/.config/mpv/scripts/EPGTV
```

## Update

```
cd $HOME/.config/mpv/scripts/EPGTV && git pull
```

## Usage
(I recommend use --hwdec, for hardware acceleration)

 * `mpv --hwdec iptv.m3u`
 * `mpv --hwdec https://example.com/iptv.m3u`

## Control

 * `h` -  Show TV information (autoclosed after 5 seconds)
 * `y` -  Show TV information like `h` but in toggle mode show/hide
 * `n` -  Scroll down of TV information for today and tomorrow
 * `u` -  Upgrade EPG TV data for current playlist (other cache unloaded)
 * `g` -  Preload all EPG TV cache for find TV programs (can be usefull)
 * `esc` - Close TV information

`EPGTV` uses a cache for faster operation, it is automatically created
when you first access the playlist, but if after a while you see a message
about the lack of data for the TV channel, then probably the cache is no longer relevant, and
you need to **update the cache manually** by pressing `u` if the `EPG` data source has been updated
then the new cache will be relevant and all data will be displayed, usually `EPG` data stores
information for several days in advance, but this is not always the case.


## Configuration

In the script directory there is a configuration file `conf.lua`, configure everything to your taste

## Notice

EPG TV cache location stored in

```
$HOME/.cache/EPGTV/
```

## Correct IPTV M3U example

```
#EXTM3U url-tvg="http://example.com/epg.xml.gz, https://example.com/epg.xml" tvg-shift="+3"
#EXTINF:-1 tvg-id="channel_id"  group-title="Group name",channel name
http://example.com/tvstream
```

For get and find TV information `M3U` playlist must have

* `url-tvg` tag with link to FILE or URL, with plain XML data or gz/zip archive
* `tvg-id` name for find channel from M3U inside EPG

Some `IPTV M3U` no have `tvg-id` in this case, an alternative search mechanism
is used by name and/or end of the link

------

# Windows

I don't use `Windows`, but here is a description of where and how I managed to
check the script's functionality for the `Windows 7` operating system only once.

## Preparation

* Download `mpv` and unpack `static-mpv.7zip` to `static-mpv`
* https://github.com/eko5624/mpv-win64/releases/tag/2024-04-01
* Download `EPGTV` and unpack to `static-mpv\portable-config\scripts\EPGTV`
* https://github.com/blogdron/EPGTV/archive/refs/heads/master.zip
* Download `curl` and unpack to `C:\Program Files\curl`
* https://curl.se/windows/
* Download `gzip` and unpack to `C:\Program Files\gzip`
* https://sourceforge.net/projects/gnuwin32/files/gzip/1.3.12-1/gzip-1.3.12-1-bin.zip/download
* Open file `static-mpv\portable-config\scripts\EPGTV\conf.lua`
* change values of `curl_path` and `gzip_path` to these

```lua
curl_path = 'C:\\Program Files\\curl\\bin\\curl.exe', -- set fullpath to you curl installation
gzip_path = 'C:\\Program Files\\gzip\\bin\\gzip.exe', -- set fullpath to you gzip installation
```

That's it, it should work now, in fact I described everything here in too much detail.
You only need to unzip the `EPGTV` directory with its contents in the script directory
of your `mpv` player, it can be in different places depending on your
version on `Windows` then you need to install `curl` and `gzip` and set the full paths
to them in the `EPGTV` configuration file and that's it. You can take these dependencies
from other places, and they may be needed in other ways, based on your case.
