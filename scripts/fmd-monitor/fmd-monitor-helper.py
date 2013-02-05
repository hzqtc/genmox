#!/usr/bin/env python

from jinja2 import Environment, Template, FileSystemLoader
import os
import json
import socket

def timestamp(seconds):
    return "%d:%02d" % (seconds / 60, seconds % 60)

scriptDir = os.path.dirname(os.path.abspath(__file__))
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
        text = "Not Playing"
        info1 = ""
        info2 = ""
        info3 = ""
    else:
        text = "%s/%s" % (timestamp(jsonObj["pos"]), timestamp(jsonObj["len"]))
        info1 = "%s - %s" % (jsonObj["artist"], jsonObj["title"])
        info2 = "%s (%d)" % (jsonObj["album"], jsonObj["year"])
        info3 = "-"
else:
    status = "error"
    text = "Contact Fmd Failed"
    info1 = ""
    info2 = ""
    info3 = ""

env = Environment(loader = FileSystemLoader(scriptDir))
template = env.get_template("template.json")
print template.render(
        status = status,
        image = os.path.join(scriptDir, "%s.png" % status),
        altimage = os.path.join(scriptDir, "%s_neg.png" % status),
        text = text,
        info1 = info1,
        info2 = info2,
        info3 = info3).encode("utf-8")
