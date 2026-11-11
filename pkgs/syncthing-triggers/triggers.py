"""Run ordered commands when a Syncthing folder is ready."""

import argparse
import json
import os
import re
import subprocess
import sys
import time
import urllib.error
import urllib.parse
import urllib.request

READY_EVENTS = {
    "StateChanged",
    "FolderSummary",
    "FolderCompletion",
    "LocalIndexUpdated",
    "RemoteIndexUpdated",
    "DeviceConnected",
    "DeviceDisconnected",
    "FolderErrors",
}
EVENT_MASK = ",".join(sorted(READY_EVENTS | {"ItemFinished"}))
CONFLICT_MARKER = ".sync-conflict-"
EXIT_NOT_READY = 3
API_ERRORS = (
    urllib.error.URLError,
    TimeoutError,
    OSError,
    json.JSONDecodeError,
    RuntimeError,
)


def read_api_key(config):
    with open(config) as handle:
        match = re.search(r"<apikey>\s*([^<\s]+)\s*</apikey>", handle.read())
    if not match:
        raise RuntimeError(f"no <apikey> in {config}")
    return match.group(1)


def get(base, key, path, timeout=90):
    request = urllib.request.Request(f"http://{base}{path}", headers={"X-API-Key": key})
    with urllib.request.urlopen(request, timeout=timeout) as response:
        return json.load(response)


def ready(base, key, folder):
    query = urllib.parse.quote(folder, safe="")
    try:
        status = get(base, key, f"/rest/db/status?folder={query}")
    except urllib.error.HTTPError as error:
        if error.code == 404:
            return None
        raise

    if status.get("state") != "idle":
        return None
    if status.get("needTotalItems", 0):
        return None
    if status.get("pullErrors", 0):
        return None

    completion = get(base, key, f"/rest/db/completion?folder={query}")
    if completion.get("completion", 0) < 100:
        return None

    return status.get("sequence", 0)


def cursor_path(state_dir, folder, step):
    return os.path.join(state_dir, folder, f"{step}.seq")


def read_cursor(state_dir, folder, step):
    try:
        with open(cursor_path(state_dir, folder, step)) as handle:
            return int(handle.read().strip())
    except (FileNotFoundError, ValueError):
        return None


def write_cursor(state_dir, folder, step, sequence):
    path = cursor_path(state_dir, folder, step)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    temporary = f"{path}.tmp"
    with open(temporary, "w") as handle:
        handle.write(str(sequence))
    os.replace(temporary, path)


def load_pipelines(path):
    with open(path) as handle:
        return json.load(handle)


def run_pipeline(args):
    pipelines = load_pipelines(args.pipelines)
    steps = pipelines.get(args.folder)
    if not steps:
        return 0

    events = set(args.events.split(","))
    try:
        key = read_api_key(args.config)
        sequence = ready(args.gui, key, args.folder)
    except API_ERRORS as error:
        print(f"{args.folder}: {error}; will retry", file=sys.stderr, flush=True)
        return 1

    if sequence is None:
        return EXIT_NOT_READY

    for step in steps:
        if not events.intersection(step["events"]):
            continue
        if read_cursor(args.state_dir, args.folder, step["name"]) == sequence:
            continue
        print(
            f"run {step['name']}: folder {args.folder} at sequence {sequence}",
            file=sys.stderr,
            flush=True,
        )
        if subprocess.call(step["command"], shell=True) != 0:
            print(
                f"{step['name']}: failed; will retry",
                file=sys.stderr,
                flush=True,
            )
            return 1
        write_cursor(args.state_dir, args.folder, step["name"], sequence)
    return 0


def latest_event_id(base, key):
    events = get(base, key, "/rest/events?since=0&limit=1")
    return events[-1]["id"] if events else 0


class FolderState:
    def __init__(self):
        self.events = {"ready"}
        self.running_events = set()
        self.retry_at = 0.0
        self.backoff = 5.0
        self.process = None


