#!/usr/bin/env python3
"""
merge_song_servers.py

Merges the four `server{1..4}_content.dart` files (each a full duplicate
song tree pointing at a different Cloudinary account) into a single tree.

Design decisions (change these if your needs differ):
  - server1 is treated as the CANONICAL structure (ids, folder names,
    ordering). Folders/songs that only exist in server2/3/4 but not in
    server1 are skipped (with a warning) -- this matches current app
    behavior, since `loadSongs()` already only ever reads server1's tree.
  - Matching across servers is done by (path, name) -- NOT by `id`,
    because the sample data shows folder `id` fields are unreliable
    (every folder in a branch repeats the deepest leaf's id). Audio leaf
    ids also differ per server (they're per-upload hashes), so id can't
    be used as a join key at all.
  - Each audio leaf keeps server1's `id` (used elsewhere as a stable key,
    e.g. Hive cache keys) and gains a `urls` map: {"server1": "...", ...}
    instead of a single `url` string. Folders keep `url: null` as before.

Usage:
    python3 merge_song_servers.py \
        --server1 server_1_content.dart \
        --server2 server_2_content.dart \
        --server3 server_3_content.dart \
        --server4 server_4_content.dart \
        --out-json merged_songs.json \
        --out-dart merged_song_data.dart
"""

import argparse
import json
import re
import sys

SERVER_NAMES = ["server1", "server2", "server3", "server4"]


def dart_list_literal_to_python(text: str):
    """Turn a Dart `final xxx = [ ... ];` literal into Python data.

    The song data files are JSON-compatible (double-quoted strings,
    lowercase true/false/null) except for two things: line comments at
    the top of the file, and trailing commas before `]`/`}`. Strip both
    and parse as-is.
    """
    # Drop `//` line comments (only appear at file top in these files).
    text = re.sub(r"^\s*//.*$", "", text, flags=re.MULTILINE)

    start = text.index("[")
    end = text.rindex("]") + 1
    body = text[start:end]

    # Remove trailing commas before a closing ] or }
    body = re.sub(r",(\s*[\]}])", r"\1", body)

    try:
        return json.loads(body)
    except json.JSONDecodeError as e:
        sys.stderr.write(f"Failed to parse Dart literal as JSON: {e}\n")
        raise


def load_server_file(path: str):
    with open(path, "r", encoding="utf-8") as f:
        text = f.read()
    return dart_list_literal_to_python(text)


def find_by_name(nodes, name):
    if not nodes:
        return None
    for n in nodes:
        if n.get("name") == name:
            return n
    return None


def merge_nodes(server_node_lists, path, stats):
    """
    server_node_lists: list (len == 4) of `children`-style lists, one per
    server, or None if that server has no corresponding parent node.
    """
    primary = server_node_lists[0]  # server1 is canonical
    if not primary:
        return []

    merged = []
    for node in primary:
        name = node["name"]
        child_path = f"{path}/{name}" if path else name

        matches = [find_by_name(lst, name) for lst in server_node_lists]

        if node.get("isAudio"):
            urls = {}
            for sname, m in zip(SERVER_NAMES, matches):
                if m and m.get("url"):
                    urls[sname] = m["url"]

            if not urls:
                stats["audio_no_urls"] += 1
            stats["audio_total"] += 1
            stats["url_count_hist"][len(urls)] = (
                stats["url_count_hist"].get(len(urls), 0) + 1
            )

            merged.append(
                {
                    "id": node["id"],
                    "name": name,
                    "url": None,
                    "urls": urls,
                    "isAudio": True,
                    "listHere": node.get("listHere", False),
                    "children": [],
                    "isDownloaded": False,
                    "audioLocalPath": None,
                    "imageLocalPath": None,
                }
            )
        else:
            child_lists = [
                (m.get("children") if m else None) for m in matches
            ]
            merged_children = merge_nodes(child_lists, child_path, stats)
            merged.append(
                {
                    "id": node["id"],
                    "name": name,
                    "url": None,
                    "isAudio": False,
                    "listHere": node.get("listHere", True),
                    "children": merged_children,
                    "isDownloaded": False,
                    "audioLocalPath": None,
                    "imageLocalPath": None,
                }
            )

        # Warn about songs present in other servers but missing from
        # server1 (these get silently dropped since server1 is canonical).
        for sname, lst in zip(SERVER_NAMES[1:], server_node_lists[1:]):
            if lst:
                for other in lst:
                    if find_by_name(primary, other["name"]) is None:
                        stats["orphaned"].append(
                            f'{sname}: "{child_path}/{other["name"]}" '
                            f"has no match in server1"
                        )

    return merged


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--server1", required=True)
    ap.add_argument("--server2", required=True)
    ap.add_argument("--server3", required=True)
    ap.add_argument("--server4", required=True)
    ap.add_argument("--out-json", default="merged_songs.json")
    ap.add_argument("--out-dart", default="merged_song_data.dart")
    args = ap.parse_args()

    server_lists = [
        load_server_file(args.server1),
        load_server_file(args.server2),
        load_server_file(args.server3),
        load_server_file(args.server4),
    ]

    stats = {"audio_total": 0, "audio_no_urls": 0, "url_count_hist": {}, "orphaned": []}
    merged = merge_nodes(server_lists, "", stats)

    with open(args.out_json, "w", encoding="utf-8") as f:
        json.dump(merged, f, ensure_ascii=False, indent=2)

    with open(args.out_dart, "w", encoding="utf-8") as f:
        f.write("// AUTO-GENERATED by merge_song_servers.py -- do not edit by hand.\n")
        f.write("final mergedSongContent = ")
        json.dump(merged, f, ensure_ascii=False, indent=2)
        f.write(";\n")

    print(f"Wrote {args.out_json} and {args.out_dart}")
    print(f"Total audio songs: {stats['audio_total']}")
    print(f"Songs with NO url on any server: {stats['audio_no_urls']}")
    print("URL coverage histogram (n_servers_available -> count of songs):")
    for k in sorted(stats["url_count_hist"]):
        print(f"  {k} server(s): {stats['url_count_hist'][k]} songs")
    if stats["orphaned"]:
        print(f"\n{len(stats['orphaned'])} songs exist in server2/3/4 but not server1 "
              f"(dropped, since server1 defines the tree):")
        for line in stats["orphaned"][:20]:
            print(f"  - {line}")
        if len(stats["orphaned"]) > 20:
            print(f"  ... and {len(stats['orphaned']) - 20} more")


if __name__ == "__main__":
    main()