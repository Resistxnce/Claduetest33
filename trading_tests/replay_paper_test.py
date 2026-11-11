#!/usr/bin/env python3
"""Forward test of the paper-trading rules over a day and a week.

First "plan" writes down the start time, costs and price forecasts. Once a
test period is over, "score" downloads Coinbase's 1-minute price history for
the period and runs the same rules through it minute by minute, as if they had
been trading live: each decision only sees prices up to that minute. The only
difference from the live one-hour test (live_paper_test.py) is that the
bid/ask spread is estimated instead of recorded.

Rules (identical to live_paper_test.py):
  Trend follower: hold the coin while its 10-minute average price is above its
                  30-minute average; otherwise hold cash. Checked every minute.
  Dip buyer:      buy when the price falls 1.5 standard deviations below its
                  30-minute average; sell when it climbs back to that average,
                  if it drops 1% below the purchase price, or at the end.
  Buy and hold:   buy at the start, sell at the end.
  Coin flip:      every 5 minutes a seeded coin flip decides whether to hold.
Each rule starts with $1,000 per coin. Costs: buy at the ask, sell at the bid,
and pay a fee per trade (0.4% in the plan). Everything is sold at the end.

Usage:
  python -I replay_paper_test.py plan PLAN.json START (e.g. 2026-11-11T18:00:00Z)
  python -I replay_paper_test.py score PLAN.json TEST OUT_DIR   (TEST: day, week, ...)
"""
import csv
import json
import math
import random
import sys
import time
import urllib.request
from datetime import datetime, timedelta, timezone
from pathlib import Path

COINS = ["BTC-USD", "ETH-USD", "SOL-USD"]
RULES = ["Trend follower", "Dip buyer", "Buy and hold", "Coin flip"]
BASE = "https://api.exchange.coinbase.com/products/"
Z90 = 1.645


def get(url):
    req = urllib.request.Request(url, headers={"User-Agent": "research-script"})
    for attempt in range(5):
        try:
            with urllib.request.urlopen(req, timeout=30) as resp:
                return json.load(resp)
        except Exception:
            time.sleep(1 + 2 * attempt)
    raise RuntimeError(f"could not fetch {url}")


def iso(t):
    return t.strftime("%Y-%m-%dT%H:%M:%SZ")


def parse(s):
    return datetime.strptime(s, "%Y-%m-%dT%H:%M:%SZ").replace(tzinfo=timezone.utc)


def mean(xs):
    return sum(xs) / len(xs)


def stdev(xs):
    m = mean(xs)
    return math.sqrt(sum((x - m) ** 2 for x in xs) / (len(xs) - 1))


def plan(path, start):
    """Record the start time, settings and 90% price ranges from recent daily volatility."""
    now = datetime.now(timezone.utc)
    forecast, live = {}, {}
    for c in COINS:
        days = sorted(get(BASE + c + "/candles?granularity=86400"), key=lambda r: r[0])[-61:]
        closes = [float(r[4]) for r in days]
        sigma = stdev([math.log(b / a) for a, b in zip(closes, closes[1:])])
        forecast[c] = {
            "daily_sigma_last_60_days": round(sigma, 5),
            "day_range_factors": [round(math.exp(-Z90 * sigma), 5), round(math.exp(Z90 * sigma), 5)],
            "week_range_factors": [round(math.exp(-Z90 * sigma * math.sqrt(7)), 5),
                                   round(math.exp(Z90 * sigma * math.sqrt(7)), 5)],
        }
        t = get(BASE + c + "/ticker")
        live[c] = float(t["price"])
    doc = {
        "registered_at": iso(now),
        "start": start,
        "tests": {"day": {"minutes": 1440}, "week": {"minutes": 10080}},
        "stake_per_coin": 1000.0,
        "fee_per_trade": 0.004,
        "half_spread_estimate": 0.00005,
        "coin_flip_seed": 42,
        "price_at_registration": live,
        "forecast": forecast,
        "rules": __doc__.split("Rules (identical to live_paper_test.py):")[1].split("Usage:")[0].strip(),
    }
    Path(path).write_text(json.dumps(doc, indent=2) + "\n")
    print(json.dumps(doc, indent=2))


def minute_prices(coin, first, last):
    """Close of each 1-minute candle, keyed by candle start time (epoch seconds)."""
    closes, t = {}, first
    while t <= last:
        t2 = min(t + timedelta(minutes=299), last)
        for row in get(BASE + coin + f"/candles?granularity=60&start={iso(t)}&end={iso(t2)}"):
            closes[int(row[0])] = float(row[4])
        t = t2 + timedelta(minutes=1)
        time.sleep(0.15)
    return closes


class Book:
    def __init__(self, stake, fee):
        self.fee = fee
        self.cash_gross = self.cash_net = stake
        self.units_gross = self.units_net = 0.0
        self.holding, self.entry, self.trades = False, None, 0

    def buy(self, q):
        if self.holding:
            return False
        self.units_gross, self.cash_gross = self.cash_gross / q["mid"], 0.0
        self.units_net, self.cash_net = self.cash_net * (1 - self.fee) / q["ask"], 0.0
        self.holding, self.entry = True, q["mid"]
        self.trades += 1
        return True

    def sell(self, q):
        if not self.holding:
            return False
        self.cash_gross, self.units_gross = self.units_gross * q["mid"], 0.0
        self.cash_net, self.units_net = self.units_net * q["bid"] * (1 - self.fee), 0.0
        self.holding, self.entry = False, None
        self.trades += 1
        return True


