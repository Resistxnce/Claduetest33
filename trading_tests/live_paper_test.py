#!/usr/bin/env python3
"""Live paper-trading test on BTC, ETH and SOL using Coinbase public prices.

Rules are fixed before the test starts and are not changed during it:
  Trend follower: hold the coin while its 10-minute average price is above its
                  30-minute average; otherwise hold cash. Checked every minute.
  Dip buyer:      buy when the price falls 1.5 standard deviations below its
                  30-minute average; sell when it climbs back to that average,
                  if it drops 1% below the purchase price, or at the end.
  Buy and hold:   buy at the start, sell at the end.
  Coin flip:      every 5 minutes a (seeded) coin flip decides whether to hold.
Each rule starts with $1,000 per coin. "Before costs" trades at the mid price
with no fee. "After costs" buys at the ask, sells at the bid and pays a 0.4%
fee per trade, about an entry-level US exchange fee. Everything is sold at the
end. At the start it also records a 90% range for each coin's price at the end,
based on the last 5 hours of 1-minute volatility.

Usage: python -I live_paper_test.py OUT_DIR [MINUTES] [SECONDS_PER_STEP]
"""
import csv
import json
import math
import random
import sys
import time
import urllib.request
from datetime import datetime, timezone
from pathlib import Path

COINS = ["BTC-USD", "ETH-USD", "SOL-USD"]
RULES = ["Trend follower", "Dip buyer", "Buy and hold", "Coin flip"]
BASE = "https://api.exchange.coinbase.com/products/"
FEE = 0.004
STAKE = 1000.0


def get(url):
    req = urllib.request.Request(url, headers={"User-Agent": "research-script"})
    for attempt in range(4):
        try:
            with urllib.request.urlopen(req, timeout=15) as resp:
                return json.load(resp)
        except Exception:
            time.sleep(1 + 2 * attempt)
    return None


def ticker(coin):
    t = get(BASE + coin + "/ticker")
    if not t or "bid" not in t:
        return None
    bid, ask = float(t["bid"]), float(t["ask"])
    return {"bid": bid, "ask": ask, "mid": (bid + ask) / 2}


def history(coin):
    candles = get(BASE + coin + "/candles?granularity=60") or []
    return [float(c[4]) for c in sorted(candles, key=lambda c: c[0])]


def mean(xs):
    return sum(xs) / len(xs)


def stdev(xs):
    m = mean(xs)
    return math.sqrt(sum((x - m) ** 2 for x in xs) / (len(xs) - 1))


def now():
    return datetime.now(timezone.utc).strftime("%H:%M:%S UTC")


class Book:
    """One rule on one coin, tracked before and after trading costs."""

    def __init__(self):
        self.cash_gross = self.cash_net = STAKE
        self.units_gross = self.units_net = 0.0
        self.holding, self.entry, self.trades = False, None, 0

    def buy(self, q):
        if self.holding:
            return False
        self.units_gross, self.cash_gross = self.cash_gross / q["mid"], 0.0
        self.units_net, self.cash_net = self.cash_net * (1 - FEE) / q["ask"], 0.0
        self.holding, self.entry = True, q["mid"]
        self.trades += 1
        return True

    def sell(self, q):
        if not self.holding:
            return False
        self.cash_gross, self.units_gross = self.units_gross * q["mid"], 0.0
        self.cash_net, self.units_net = self.units_net * q["bid"] * (1 - FEE), 0.0
        self.holding, self.entry = False, None
        self.trades += 1
        return True