def mark_ready(states, folder=None):
    if folder is None:
        for state in states.values():
            state.events.add("ready")
        return
    if folder in states:
        states[folder].events.add("ready")


def dispatch(args):
    pipelines = load_pipelines(args.pipelines)
    if not pipelines:
        return

    states = {folder: FolderState() for folder in pipelines}
    key = None
    since = 0

    while True:
        try:
            if key is None:
                key = read_api_key(args.config)
            since = latest_event_id(args.gui, key)
            break
        except API_ERRORS as error:
            print(f"events: {error}; retrying", file=sys.stderr, flush=True)
            time.sleep(5)

    while True:
        now = time.monotonic()

        for folder, state in states.items():
            if state.process is None:
                continue
            code = state.process.poll()
            if code is None:
                continue
            state.process = None
            if code == 0:
                state.events.difference_update(state.running_events)
                state.running_events.clear()
                state.backoff = 5.0
                state.retry_at = 0.0
            elif code == EXIT_NOT_READY:
                state.running_events.clear()
                state.retry_at = now + 5.0
            else:
                state.running_events.clear()
                state.retry_at = now + state.backoff
                state.backoff = min(state.backoff * 2, 300.0)

        for folder, state in states.items():
            if state.process is not None or not state.events:
                continue
            if now < state.retry_at:
                continue
            state.running_events = set(state.events)
            state.process = subprocess.Popen(
                [
                    sys.executable,
                    os.path.abspath(__file__),
                    "run",
                    "--config",
                    args.config,
                    "--gui",
                    args.gui,
                    "--pipelines",
                    args.pipelines,
                    "--state-dir",
                    args.state_dir,
                    "--folder",
                    folder,
                    "--events",
                    ",".join(sorted(state.events)),
                ]
            )

        deadlines = [
            state.retry_at
            for state in states.values()
            if state.process is None and state.events
        ]
        horizon = min(deadlines) if deadlines else now + 60.0
        timeout = max(1, min(60, int(horizon - now) or 1))

        try:
            events = get(
                args.gui,
                key,
                f"/rest/events?since={since}&timeout={timeout}&events={EVENT_MASK}",
                timeout=timeout + 15,
            )
        except API_ERRORS as error:
            print(f"events: {error}; retrying", file=sys.stderr, flush=True)
            mark_ready(states)
            time.sleep(5)
            continue

        gap = False
        for event in events:
            event_id = event["id"]
            if event_id > since + 1:
                gap = True
            since = max(since, event_id)

            kind = event["type"]
            data = event.get("data") or {}
            folder = data.get("folder")

            if kind == "ItemFinished":
                item = data.get("item") or ""
                if CONFLICT_MARKER in item and folder in states:
                    states[folder].events.add("conflict")
                continue

            if kind in READY_EVENTS:
                if folder in states:
                    states[folder].events.add("ready")
                elif folder is None:
                    mark_ready(states)

        if gap:
            print("event gap; re-evaluating all folders", file=sys.stderr, flush=True)
            mark_ready(states)


def main():
    parser = argparse.ArgumentParser()
    subparsers = parser.add_subparsers(dest="command", required=True)

    run = subparsers.add_parser("run")
    run.add_argument("--config", required=True)
    run.add_argument("--gui", required=True)
    run.add_argument("--pipelines", required=True)
    run.add_argument("--state-dir", required=True)
    run.add_argument("--folder", required=True)
    run.add_argument("--events", required=True)

    dispatch_parser = subparsers.add_parser("dispatch")
    dispatch_parser.add_argument("--config", required=True)
    dispatch_parser.add_argument("--gui", required=True)
    dispatch_parser.add_argument("--pipelines", required=True)
    dispatch_parser.add_argument("--state-dir", required=True)

    args = parser.parse_args()
    if args.command == "run":
        raise SystemExit(run_pipeline(args))
    dispatch(args)


if __name__ == "__main__":
    main()
