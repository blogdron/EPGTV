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

## Screenshot

![screenshot](.screenshot/screenshot.png)


## Dependency

 * `mpv`  This script work inside `mpv` player
 * `curl` Need for download `EPG` data
 * `gzip` Need for `zcat` utilite for unpack `zip/gzip` archives

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

`mpv iptv.m3u` or `mpv https://example.com/iptv.m3u`

 * `h` -  Show TV information
 * `n` -  Scroll down of TV information for today and tomorrow
 * `u` -  Upgrade EPG TV data for current playlist (other cache unloaded)
 * `g` -  Preload all EPG TV cache for find TV programs (can be usefull)
 * `esc` - Close TV information

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
