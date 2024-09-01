# EPGTV - TV program viewer for mpv player (Work In Progress)

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

