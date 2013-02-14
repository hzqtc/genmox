#!/usr/bin/env python

import jinja2
import json
import mpd
import os
import socket

def timestamp(seconds):
    return "%d:%02d" % (seconds / 60, seconds % 60)

def getFMDPlaying():
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    try:
        s.connect(("localhost", 10098))
    except socket.error:
        s.close()
        s = None

    (status, artist, title, album, year, pos, length) = ('', '', '', '', '', '0', '0')
    if s:
        s.send("info")
        response = s.recv(4096)
        s.close()
        jsonObj = json.loads(response)

        status = jsonObj["status"]
        if status != "stop":
            artist = jsonObj["artist"]
            title = jsonObj["title"]
            album = jsonObj["album"]
            year = jsonObj["year"]
            pos = jsonObj["pos"]
            length = jsonObj["len"]
    else:
        status = "error"
    return (status, artist, title, album, year, pos, length)

def getMPDPlaying():
    client = mpd.MPDClient()
    try:
        client.connect('localhost', 6600)
    except socket.error:
        client = None

    (status, artist, title, album, year, pos, length) = ('', '', '', '', '', '0', '0')
    if client:
        dictCurrent = client.currentsong()
        dictStatus = client.status()
        client.close()

        status = dictStatus["state"]
        if status != "stop":
            artist = dictCurrent["artist"]
            title = dictCurrent["title"]
            album = dictCurrent["album"]
            year = dictCurrent["date"]
            (pos, length) = dictStatus["time"].split(":")
    else:
        status = "error"
    return (status, artist, title, album, year, pos, length)

(status, artist, title, album, year, pos, length) = getFMDPlaying()
if status != "error":
    server = "fmd"
    tooltip = "FMD"
else:
    (status, artist, title, album, year, pos, length) = getMPDPlaying()
    if status != "error":
        server = "mpd"
        tooltip = "MPD"
    else:
        server = "error"
        tooltip = "Error"

scriptDir = os.path.dirname(os.path.abspath(__file__))
env = jinja2.Environment(loader = jinja2.FileSystemLoader(scriptDir))
template = env.get_template("template.json")
print template.render(
        status = status,
        server = server,
        image = os.path.join(scriptDir, "%s.png" % status),
        altimage = os.path.join(scriptDir, "%s_neg.png" % status),
        text = "",
        tooltip = tooltip,
        info1 = "%s %s: %s / %s" % (server.upper(), "Playing" if status == "play" else "Paused", timestamp(int(pos)), timestamp(int(length))),
        info2 = "%s - %s" % (artist, title),
        info3 = "%s (%s)" % (album, year)).encode("utf-8")
