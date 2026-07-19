#!/usr/bin/env python3
"""
Simple scroll runner
--------------------------
Get text from stdin conostantly (ex. "title - artist")
If the text lenght exceed width, then use scroll runner animation every delay second, or else print it directly.

Usage:
    some_source_that_print_lines | scroll.py [width] [delay]

Example:
    ~/.config/eww/scripts/music-feeder.sh | scroll.py 26 0.2

When using in eww, use deflisten to monitor the output of the pipeline:
    (deflisten music-marquee :initial "No music playing" "~/.config/eww/scripts/music_feeder.sh | ~/.config/eww/scripts/scroll.py 26 0.2")
"""

import sys
import time
import threading

# ---------Parameters------------------
width = int(sys.argv[1]) if len(sys.argv) > 1 else 22
delay = float(sys.argv[2]) if len(sys.argv) > 2 else 0.25
SEP = "   •   "  # Seperate symbol

current_text = ""
lock = threading.Lock()

def read_input():
    """
    Background thread: Once stdin has new line, update the current_text
    Use lock to avoid reading the main loop still writing's string
    """
    global current_text
    for line in sys.stdin:
        with lock:
            current_text = line.rstrip("\n")

t = threading.Thread(target=read_input, daemon=True)
t.start()

last_text = None
offset = 0

while True:
    with lock:
        text = current_text

    # If the text change, restart the offset
    if text != last_text:
        offset = 0
        last_text = text

    if not text:
        print("", flush=True)
    elif len(text)<=width:
        print(text, flush=True)
    else:
        loop_text = text + SEP
        end = offset + width
        if end <= len(loop_text):
            frame = loop_text[offset:end]
        else:
            # When exceed the tail, go back from start, to make the loop animation
            frame = loop_text[offset:] + loop_text[: end - len(loop_text)]
        print(frame, flush=True)
        offset = (offset + 1) % len(loop_text)
    time.sleep(delay)