def main():
    out = Path(sys.argv[1])
    out.mkdir(exist_ok=True)
    minutes = int(sys.argv[2]) if len(sys.argv) > 2 else 60
    step = float(sys.argv[3]) if len(sys.argv) > 3 else 60.0   # seconds between checks (60 = one per minute)
    rng = random.Random(42)
    prices = {c: history(c) for c in COINS}
    books = {(r, c): Book() for r in RULES for c in COINS}
    lastq = {c: ticker(c) for c in COINS}
    start = dict(lastq)

    with open(out / "start.txt", "w") as f:
        f.write(f"Started {now()}, running {minutes} minutes\n")
        for c in COINS:
            p = prices[c][-300:]
            rets = [math.log(b / a) for a, b in zip(p, p[1:])]
            s = stdev(rets) * math.sqrt(minutes)
            m0 = start[c]["mid"]
            lo, hi = m0 * math.exp(-1.645 * s), m0 * math.exp(1.645 * s)
            f.write(f"{c}: start ${m0:,.2f} (bid {start[c]['bid']:,.2f} / ask {start[c]['ask']:,.2f}); "
                    f"90% range for the end: ${lo:,.2f} to ${hi:,.2f}\n")
    print((out / "start.txt").read_text(), flush=True)

    trade_log = open(out / "trades.csv", "w", newline="")
    tw = csv.writer(trade_log)
    tw.writerow(["time", "rule", "coin", "side", "mid", "bid", "ask", "why"])
    price_log = open(out / "prices.csv", "w", newline="")
    pw = csv.writer(price_log)
    pw.writerow(["time"] + [f"{c} {k}" for c in COINS for k in ("bid", "ask", "mid")])

    def act(rule, coin, side, q, why):
        book = books[(rule, coin)]
        if (book.buy(q) if side == "BUY" else book.sell(q)):
            tw.writerow([now(), rule, coin, side, f"{q['mid']:.4f}", q["bid"], q["ask"], why])
            trade_log.flush()
            print(f"{now()}  {rule:15} {side:4} {coin} at ${q['mid']:,.2f}  ({why})", flush=True)

    t0 = time.monotonic()
    for i in range(minutes + 1):
        wait = t0 + step * i - time.monotonic()
        if wait > 0:
            time.sleep(wait)
        last = i == minutes
        row = [now()]
        for c in COINS:
            q = ticker(c)
            if q is None:
                if not last:
                    row += ["", "", ""]
                    continue
                q = lastq[c]                       # close out on the last known quote
            lastq[c] = q
            row += [q["bid"], q["ask"], q["mid"]]
            prev = prices[c][-30:]
            prices[c].append(q["mid"])
            p = prices[c]

            if last:
                for r in RULES:
                    act(r, c, "SELL", q, "end of test")
                continue

            fast, slow = mean(p[-10:]), mean(p[-30:])
            if fast > slow:
                act("Trend follower", c, "BUY", q, "10-min average above 30-min average")
            else:
                act("Trend follower", c, "SELL", q, "10-min average fell below 30-min average")

            avg, sd = mean(prev), stdev(prev)
            z = (q["mid"] - avg) / sd if sd > 0 else 0.0
            dip = books[("Dip buyer", c)]
            if not dip.holding and z < -1.5:
                act("Dip buyer", c, "BUY", q, f"price {z:.1f} std devs below 30-min average")
            elif dip.holding and q["mid"] >= avg:
                act("Dip buyer", c, "SELL", q, "back to 30-min average")
            elif dip.holding and q["mid"] <= dip.entry * 0.99:
                act("Dip buyer", c, "SELL", q, "stop-loss: 1% below purchase")

            if i == 0:
                act("Buy and hold", c, "BUY", q, "start of test")

            if i % 5 == 0:
                if rng.random() < 0.5:
                    act("Coin flip", c, "BUY", q, "coin flip: heads")
                else:
                    act("Coin flip", c, "SELL", q, "coin flip: tails")
        pw.writerow(row)
        price_log.flush()

    lines = [f"\nFinished {now()}. $1,000 per coin per rule; costs = bid/ask spread plus 0.4% per trade.\n"]
    lines.append(f"{'Rule':16}" + "".join(f"{c:>26}" for c in COINS) + f"{'All three ($3,000)':>26}  trades")
    for r in RULES:
        cells, g_tot, n_tot, trades = [], 0.0, 0.0, 0
        for c in COINS:
            b = books[(r, c)]
            g_tot += b.cash_gross
            n_tot += b.cash_net
            trades += b.trades
            cells.append(f"${b.cash_gross:>8,.2f} / ${b.cash_net:>8,.2f}")
        lines.append(f"{r:16}" + "".join(f"{x:>26}" for x in cells)
                     + f"{f'${g_tot:,.2f} / ${n_tot:,.2f}':>26}  {trades}")
    lines.append("(each cell: before costs / after costs)\n")
    for c in COINS:
        s, e = start[c]["mid"], lastq[c]["mid"]
        lines.append(f"{c}: ${s:,.2f} -> ${e:,.2f} ({(e / s - 1):+.3%})")
    lines.append((out / "start.txt").read_text())
    summary = "\n".join(lines)
    (out / "summary.txt").write_text(summary)
    print(summary, flush=True)


if __name__ == "__main__":
    main()
