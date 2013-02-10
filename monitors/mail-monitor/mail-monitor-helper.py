#!/usr/bin/env python

import base64
import datetime
import imaplib
import jinja2
import os

client = imaplib.IMAP4_SSL("imap.gmail.com")
account = base64.b64decode(open(os.path.expanduser("~/.gmail_account")).read()).split('\n')
client.login(account[0], account[1])
client.select("INBOX")
text = len(client.search(None, "UnSeen")[1][0].split())
client.close()
client.logout()
updatetime = "Last update: %s" % (datetime.datetime.now().strftime("%b %d, %H:%M"))

scriptDir = os.path.dirname(os.path.abspath(__file__))
env = jinja2.Environment(loader = jinja2.FileSystemLoader(scriptDir))
template = env.get_template("template.json")
print template.render(
        image = os.path.join(scriptDir, "mail.png"),
        altimage = os.path.join(scriptDir, "mail_neg.png"),
        updatetime = updatetime,
        text = text).encode("utf-8")
