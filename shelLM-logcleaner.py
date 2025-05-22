#!/usr/bin/env python3
import re, time, pathlib

SRC     = "/opt/shelLM-kaiser/history.txt"
DST     = "/var/log/shelLM/sessions.log"
OFFSET  = pathlib.Path("/var/log/shelLM/.offset")

pat_cmd  = re.compile(r"^(.*)\t<(?P<ts>\d{4}-\d{2}-\d{2} [^>]+)>$")
pat_login = re.compile(r"Last login: .* from ([0-9.]+)")

current_ip = "-"
pos = int(OFFSET.read_text()) if OFFSET.exists() else 0

with open(SRC, "r", encoding="utf-8") as src, open(DST, "a") as dst:
    src.seek(pos)
    while True:
        line = src.readline()
        if not line:
            time.sleep(0.5)
            continue


        # Capture commands
        m = pat_cmd.match(line.rstrip())
        if m:
            ts  = m.group("ts")
            cmd = line.split("$", 1)[-1].split("\t")[0].strip()
            dst.write(f"{ts} | kaiser | {cmd}\n")
            dst.flush()

        OFFSET.write_text(str(src.tell()))