#!/usr/bin/env python

from jinja2 import Environment, Template, FileSystemLoader
import os
import json
import socket

def timestamp(seconds):
    return "%d:%02d" % (seconds / 60, seconds % 60)

fmdSock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
fmdSock.connect(("localhost", 10098))
fmdSock.send("info")
response = fmdSock.recv(4096)
jsonObj = json.loads(response)

scriptDir = os.path.dirname(os.path.abspath(__file__))

status = jsonObj["status"]
icon = os.path.join(scriptDir, "%s.png" % status)
if status == "stop":
    text = "Not Playing"
    info1 = ""
    info2 = ""
    info3 = ""
else:
    text = "%s / %s" % (timestamp(jsonObj["pos"]), timestamp(jsonObj["len"]))
    info1 = "%s - %s" % (jsonObj["artist"], jsonObj["title"])
    info2 = "%s (%d)" % (jsonObj["album"], jsonObj["year"])
    info3 = "-"

env = Environment(loader = FileSystemLoader(scriptDir))
template = env.get_template("template.json")
print template.render(icon = icon,
        text = text,
        info1 = info1,
        info2 = info2,
        info3 = info3).encode("utf-8")
