#!/usr/bin/env python3
"""Score the $300 Nvidia paper trade recorded in nvda_300_test.json.

Sells at the open of the 1-minute bar starting at the planned exit time
(12:00 pm EST on 2026-11-12), compares with the same $300 in SPY, and shows the
best and worst moments during the hold for context.
Usage: python -I nvda_300_test.py trading_tests/nvda_300_test.json
"""
import json
import sys
import time
import urllib.request
from datetime import datetime, timedelta, timezone

UA = {"User-Agent": "Mozilla/5.0 (research-script)"}


def bars(sym, start, end):
    url = (f"https://query1.finance.yahoo.com/v8/finance/chart/{sym}?interval=1m"
           f"&period1={int(start.timestamp())}&period2={int(end.timestamp())}")
    for attempt in range(4):
        try:
            with urllib.request.urlopen(urllib.request.Request(url, headers=UA), timeout=20) as r:
                res = json.load(r)["chart"]["result"][0]
            q = res["indicators"]["quote"][0]
            return [(t, o, h, l, c) for t, o, h, l, c in
                    zip(res["timestamp"], q["open"], q["high"], q["low"], q["close"]) if o is not None]
        except Exception:
            time.sleep(1 + 2 * attempt)
    raise RuntimeError(f"could not fetch {sym} prices")


def parse(s):
    return datetime.strptime(s, "%Y-%m-%dT%H:%M:%SZ").replace(tzinfo=timezone.utc)


def est(ts):
    return (datetime.fromtimestamp(ts, timezone.utc) - timedelta(hours=5)).strftime("%b %d %I:%M %p EST")


rec = json.load(open(sys.argv[1]))
entry, exit_t = rec["entry"], parse(rec["planned_exit"]["time_utc"])
if datetime.now(timezone.utc) < exit_t + timedelta(minutes=1):
    sys.exit(f"Planned exit is {rec['planned_exit']['time_est']}; score it after that.")
start = parse(entry["time_utc"])
out = {}
for sym, key in [("NVDA", "nvda"), ("SPY", "spy")]:
    b = bars(sym, start - timedelta(minutes=1), exit_t + timedelta(minutes=5))
    sell = min(b, key=lambda x: abs(x[0] - exit_t.timestamp()))
    held = [x for x in b if start.timestamp() - 60 <= x[0] <= exit_t.timestamp()]
    shares, buy = entry[f"{key}_shares"], entry[f"{key}_price"]
    out[sym] = (buy, sell, shares, held)
nv_buy, nv_sell, nv_sh, held = out["NVDA"]
value = nv_sh * nv_sell[1]
hi, lo = max(held, key=lambda x: x[2]), min(held, key=lambda x: x[3])
print(f"Nvidia: bought {nv_sh:.4f} shares at ${nv_buy:,.2f} ({entry['time_est']}), "
      f"sold at ${nv_sell[1]:,.2f} ({est(nv_sell[0])})")
print(f"  $300.00 -> ${value:,.2f} ({value - 300:+,.2f}, {nv_sell[1] / nv_buy - 1:+.2%})")
print(f"  Highest point while held: ${hi[2]:,.2f} at {est(hi[0])} (worth ${nv_sh * hi[2]:,.2f}); "
      f"lowest: ${lo[3]:,.2f} at {est(lo[0])} (worth ${nv_sh * lo[3]:,.2f})")
spy_buy, spy_sell, spy_sh, _ = out["SPY"]
print(f"Same $300 in SPY (S&P 500): ${spy_buy:,.2f} -> ${spy_sell[1]:,.2f}, "
      f"$300.00 -> ${spy_sh * spy_sell[1]:,.2f} ({spy_sell[1] / spy_buy - 1:+.2%})")
