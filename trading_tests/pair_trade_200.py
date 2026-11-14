#!/usr/bin/env python3
"""Score the $200 long Nvidia / $200 short AMD paper trade in pair_trade_200.json.

Closes both positions at the open of the 1-minute bar starting at the planned
exit time and shows the best and worst combined moments during the hold.
Usage: python -I pair_trade_200.py trading_tests/pair_trade_200.json
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
            return {t: o for t, o in zip(res["timestamp"], q["open"]) if o is not None}
        except Exception:
            time.sleep(1 + 2 * attempt)
    raise RuntimeError(f"could not fetch {sym} prices")


def parse(s):
    return datetime.strptime(s, "%Y-%m-%dT%H:%M:%SZ").replace(tzinfo=timezone.utc)


def est(ts):
    return (datetime.fromtimestamp(ts, timezone.utc) - timedelta(hours=5)).strftime("%I:%M %p EST")


rec = json.load(open(sys.argv[1]))
e, exit_t = rec["entry"], parse(rec["planned_exit"]["time_utc"])
if datetime.now(timezone.utc) < exit_t + timedelta(minutes=1):
    sys.exit(f"Planned exit is {rec['planned_exit']['time_est']}; score it after that.")
start = parse(e["time_utc"])
b = {s: bars(s, start - timedelta(minutes=1), exit_t + timedelta(minutes=5)) for s in ("NVDA", "AMD", "SPY")}
close = {s: b[s][min(b[s], key=lambda t: abs(t - exit_t.timestamp()))] for s in b}
nv = e["nvda_shares_long"] * (close["NVDA"] - e["nvda_price"])
amd = e["amd_shares_short"] * (e["amd_price"] - close["AMD"])
print(f"Long Nvidia:  {e['nvda_shares_long']:.4f} shares, ${e['nvda_price']:,.2f} -> ${close['NVDA']:,.2f}: {nv:+,.2f} "
      f"({close['NVDA'] / e['nvda_price'] - 1:+.2%})")
print(f"Short AMD:    {e['amd_shares_short']:.4f} shares, ${e['amd_price']:,.2f} -> ${close['AMD']:,.2f}: {amd:+,.2f} "
      f"(AMD moved {close['AMD'] / e['amd_price'] - 1:+.2%})")
print(f"Total on $400: {nv + amd:+,.2f} ({(nv + amd) / 400:+.2%})")
times = sorted(set(b["NVDA"]) & set(b["AMD"]))
times = [t for t in times if start.timestamp() - 60 <= t <= exit_t.timestamp()]
pnl = [(t, e["nvda_shares_long"] * (b["NVDA"][t] - e["nvda_price"]) + e["amd_shares_short"] * (e["amd_price"] - b["AMD"][t]))
       for t in times]
best, worst = max(pnl, key=lambda x: x[1]), min(pnl, key=lambda x: x[1])
print(f"Best moment: {best[1]:+,.2f} at {est(best[0])}; worst: {worst[1]:+,.2f} at {est(worst[0])}")
print(f"S&P 500 (SPY) over the same time: ${e['spy_price']:,.2f} -> ${close['SPY']:,.2f} ({close['SPY'] / e['spy_price'] - 1:+.2%})")
