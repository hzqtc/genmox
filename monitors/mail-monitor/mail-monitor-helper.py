#!/usr/bin/env python

from jinja2 import Environment, Template, FileSystemLoader
import os
import base64
import imaplib

client = imaplib.IMAP4_SSL("imap.gmail.com")
account = base64.b64decode(open(os.path.expanduser("~/.gmail_account")).read()).split('\n')
client.login(account[0], account[1])
client.select("INBOX")
text = len(client.search(None, "UnSeen")[1][0].split())
client.close()
client.logout()

scriptDir = os.path.dirname(os.path.abspath(__file__))
env = Environment(loader = FileSystemLoader(scriptDir))
template = env.get_template("template.json")
print template.render(
        image = os.path.join(scriptDir, "mail.png"),
        altimage = os.path.join(scriptDir, "mail_neg.png"),
        text = text).encode("utf-8")
