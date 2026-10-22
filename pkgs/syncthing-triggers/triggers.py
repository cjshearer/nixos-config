#!/usr/bin/env python3
"""Replicate a Syncthing folder from one always-on replica host.

Syncthing has no command hooks, so a folder consumer registers commands here
and this service long-polls the event stream. A command runs only after its
folder has been quiet for a settle period and the local copy is complete:
idle, nothing needed, no pull errors, 100% completion. Each command then runs
at most once per folder sequence, so a reconnect or restart does not re-run it.

Run this on exactly one host per folder. Restricting replication to a single
always-on writer is what makes a bare `rclone sync` safe: a joiner or a host
that is behind never pushes, so it cannot delete remote files its peers have
not shared. A command that fails is retried after the next settle.
"""

import argparse
import json
import os
import re
import subprocess
import sys
import time
import urllib.parse
import urllib.request


def read_api_key(config):
    with open(config) as handle:
        match = re.search(r"<apikey>\s*([^<\s]+)\s*</apikey>", handle.read())
    if not match:
        raise SystemExit(f"no <apikey> in {config}")
    return match.group(1)


def get(base, key, path, timeout=90):
    request = urllib.request.Request(
        f"http://{base}{path}", headers={"X-API-Key": key}
    )
    with urllib.request.urlopen(request, timeout=timeout) as response:
        return json.load(response)


def ready(base, key, folder):
    """Return the folder sequence if the local copy is complete, else None."""
    query = urllib.parse.quote(folder, safe="")
    status = get(base, key, f"/rest/db/status?folder={query}")
    if status.get("state") != "idle":
        return None
    if status.get("needFiles", 0) or status.get("needDeletes", 0):
        return None
    if status.get("pullErrors", 0):
        return None
    completion = get(base, key, f"/rest/db/completion?folder={query}")
    if completion.get("completion", 0) < 100:
        return None
    return status.get("sequence", 0)


def read_cursor(state_dir, name):
    try:
        with open(os.path.join(state_dir, f"{name}.seq")) as handle:
            return int(handle.read().strip())
    except (FileNotFoundError, ValueError):
        return None


def write_cursor(state_dir, name, sequence):
    with open(os.path.join(state_dir, f"{name}.seq"), "w") as handle:
        handle.write(str(sequence))


def run_commands(base, key, folder, triggers, state_dir):
    sequence = ready(base, key, folder)
    if sequence is None:
        return True

    ok = True
    for trigger in triggers:
        name = trigger["name"]
        if read_cursor(state_dir, name) == sequence:
            continue
        print(
            f"run {name}: folder {folder} at sequence {sequence}",
            file=sys.stderr,
            flush=True,
        )
        if subprocess.call(trigger["command"], shell=True) == 0:
            write_cursor(state_dir, name, sequence)
        else:
            print(f"{name}: failed; will retry", file=sys.stderr, flush=True)
            ok = False
    return ok


def latest_event_id(base, key):
    events = get(base, key, "/rest/events?since=0&limit=1")
    return events[-1]["id"] if events else 0


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--config", required=True)
    parser.add_argument("--gui", required=True)
    parser.add_argument("--triggers", required=True)
    parser.add_argument("--state-dir", required=True)
    parser.add_argument("--settle", type=float, default=15.0)
    parser.add_argument("--recheck", type=float, default=300.0)
    args = parser.parse_args()

    key = read_api_key(args.config)
    with open(args.triggers) as handle:
        triggers = json.load(handle)
    by_folder = {}
    for trigger in triggers:
        by_folder.setdefault(trigger["folder"], []).append(trigger)
    os.makedirs(args.state_dir, exist_ok=True)

    since = latest_event_id(args.gui, key)
    now = time.monotonic()
    deadlines = {folder: now + args.settle for folder in by_folder}
    recheck = now + args.recheck

    while True:
        now = time.monotonic()
        due = [folder for folder, deadline in deadlines.items() if deadline <= now]
        if due:
            for folder in due:
                del deadlines[folder]
                try:
                    done = run_commands(
                        args.gui, key, folder, by_folder[folder], args.state_dir
                    )
                except Exception as error:
                    print(f"{folder}: {error}; will retry", file=sys.stderr, flush=True)
                    done = False
                if not done:
                    deadlines[folder] = time.monotonic() + args.settle
            continue

        if now >= recheck:
            for folder in by_folder:
                deadlines.setdefault(folder, now + args.settle)
            recheck = now + args.recheck
            continue

        horizon = min([*deadlines.values(), recheck])
        timeout = max(1, min(60, int(horizon - now) or 1))
        try:
            events = get(
                args.gui,
                key,
                f"/rest/events?since={since}&timeout={timeout}"
                "&events=StateChanged,FolderCompletion",
                timeout=timeout + 15,
            )
        except Exception as error:
            print(f"events: {error}; retrying", file=sys.stderr, flush=True)
            time.sleep(5)
            continue
        for event in events:
            since = max(since, event["id"])
            folder = (event.get("data") or {}).get("folder")
            if folder in by_folder:
                deadlines[folder] = time.monotonic() + args.settle


if __name__ == "__main__":
    main()
