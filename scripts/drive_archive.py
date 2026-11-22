#!/usr/bin/env python3
"""Move the site's images to Google Drive and free the local disk.

Every image this project makes or collects (page photos for quizzes, structure
drawings, Google Flow illustration originals) is uploaded to Drive under
"시몬 책장/", checked against its local md5, and only then removed locally.
The site itself only keeps the small WebP copies in assets/img/.

  python3 scripts/drive_archive.py sweep              # show what would move
  python3 scripts/drive_archive.py sweep --apply      # upload, verify, delete local
  python3 scripts/drive_archive.py push FILE... --to pages --book SLUG [--apply]
  python3 scripts/drive_archive.py verify             # Drive md5 vs index

sweep collects:
  media/flow/*                         -> 시몬 책장/일러스트 원본/
  media/covers/*                       -> 시몬 책장/표지 원본/
  media/pages/<slug>/*                 -> 시몬 책장/쪽 사진/<slug>/
  ~/Downloads/<slug>-structure-*.png   -> 시몬 책장/구조 그림/<slug>/

Nothing is uploaded or deleted without --apply. Add --trash to move local files
to the Trash instead of deleting them (then empty the Trash to free space).
Needs the gws CLI signed in with the drive.file scope (gws auth status).
"""
import argparse, datetime, glob, hashlib, json, os, re, subprocess, sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
MEDIA = os.path.join(ROOT, "media")
INDEX = os.path.join(MEDIA, ".drive-index.json")
LOG = os.path.join(MEDIA, ".drive-log.txt")
DRIVE_ROOT = "시몬 책장"
KINDS = {"pages": "쪽 사진", "drawings": "구조 그림", "flow": "일러스트 원본", "covers": "표지 원본"}
IMAGE = re.compile(r"\.(jpe?g|png|heic|heif|webp|gif)$", re.I)
SLUG = re.compile(r"^[a-z0-9][a-z0-9-]*$")


def md5(path):
    h = hashlib.md5()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def gws(*args):
    p = subprocess.run(["gws", *args], capture_output=True, text=True)
    out = p.stdout
    i = out.find("{")
    if i < 0:
        raise SystemExit("gws %s failed: %s %s" % (" ".join(args[:3]), out[:300], p.stderr[:300]))
    data = json.loads(out[i:])
    if "error" in data:
        raise SystemExit("gws %s: %s" % (" ".join(args[:3]), data["error"].get("message")))
    return data


def load_index():
    if os.path.exists(INDEX):
        with open(INDEX) as f:
            return json.load(f)
    return {"folders": {}, "files": {}}


def save_index(idx):
    os.makedirs(MEDIA, exist_ok=True)
    tmp = INDEX + ".tmp"
    with open(tmp, "w") as f:
        json.dump(idx, f, indent=2, ensure_ascii=False)
    os.replace(tmp, INDEX)


def folder(idx, parts):
    """Drive folder id for a path like ["쪽 사진", "slug"], created on first use."""
    parent, key = None, ""
    for name in [DRIVE_ROOT] + parts:
        key = key + "/" + name
        fid = idx["folders"].get(key)
        if not fid:
            body = {"name": name, "mimeType": "application/vnd.google-apps.folder"}
            if parent:
                body["parents"] = [parent]
            fid = gws("drive", "files", "create", "--json", json.dumps(body), "--params", '{"fields":"id"}')["id"]
            idx["folders"][key] = fid
            save_index(idx)
        parent = fid
    return parent


def targets(kind, book):
    parts = [KINDS[kind]]
    if kind in ("pages", "drawings"):
        if not book or not SLUG.match(book):
            raise SystemExit("--book <slug> is needed for %s (the file name in _books/ without .md)" % kind)
        parts.append(book)
    return parts


def collect_sweep():
    jobs = []
    for p in sorted(glob.glob(os.path.join(MEDIA, "flow", "*"))):
        if os.path.isfile(p) and IMAGE.search(p):
            jobs.append((p, ["flow", None]))
    for p in sorted(glob.glob(os.path.join(MEDIA, "covers", "*"))):
        if os.path.isfile(p) and IMAGE.search(p):
            jobs.append((p, ["covers", None]))
    for d in sorted(glob.glob(os.path.join(MEDIA, "pages", "*"))):
        slug = os.path.basename(d)
        if os.path.isdir(d) and SLUG.match(slug):
            for p in sorted(glob.glob(os.path.join(d, "*"))):
                if os.path.isfile(p) and IMAGE.search(p):
                    jobs.append((p, ["pages", slug]))
    for p in sorted(glob.glob(os.path.expanduser("~/Downloads/*-structure-*.png"))):
        m = re.match(r"^(.+)-structure-\d{8}(?: \(\d+\))?\.png$", os.path.basename(p))
        if m and SLUG.match(m.group(1)) and os.path.exists(os.path.join(ROOT, "_books", m.group(1) + ".md")):
            jobs.append((p, ["drawings", m.group(1)]))
    return jobs


