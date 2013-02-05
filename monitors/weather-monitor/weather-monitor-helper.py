#!/usr/bin/env python
# -*- coding: utf-8 -*-

from jinja2 import Environment, Template, FileSystemLoader
import os
import sys
import json
import urllib
import datetime

def getImageName(code):
    image = {
        179: 'snow', 335: 'snow', 311: 'rain', 317: 'hail', 314: 'rain',
        392: 'thunder', 116: 'lightclouds', 113: 'clear', 176: 'rain',
        119: 'clouds', 338: 'snow', 230: 'snow', 395: 'snow', 182: 'hail',
        323: 'snow', 320: 'hail', 326: 'snow', 368: 'snow', 185: 'rain',
        281: 'rain', 365: 'hail', 362: 'hail', 284: 'rain', 308: 'rain',
        200: 'thunder', 143: 'fog', 302: 'rain', 299: 'rain', 305: 'rain',
        263: 'rain', 371: 'snow', 122: 'clouds', 260: 'rain', 266: 'rain',
        386: 'thunder', 227: 'snow', 389: 'thunder', 332: 'snow', 248: 'fog',
        329: 'snow', 293: 'rain', 356: 'rain', 353: 'rain', 359: 'rain',
        350: 'hail', 296: 'rain', 374: 'hail', 377: 'hail'
    }[code];

    hour = datetime.datetime.now().hour
    night = hour <= 6 or hour >= 18
    if night and (image == "clear" or image == "lightclouds"):
        return image + "_night"
    else:
        return image

def prettyDate(uglydate):
    l = map(lambda x: int(x), uglydate.split("-"))
    d = datetime.date(*l)
    return d.strftime("%b %d")

if len(sys.argv) < 2:
    print "Usage: %s [city]" % sys.argv[0]
    print "This script should be used with GenMoX only."
    exit()

city = sys.argv[1]
days = 5
apikey = open(os.path.expanduser("~/.wwo_apikey")).read()

url = "http://free.worldweatheronline.com/feed/weather.ashx?q=%s&format=json&num_of_days=%d&key=%s" % (city, days, apikey)

jsonstr = urllib.urlopen(url).read()
jsonobj = json.loads(jsonstr)

text = "%sºC".decode("utf-8") % jsonobj["data"]["current_condition"][0]["temp_C"]
condition = jsonobj["data"]["current_condition"][0]["weatherDesc"][0]["value"]
location = jsonobj["data"]["request"][0]["query"]
desc = "%s: %s" % (location, condition)
info = "Humidity: %s%%. Wind: %s, %s Km/h." % (
        jsonobj["data"]["current_condition"][0]["humidity"],
        jsonobj["data"]["current_condition"][0]["winddir16Point"],
        jsonobj["data"]["current_condition"][0]["windspeedKmph"])

code = int(jsonobj["data"]["current_condition"][0]["weatherCode"])
imagename = getImageName(code)

forcasts = []
for forcastobj in jsonobj["data"]["weather"]:
    fdate = prettyDate(forcastobj["date"])
    fcond = forcastobj["weatherDesc"][0]["value"]
    ftempmin = forcastobj["tempMinC"]
    ftempmax = forcastobj["tempMaxC"]
    fstr = "%s: %s, %sºC~%sºC".decode("utf-8") % (fdate, fcond, ftempmin, ftempmax)
    forcasts.append(fstr)

scriptDir = os.path.dirname(os.path.abspath(__file__))
env = Environment(loader = FileSystemLoader(scriptDir))
template = env.get_template("template.json")
print template.render(
        image = os.path.join(scriptDir, "%s.png" % imagename),
        altimage = os.path.join(scriptDir, "%s_neg.png" % imagename),
        text = text,
        desc = desc,
        info = info,
        tooltip = desc,
        forcasts = forcasts).encode("utf-8")
