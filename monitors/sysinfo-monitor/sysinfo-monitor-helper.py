#!/usr/bin/env python

from jinja2 import Environment, Template, FileSystemLoader
import os
import psutil

cpu_percent_list = psutil.cpu_percent(interval = 1, percpu = True)
memory_usage = psutil.virtual_memory()

overall_cpu_percent = reduce(lambda x, y: x + y, cpu_percent_list) / len(cpu_percent_list)
text = "%.1lf%%" % overall_cpu_percent

cpu_ids = range(len(cpu_percent_list))
cpu = "; ".join(map(lambda x: "Core %d: %.1lf%%" % (x[0], x[1]), zip(cpu_ids, cpu_percent_list)))

# only the following figures are correct in psutil.virtual_memory()
mtotal = memory_usage.total / (1 << 20)
mfree = memory_usage.free / (1 << 20)
mactive = memory_usage.active / (1 << 20)
minactive = memory_usage.inactive / (1 << 20)
# other figures are calculated
mavailable = mfree + minactive
mused = mtotal - mfree - minactive
mwired = mused - mactive

memory1 = "Total: %dM; Available: %dM; Used: %dM" % (mtotal, mavailable, mused)
memory2 = "Wired: %dM; Active: %dM; Inactive: %dM; Free: %dM" % (mwired, mactive, minactive, mfree)

scriptDir = os.path.dirname(os.path.abspath(__file__))
env = Environment(loader = FileSystemLoader(scriptDir))
template = env.get_template("template.json")
print template.render(
        image = os.path.join(scriptDir, "icon.png"),
        altimage = os.path.join(scriptDir, "icon_neg.png"),
        text = text,
        cpu = cpu,
        memory1 = memory1,
        memory2 = memory2).encode("utf-8")
