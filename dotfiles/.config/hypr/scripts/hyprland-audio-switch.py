#!/usr/bin/env python3
import subprocess
import re

# --- CONFIGURATION ---
WHITELIST_SINK_NAMES = [
    "USB Audio Speakers",
    "JBL Quantum350 Wireless Analoges Stereo"
]  # Only these sinks will be considered
ENABLE_NOTIFICATIONS = True  # Set to False to disable notifications

# --- 

def notify(message):
    """Send a notification if enabled."""
    if ENABLE_NOTIFICATIONS:
        subprocess.run(["dbus-launch", "notify-send", "-u", "low", "-t", "800", "Audio Switch", message])

def get_sinks():
    """Retrieve available audio sinks filtered by whitelist."""
    output = subprocess.check_output(["wpctl", "status"], encoding="utf-8")

    # Remove ASCII tree characters
    lines = output.replace("├", "").replace("─", "").replace("│", "").replace("└", "").splitlines()

    # Search for "Sinks:"
    sinks_index = next((i for i, line in enumerate(lines) if "Sinks:" in line), None)
    if sinks_index is None:
        return []

    # Extract sinks
    sinks = []
    for line in lines[sinks_index + 1:]:
        if not line.strip():
            break
        sinks.append(line.strip())

    # Parse sinks
    parsed_sinks = []
    for sink in sinks:
        is_default = sink.startswith("*")  # Detect default sink
        sink = sink.lstrip("*").strip()
        
        sink_match = re.match(r"^(\d+)\.\s*([^\[]+)", sink)
        if sink_match:
            sink_id, sink_name = sink_match.groups()
            sink_name = sink_name.strip()
            if sink_name in WHITELIST_SINK_NAMES:
                parsed_sinks.append({"sink_id": int(sink_id), "sink_name": sink_name, "is_default": is_default})
    
    return parsed_sinks

def toggle_sink():
    """Switch to the next audio sink in whitelist."""
    sinks = get_sinks()
    if not sinks:
        notify("No whitelisted sinks found!")
        return

    # Find current default device
    current_index = next((i for i, sink in enumerate(sinks) if sink["is_default"]), -1)
    if current_index == -1:
        current_index = 0  # Default to first if none marked as default

    # Calculate next device in list (cyclic)
    next_index = (current_index + 1) % len(sinks)
    next_sink = sinks[next_index]

    # Set default device
    subprocess.run(["wpctl", "set-default", str(next_sink['sink_id'])])

    # Send notification
    notify(f"Switched to {next_sink['sink_name']}")


# Execute script
toggle_sink()




# MIT License
#  
# Copyright (c) 2024 luminoucid
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