def score(path, test, out_dir):
    doc = json.loads(Path(path).read_text())
    spec = doc["tests"][test]
    start = parse(spec.get("start", doc["start"]))
    minutes = spec["minutes"]
    end = start + timedelta(minutes=minutes)
    if datetime.now(timezone.utc) < end + timedelta(minutes=2):
        sys.exit(f"The {test} test ends at {iso(end)}; score it after that.")
    out = Path(out_dir)
    out.mkdir(parents=True, exist_ok=True)
    hs, fee, stake = doc["half_spread_estimate"], doc["fee_per_trade"], doc["stake_per_coin"]
    rng = random.Random(doc["coin_flip_seed"])
    books = {(r, c): Book(stake, fee) for r in RULES for c in COINS}

    # Price at decision time T = close of the candle covering [T - 1 min, T).
    series = {}
    for c in COINS:
        closes = minute_prices(c, start - timedelta(minutes=301), end)
        vals, last = [], None
        for k in range(-300, minutes + 1):
            key = int((start + timedelta(minutes=k - 1)).timestamp())
            last = closes.get(key, last)
            vals.append(last)
        first_known = next(v for v in vals if v is not None)
        series[c] = [v if v is not None else first_known for v in vals]

    trades_file = open(out / f"{test}_trades.csv", "w", newline="")
    tw = csv.writer(trades_file)
    tw.writerow(["time", "rule", "coin", "side", "price", "why"])
    prices = {c: series[c][:300] for c in COINS}

    def act(rule, coin, side, q, when, why):
        book = books[(rule, coin)]
        if book.buy(q) if side == "BUY" else book.sell(q):
            tw.writerow([iso(when), rule, coin, side, f"{q['mid']:.4f}", why])

    for i in range(minutes + 1):
        when, last = start + timedelta(minutes=i), i == minutes
        for c in COINS:
            mid = series[c][300 + i]
            q = {"mid": mid, "bid": mid * (1 - hs), "ask": mid * (1 + hs)}
            prev = prices[c][-30:]
            prices[c].append(mid)
            p = prices[c]
            if last:
                for r in RULES:
                    act(r, c, "SELL", q, when, "end of test")
                continue
            if mean(p[-10:]) > mean(p[-30:]):
                act("Trend follower", c, "BUY", q, when, "10-min average above 30-min average")
            else:
                act("Trend follower", c, "SELL", q, when, "10-min average fell below 30-min average")
            avg, sd = mean(prev), stdev(prev)
            z = (mid - avg) / sd if sd > 0 else 0.0
            dip = books[("Dip buyer", c)]
            if not dip.holding and z < -1.5:
                act("Dip buyer", c, "BUY", q, when, f"price {z:.1f} std devs below 30-min average")
            elif dip.holding and mid >= avg:
                act("Dip buyer", c, "SELL", q, when, "back to 30-min average")
            elif dip.holding and mid <= dip.entry * 0.99:
                act("Dip buyer", c, "SELL", q, when, "stop-loss: 1% below purchase")
            if i == 0:
                act("Buy and hold", c, "BUY", q, when, "start of test")
            if i % 5 == 0:
                if rng.random() < 0.5:
                    act("Coin flip", c, "BUY", q, when, "coin flip: heads")
                else:
                    act("Coin flip", c, "SELL", q, when, "coin flip: tails")
    trades_file.close()

    lines = [f"{test} test: {iso(start)} to {iso(end)} ({minutes} minutes, a decision every minute)",
             f"$1,000 per coin per rule; after costs = estimated spread plus {fee:.1%} per trade", ""]
    lines.append(f"{'Rule':16}" + "".join(f"{c:>26}" for c in COINS) + f"{'All three ($3,000)':>26}  trades")
    for r in RULES:
        cells, g_tot, n_tot, trades = [], 0.0, 0.0, 0
        for c in COINS:
            b = books[(r, c)]
            g_tot, n_tot, trades = g_tot + b.cash_gross, n_tot + b.cash_net, trades + b.trades
            cells.append(f"${b.cash_gross:>8,.2f} / ${b.cash_net:>8,.2f}")
        lines.append(f"{r:16}" + "".join(f"{x:>26}" for x in cells)
                     + f"{f'${g_tot:,.2f} / ${n_tot:,.2f}':>26}  {trades}")
    lines.append("(each cell: before costs / after costs)")
    lines.append("")
    key = "day_range_factors" if minutes <= 1440 else "week_range_factors"
    for c in COINS:
        s, e = series[c][300], series[c][300 + minutes]
        lo, hi = (s * f for f in doc["forecast"][c][key])
        inside = "inside" if lo <= e <= hi else "OUTSIDE"
        lines.append(f"{c}: ${s:,.2f} -> ${e:,.2f} ({e / s - 1:+.2%}); "
                     f"forecast 90% range ${lo:,.2f} to ${hi:,.2f}: {inside}")
    summary = "\n".join(lines) + "\n"
    (out / f"{test}_summary.txt").write_text(summary)
    print(summary)


if __name__ == "__main__":
    if sys.argv[1] == "plan":
        plan(sys.argv[2], sys.argv[3])
    elif sys.argv[1] == "score":
        score(sys.argv[2], sys.argv[3], sys.argv[4])
    else:
        sys.exit(__doc__)
