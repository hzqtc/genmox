#!/usr/bin/env python

from jinja2 import Environment, Template, FileSystemLoader
import os
import psutil

cpu_percent_list = psutil.cpu_percent(interval = 1, percpu = True)
memory_usage = psutil.virtual_memory()

overall_cpu_percent = reduce(lambda x, y: x + y, cpu_percent_list) / len(cpu_percent_list)
overall_memory_percent = memory_usage.percent
text = "CPU: %.1lf%% MEM: %.1lf%%" % (overall_cpu_percent, overall_memory_percent)

cpu_ids = range(len(cpu_percent_list))
cpu = "; ".join(map(lambda x: "Core %d: %.1lf%%" % (x[0], x[1]), zip(cpu_ids, cpu_percent_list)))

memory = "Total: %dM; Available: %dM; Used: %dM; Free: %dM" % (
    memory_usage.total / (1 << 20),
    memory_usage.available / (1 << 20),
    memory_usage.used / (1 << 20),
    memory_usage.free / (1 << 20))

scriptDir = os.path.dirname(os.path.abspath(__file__))
env = Environment(loader = FileSystemLoader(scriptDir))
template = env.get_template("template.json")
print template.render(
        text = text,
        cpu = cpu,
        memory = memory).encode("utf-8")
