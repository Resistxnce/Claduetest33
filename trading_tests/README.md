# Crypto paper-trading tests

Tests of four simple trading rules on bitcoin, ether and Solana, using
Coinbase's public prices and fake money ($1,000 per coin per rule). The rules
were fixed before each test started.

| Rule | What it does |
|---|---|
| Trend follower | Holds a coin while its 10-minute average price is above its 30-minute average; otherwise holds cash. Checks every minute. |
| Dip buyer | Buys when the price falls 1.5 standard deviations below its 30-minute average. Sells when it gets back to that average, if it drops 1% below the purchase price, or at the end. |
| Buy and hold | Buys at the start and sells at the end. |
| Coin flip | Every 5 minutes a coin flip decides whether to hold the coin. |

Results are shown before costs and after costs. "After costs" buys at the
ask, sells at the bid and pays a 0.4% fee per trade, about an entry-level US
exchange fee.

## The tests

- **One hour, live** (`live_paper_test.py`): 2026-11-11, 17:48 to 18:48 UTC,
  using live bid/ask quotes checked every minute.
- **One day** (`replay_paper_test.py`): 2026-11-11 18:30 UTC to
  2026-11-12 18:30 UTC. `forward_test_plan.json` records the start time,
  costs and 90% price ranges, written before the start. When the day ends,
  `score` downloads Coinbase's 1-minute prices for it and runs the same rules
  through them minute by minute, so each decision only sees prices up to that
  minute. The bid/ask spread is estimated rather than recorded. The plan also
  lists a one-week test; that test was cancelled after it started and will not
  be scored.

- **$300 of Nvidia, one day** (`nvda_300_test.json`, `nvda_300_test.py`): a
  pretend $300 buy at $177.14 on 2026-11-11 at 1:54 pm EST, sold at 12:00 pm
  EST on 2026-11-12, with the same $300 in SPY (an S&P 500 fund) for
  comparison. No commission. Score it with
  `python3 -I trading_tests/nvda_300_test.py trading_tests/nvda_300_test.json`.

- **$200 long Nvidia / $200 short AMD, four hours** (`pair_trade_200.json`,
  `pair_trade_200.py`): opened 2026-11-13 around 10:05 am EST, closed four
  hours later. Score it with
  `python3 -I trading_tests/pair_trade_200.py trading_tests/pair_trade_200.json`.

To score the day test once it has ended (needs only Python 3):

```sh
python3 -I trading_tests/replay_paper_test.py score trading_tests/forward_test_plan.json day /tmp/day_results
```
