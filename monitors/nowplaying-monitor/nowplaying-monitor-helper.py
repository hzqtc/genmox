#!/usr/bin/env python

from jinja2 import Environment, Template, FileSystemLoader
import os
import json
import socket
import mpd

def timestamp(seconds):
    return "%d:%02d" % (seconds / 60, seconds % 60)

def getFMDPlaying():
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    try:
        s.connect(("localhost", 10098))
    except socket.error:
        s.close()
        s = None

    if s:
        s.send("info")
        response = s.recv(4096)
        s.close()
        jsonObj = json.loads(response)

        status = jsonObj["status"]
        if status == "stop":
            info1 = ""
            info2 = ""
            info3 = ""
        else:
            info1 = "%s - %s" % (jsonObj["artist"], jsonObj["title"])
            info2 = "%s (%d)" % (jsonObj["album"], jsonObj["year"])
            info3 = "-"
    else:
        status = "error"
        info1 = ""
        info2 = ""
        info3 = ""
    return (status, info1, info2, info3)

def getMPDPlaying():
    client = mpd.MPDClient()
    try:
        client.connect('localhost', 6600)
    except socket.error:
        client = None

    if client:
        dictCurrent = client.currentsong()
        dictStatus = client.status()
        client.close()

        status = dictStatus["state"]
        if status == "stop":
            info1 = ""
            info2 = ""
            info3 = ""
        else:
            (pos, length) = dictStatus["time"].split(":")
            info1 = "%s - %s" % (dictCurrent["artist"], dictCurrent["title"])
            info2 = "%s (%d)" % (dictCurrent["album"], int(dictCurrent["date"]))
            info3 = "-"
    else:
        status = "error"
        info1 = ""
        info2 = ""
        info3 = ""
    return (status, info1, info2, info3)

(status, info1, info2, info3) = getFMDPlaying()
if status != "error":
    server = "Fmd"
else:
    (status, info1, info2, info3) = getMPDPlaying()
    if status != "error":
        server = "Mpd"
    else:
        server = "Error"

scriptDir = os.path.dirname(os.path.abspath(__file__))
env = Environment(loader = FileSystemLoader(scriptDir))
template = env.get_template("template.json")
print template.render(
        server = server,
        image = os.path.join(scriptDir, "%s.png" % status),
        altimage = os.path.join(scriptDir, "%s_neg.png" % status),
        text = server,
        info1 = info1,
        info2 = info2,
        info3 = info3).encode("utf-8")
