#!/usr/bin/env python3
"""Choose a cliphist item in rofi, with temporary thumbnails for images."""

import os
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
import subprocess
import sys
import tempfile


def run(args, **kwargs):
    return subprocess.run(args, check=True, **kwargs)


def make_thumbnail(entry, thumbnail):
    try:
        data = run(["cliphist", "decode"], input=entry, stdout=subprocess.PIPE).stdout
        mime = run(
            ["file", "--brief", "--mime-type", "-"], input=data, stdout=subprocess.PIPE
        ).stdout.decode().strip()
        if not mime.startswith("image/"):
            return None
        run(
            ["magick", "-", "-thumbnail", "96x96", str(thumbnail)],
            input=data, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
        )
        return thumbnail
    except (OSError, subprocess.CalledProcessError):
        return None


def main():
    entries = run(["cliphist", "list"], stdout=subprocess.PIPE).stdout.splitlines()
    if not entries:
        return

    runtime = os.environ.get("XDG_RUNTIME_DIR")
    with tempfile.TemporaryDirectory(prefix="cliphist-rofi-", dir=runtime) as directory:
        # Limit work before showing the menu; never persist clipboard images.
        candidates = [
            (index, entry) for index, entry in enumerate(entries)
            if b"[[ binary data" in entry
        ][:40]
        with ThreadPoolExecutor(max_workers=4) as executor:
            pending = {
                index: executor.submit(make_thumbnail, entry, Path(directory) / f"{index}.png")
                for index, entry in candidates
            }
            thumbnails = {index: future.result() for index, future in pending.items()}
        rows = []
        for index, entry in enumerate(entries):
            icon = thumbnails.get(index)
            if not icon:
                icon = Path(__file__).with_name(
                    "clipboard-file.svg" if b"[[ binary data" in entry else "clipboard-text.svg"
                )
            rows.append(entry + b"\0icon\x1f" + os.fsencode(icon))

        menu = subprocess.run(
            ["rofi", "-dmenu", "-i", "-show-icons", "-format", "i",
             "-p", "Clipboard", "-theme",
             str(Path(__file__).with_name("clipboard.rasi"))],
            input=b"\n".join(rows) + b"\n", stdout=subprocess.PIPE, check=False
        )
        if menu.returncode != 0:
            return
        try:
            index = int(menu.stdout.strip())
            if not 0 <= index < len(entries):
                return
        except ValueError:
            return

        data = run(["cliphist", "decode"], input=entries[index], stdout=subprocess.PIPE).stdout
        mime = run(
            ["file", "--brief", "--mime-type", "-"], input=data, stdout=subprocess.PIPE
        ).stdout.decode().strip()
        command = ["wl-copy"]
        if mime.startswith("image/"):
            command += ["--type", mime]
        run(command, input=data)


if __name__ == "__main__":
    try:
        main()
    except (OSError, subprocess.CalledProcessError) as error:
        print(f"Clipboard menu: {error}", file=sys.stderr)
        sys.exit(1)
