"""Lines of firmware code over time, from the git history of the firmware repository.

Counts the non-blank lines of the hand-written source at every commit, then draws
the chart used in Chapter 3. Vendor code (HAL, CMSIS, WIZnet) and the files that
STM32CubeMX generates (Core/) are not counted.

Run it again before the final report to include the newest commits:

    python loc_history.py PATH_TO_FIRMWARE_REPO [REF]

REF is the branch to read (default: HEAD). It writes loc.csv and loc-over-time.svg
next to this script.
"""

import csv
import subprocess
import sys
from datetime import datetime
from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.dates as mdates
import matplotlib.pyplot as plt

# The hand-written code, as (label, path prefix). Each gets its own series in the chart.
GROUPS = [
    ("Application (App/)", "App/"),
    ("Modbus library (Libraries/modbus/)", "Libraries/modbus/"),
]
EXTENSIONS = (".c", ".cpp", ".h", ".hpp")

# The start of the build semester, drawn as a reference line.
SEMESTER_START = datetime(2026, 8, 24)

here = Path(__file__).parent


def git(repo, *args):
    return subprocess.run(
        ["git", "-C", str(repo), *args], capture_output=True, check=True
    ).stdout


def main():
    repo = sys.argv[1]
    ref = sys.argv[2] if len(sys.argv) > 2 else "HEAD"

    commits = []
    # Follow the main line of the history only, so that commits from side branches that
    # were merged later do not show up as short jumps in the chart.
    for line in git(repo, "log", "--first-parent", "--reverse", "--format=%H %at", ref).decode().splitlines():
        sha, when = line.split()
        # Rebased commits can carry an older date than the one before them. The date
        # never goes back, so the chart keeps the real order of the work.
        when = max(int(when), commits[-1][1] if commits else 0)
        commits.append((sha, when))

    blob_lines = {}  # blob hash -> non-blank line count

    def count(blob):
        if blob not in blob_lines:
            text = git(repo, "cat-file", "blob", blob).decode("utf-8", errors="replace")
            blob_lines[blob] = sum(1 for l in text.splitlines() if l.strip())
        return blob_lines[blob]

    rows = []
    for sha, when in commits:
        totals = {prefix: 0 for _, prefix in GROUPS}
        files = 0
        for entry in git(repo, "ls-tree", "-r", sha).decode().splitlines():
            meta, path = entry.split("\t", 1)
            blob = meta.split()[2]
            if not path.endswith(EXTENSIONS):
                continue
            for _, prefix in GROUPS:
                if path.startswith(prefix):
                    totals[prefix] += count(blob)
                    files += 1
        rows.append(
            (
                datetime.fromtimestamp(when),  # local time
                sha[:7],
                files,
                *[totals[p] for _, p in GROUPS],
            )
        )

    with open(here / "loc.csv", "w", newline="") as f:
        w = csv.writer(f)
        w.writerow(["date", "commit", "files", *[prefix for _, prefix in GROUPS], "total"])
        for date, sha, files, *vals in rows:
            w.writerow([date.strftime("%Y-%m-%d"), sha, files, *vals, sum(vals)])

    dates = [r[0] for r in rows]
    series = [[r[3 + i] for r in rows] for i in range(len(GROUPS))]
    total = [sum(v) for v in zip(*series)]

    plt.rcParams.update({"font.size": 9, "font.family": "DejaVu Sans"})
    fig, ax = plt.subplots(figsize=(6.4, 3.3))
    ax.stackplot(
        dates, *series, labels=[label for label, _ in GROUPS],
        colors=["#3b78c4", "#e08a2e"], step="post", alpha=0.9,
    )
    ax.plot(dates, total, color="#222222", linewidth=1.0, drawstyle="steps-post")
    ax.axvline(SEMESTER_START, color="#777777", linestyle="--", linewidth=0.9)
    ax.text(SEMESTER_START, ax.get_ylim()[1] * 0.97, " Build semester starts",
            color="#555555", fontsize=8, va="top", ha="left")
    ax.annotate(f"{total[-1]:,} lines", (dates[-1], total[-1]), xytext=(-4, 6),
                textcoords="offset points", ha="right", fontsize=8, color="#222222")
    ax.set_ylabel("Non-blank lines of source")
    ax.set_xlim(dates[0], dates[-1])
    ax.set_ylim(bottom=0)
    ax.xaxis.set_major_locator(mdates.MonthLocator())
    ax.xaxis.set_major_formatter(mdates.DateFormatter("%b %d"))
    ax.grid(axis="y", color="#dddddd", linewidth=0.6)
    ax.set_axisbelow(True)
    for side in ("top", "right"):
        ax.spines[side].set_visible(False)
    ax.legend(loc="upper left", frameon=False, bbox_to_anchor=(0.0, 0.88), fontsize=8)
    fig.tight_layout()
    fig.savefig(here / "loc-over-time.svg")
    print(f"{len(rows)} commits, {dates[0]:%Y-%m-%d} to {dates[-1]:%Y-%m-%d}, "
          f"{total[-1]} lines in {rows[-1][2]} files")


main()