def remove_local(path, trash):
    if not trash:
        os.remove(path)
        return "deleted"
    if path.startswith("/Volumes/"):
        td = os.path.join("/".join(path.split("/")[:3]), ".Trashes", str(os.getuid()))
    else:
        td = os.path.expanduser("~/.Trash")
    os.makedirs(td, exist_ok=True)
    dst = os.path.join(td, os.path.basename(path))
    if os.path.exists(dst):
        dst += "." + datetime.datetime.now().strftime("%H%M%S")
    os.rename(path, dst)
    return "trashed"


def run(jobs, apply, trash):
    idx = load_index()
    total = 0
    plan = []
    for path, (kind, book) in jobs:
        parts = targets(kind, book)
        size = os.path.getsize(path)
        total += size
        plan.append((path, parts, size))
        print("%-9s %7.1f MB  %s  ->  %s/%s/" % ("UPLOAD", size / 1e6, os.path.relpath(path, ROOT) if path.startswith(ROOT) else path, DRIVE_ROOT, "/".join(parts)))
    print("%d files, %.1f MB%s" % (len(plan), total / 1e6, "" if apply else "  (dry run, add --apply)"))
    if not apply or not plan:
        return 0
    failed = 0
    log = open(LOG, "a")
    for path, parts, size in plan:
        h = md5(path)
        key = "/".join(parts) + "/" + os.path.basename(path)
        ent = idx["files"].get(key)
        if ent and ent.get("md5") != h:
            # Same name, different picture: keep both on Drive.
            stem, ext = os.path.splitext(os.path.basename(path))
            key = "/".join(parts) + "/" + stem + "-" + h[:6] + ext
            ent = idx["files"].get(key)
        if not ent:
            parent = folder(idx, parts)
            fid = gws("drive", "+upload", path, "--parent", parent, "--name", key.rsplit("/", 1)[1])["id"]
            ent = idx["files"][key] = {"id": fid, "md5": h, "size": size, "at": datetime.datetime.now().isoformat(timespec="seconds")}
            save_index(idx)
        r = gws("drive", "files", "get", "--params", json.dumps({"fileId": ent["id"], "fields": "md5Checksum,trashed"}))
        if r.get("md5Checksum") != h or r.get("trashed"):
            failed += 1
            print("KEPT      %s  (Drive copy does not match; not removed)" % path)
            continue
        how = remove_local(path, trash)
        log.write("%s\t%s\t%s\t%s\n" % (datetime.datetime.now().isoformat(timespec="seconds"), how, path, key))
        print("OK        %s  (%s locally, Drive id %s)" % (os.path.basename(path), how, ent["id"]))
    log.close()
    for d in glob.glob(os.path.join(MEDIA, "pages", "*")):
        if os.path.isdir(d) and not os.listdir(d):
            os.rmdir(d)
    print("done: %d moved to Drive, %d kept" % (len(plan) - failed, failed))
    return 1 if failed else 0


def verify():
    idx = load_index()
    bad = 0
    for key, ent in idx["files"].items():
        r = gws("drive", "files", "get", "--params", json.dumps({"fileId": ent["id"], "fields": "md5Checksum,trashed"}))
        if r.get("md5Checksum") != ent["md5"] or r.get("trashed"):
            bad += 1
            print("MISMATCH " + key)
    print("verify: %d files on Drive, %d mismatched" % (len(idx["files"]), bad))
    return 1 if bad else 0


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("command", choices=["sweep", "push", "verify"])
    ap.add_argument("files", nargs="*")
    ap.add_argument("--to", choices=sorted(KINDS))
    ap.add_argument("--book")
    ap.add_argument("--apply", action="store_true")
    ap.add_argument("--trash", action="store_true", help="move to Trash instead of deleting")
    a = ap.parse_args()
    if a.command == "verify":
        return verify()
    if a.command == "sweep":
        return run(collect_sweep(), a.apply, a.trash)
    if not a.files or not a.to:
        ap.error("push needs FILE... and --to")
    missing = [f for f in a.files if not os.path.isfile(f)]
    if missing:
        ap.error("not a file: " + ", ".join(missing))
    return run([(os.path.abspath(f), [a.to, a.book]) for f in a.files], a.apply, a.trash)


if __name__ == "__main__":
    sys.exit(main())
