# GenMoX

GenMoX is a general monitor for MAC OS X. The Mac menubar is a perfect location
to place widgets such as "weather info" and "now playing". There are lots of
special apps for menubar to monitor a specified kind of infomation. Here, I
present you a more generic and powerful widget: GenMoX.

## How it works

When a GenMoX instance is started, it's told to execute a program every few
seconds. Both program and interval are configurable through command line
arguments. For example:

```bash
genmox 1800 "weather-monitor-helper.py shanghai"
```

The first argument is monitor interval in seconds. The second argument is the
program to be monitored. So this launch string means: run
`weather-monitor-helper.py shanghai` every half an hour (1800 seconds).

**Notice:
the program to be monitored should be put in quotes together with its
arguments.**

The program to be monitored can be written in any language as long as its output
is a JSON string in the following format:

```javascript
{
    "image": "/path/to/normal/image.png",
    "altimage": "/path/to/alternate/image/when/highlighted.png",
    "menus": [
        {
            "click": "",    // empty click command causes menu item disabled
            "text": "Disabled Menu Text",
            "keyboard": "",
        },
        {
            "click": "",
            "text": "",     // empty item will be ignored
            "keyboard": "",
        },
        {
            "click": "",
            "text": "-",    // this will make a menu separator
            "keyboard": "",
        },
        {
            "click": "/bin/sleep 5",
            "text": "Sleep",
            "keyboard": "s",    // shortcut key will be "⌘-S"
        }
    ],
    "text": "Status Text",
    "tooltip": "Status Tooltip"
}
```

The `image`, `altimage`, `tooltip` and `menus` fields can be omitted. For more
examples, refer to `monitors` directory in the source tree.

GenMoX is fully-customizable through any programming language. It's perfectly
fine and can be quite useful if you just prepare a static JSON file and run
GenMoX with:

```bash
genmox 100000 "cat static.json"
```

## Screenshots

To this end, three monitor scripts have been developed.

### Now Playing Monitor

Display now playing infomation of [Music Player Daemon](http://musicpd.org/)
and provide basic controlls.

```bash
genmox 1 $(pwd)/mpd-monitor.sh
```

![](https://raw.github.com/hzqtc/genmox/master/screenshots/nowplaying-monitor.png)

Copy the [plist file](https://raw.github.com/hzqtc/genmox/master/monitors/nowplaying/hzqtc.nowplaying.plist)
to `~/Library/LaunchAgents/` to run this monitor on login.

### System Infomation Monitor

Display current CPU and memory usage infomation.

```bash
genmox 3 $(pwd)/sysinfo.sh
```

![](https://raw.github.com/hzqtc/genmox/master/screenshots/sysinfo-monitor.png)

### World clock

Show the current time in other timezones.

```bash
genmox 30 $(pwd)/world-clock.sh Asia/Shanghai America/New_York Europe/Zurich
```

![](https://raw.github.com/hzqtc/genmox/master/screenshots/world-clock.png)

Copy the [plist file](https://raw.github.com/hzqtc/genmox/master/monitors/world-clock/hzqtc.worldclock.plist)
to `~/Library/LaunchAgents/` to run this monitor on login.

## Contribute

Patches and monitor scripts are welcomed.
