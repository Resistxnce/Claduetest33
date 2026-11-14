# Roblox Creator Income as of 2026-11-11: DevEx, Payouts, Monetization Routes, Discovery, Freelancing, and Risks (US-based hobbyist Luau developer)

Research date: 2026-11-11. All figures carry their date or period. "Older" marks figures from before 2025. Where a figure comes only from a secondary or vendor site, it is labeled that way. Roblox uses "game" and "experience" interchangeably.

## 1. Developer Exchange (DevEx): rate, minimum, eligibility, payout timing, tax forms

### Takeaway
As of November 2026, the standard DevEx rate is **$0.0038 per earned Robux** ($38 per 10,000). Roblox raised it 8.5% from $0.0035 on Sept 5, 2025. A higher rate of **$0.0054 per Robux** (+42%) has applied since **June 8, 2026**, but only to qualifying in-game spend from **age-checked 18+ players in the US**, and only in games that use R15 avatars or qualify another way. To cash out you need **30,000 earned Robux**, which is about $114 at the standard rate. You must be **13 or older**, and your account must be verified and in good standing. Cash-outs run monthly through a third-party payout and tax vendor.

### Cited Findings
**Exchange rate (current and history)**
- Roblox Creator Hub (2026 page) states "10,000 Robux = $38 USD" at a fixed rate. — [Creator Hub: Earning on Roblox](https://create.roblox.com/docs/production/earning-on-roblox)
- From **Sept 5, 2025**, Roblox "increased the amount creators can receive in fiat currency based on earned Robux by 8.5%," applied prospectively. — [Roblox 10-K FY2025](https://www.sec.gov/Archives/edgar/data/1315098/000131509826000024/rblx-20251231.htm)
- (Older) The rate was **$0.0035 per Robux** as of Dec 31, 2023. — [Roblox FY2023 Annual Report (ARS)](https://www.sec.gov/Archives/edgar/data/1315098/000155837024004977/rblx-20231231xars.pdf) (figure taken from a search-result excerpt of the filing)
- **US 18+ DevEx rate.** The standard rate is "$0.38 per 100 Earned Robux" (≈$0.0038). The US 18+ rate is "$0.54 per 100 Earned Robux" (≈$0.0054), a 42% increase. Timeline: announced Apr 30, 2026; full eligibility details May 29, 2026; **live June 8, 2026**; updated Oct 12, 2026. — [DevForum: Introducing the US 18+ DevEx Rate](https://devforum.roblox.com/t/introducing-the-us-18-devex-rate-earn-42-more-on-spend-from-18-us-players/4607091)
  - **Spend that qualifies:** game passes, developer products, in-game Robux subscriptions, private servers, and Paid Access bought with Robux (added in the October 2026 update, reportedly effective Sept 21, 2026). **Spend that does not qualify:** in-game avatar items and Marketplace items. — [same DevForum post](https://devforum.roblox.com/t/introducing-the-us-18-devex-rate-earn-42-more-on-spend-from-18-us-players/4607091)
  - **Player requirements:** the player must be age-checked as 18+ and have a US "economic location." VPNs don't count. — [same](https://devforum.roblox.com/t/introducing-the-us-18-devex-rate-earn-42-more-on-spend-from-18-us-players/4607091)
  - **Game requirements:** Avatar Settings must be "R15 Only," or a custom avatar system must meet one of these conditions: always R15; a human-form rig with 15+ parts; a non-human rig; or **"no visible player characters (e.g., puzzle, strategy, or card games)."** Eligibility is automatic and needs no application. The creator's region doesn't matter. Roblox reviews eligibility on an ongoing basis and may remove it. — [same](https://devforum.roblox.com/t/introducing-the-us-18-devex-rate-earn-42-more-on-spend-from-18-us-players/4607091)
  - The 18+ rate and the Roblox Plus incentive don't stack; the higher of the two applies. US 18+ Robux are cashed out first, through the existing **monthly** DevEx process. These earnings appear as a separate line in Creator Analytics. An Age Check API arrived in October 2026: `Player:PromptAgeCheck()` and `Player.AgeChecked`, limited to one prompt per player per 15 minutes per session, with no console or VR support. — [same](https://devforum.roblox.com/t/introducing-the-us-18-devex-rate-earn-42-more-on-spend-from-18-us-players/4607091)
  - Roblox's newsroom says the rate applies to spend by US players in games using R15 avatars. — [Roblox Newsroom, Apr 2026](https://about.roblox.com/newsroom/2026/04/roblox-fuels-high-fidelity-games-over-18-players-increases-qualifying-devex-rate-42). Roblox announced it at the same time as it cut its 2026 forecast. — [MSN](https://www.msn.com/en-us/news/other/roblox-lifts-us-creator-payouts-42-as-2026-forecast-cut/gm-GM08CD8278)

**Minimum cash-out**
- The minimum is "at least 30,000 Earned Robux." — [Creator Hub](https://create.roblox.com/docs/production/earning-on-roblox)
- The threshold dropped from 100,000 to 50,000 Robux on Jan 31, 2022, then from 50,000 to 30,000 on Jan 31, 2023. — [10-K FY2025](https://www.sec.gov/Archives/edgar/data/1315098/000131509826000024/rblx-20251231.htm)
- That works out to about $114 per 30,000 Robux at $0.0038. — [Tubefilter, Apr 13, 2026](https://www.tubefilter.com/2026/04/13/roblox-plus-creator-payouts/)

**Eligibility**
- Official requirements: age **13 or older**, compliance with the Community Standards, and the required Earned Robux balance. — [Creator Hub](https://create.roblox.com/docs/production/earning-on-roblox)
- The 10-K describes the requirements as a minimum accumulated earned-Robux threshold plus a "verified creator account in good standing." Roblox runs a risk-based review to prevent fraud and money laundering. A third-party vendor collects tax information, does customer due diligence, and sends the payouts. — [10-K FY2025](https://www.sec.gov/Archives/edgar/data/1315098/000131509826000024/rblx-20251231.htm)
- Robux earned by reselling Limited items you didn't create can't be cashed out through DevEx. — [Creator Hub: Marketplace fees and commissions](https://create.roblox.com/docs/marketplace/marketplace-fees-and-commissions)
- Third-party guides (not official, and inconsistent) say ID verification uses a government ID plus a live selfie, naming Veriff or Persona. They also say under-18s need parent or guardian consent. They disagree on whether a Premium membership is required. — [ROLearn DevEx guide](https://rolearn.dev/guidance/roblox-devex-guide-requirements-rates/); [creation.dev DevEx guide](https://www.creation.dev/blog/roblox-devex-guide)

**Payout timing and tax forms**
- DevEx cash-outs follow a monthly process. — [DevForum US 18+ post](https://devforum.roblox.com/t/introducing-the-us-18-devex-rate-earn-42-more-on-spend-from-18-us-players/4607091)
- Third-party guides (unverified) describe the process this way: payouts go through **Tipalti**. The first cash-out requires registering with Tipalti and filing a **W-9** (US) or **W-8BEN** (non-US). Payment arrives by wire, ACH, or PayPal. A **1099-MISC** is issued above $600 a year. Time to payment is quoted as 10–21 business days or 3–7 business days after approval; the guides conflict. — [ROLearn](https://rolearn.dev/guidance/roblox-devex-guide-requirements-rates/); [GeneralistProgrammer DevEx guide](https://generalistprogrammer.com/tutorials/roblox-devex-guide-how-to-cash-out-robux)

**Program size**
- As of Dec 31, 2025, more than **35,500** creators had qualified and registered, including more than 10,500 new in 2025. More than **23,500** creators were actually paid fiat currency in 2025. — [10-K FY2025](https://www.sec.gov/Archives/edgar/data/1315098/000131509826000024/rblx-20251231.htm)
- More than **42,000** DevEx participants in the 12 months to June 30, 2026. — [Roblox Newsroom, Sept 3, 2026](https://about.roblox.com/newsroom/2026/09/global-impact-of-creation-on-roblox)
- More than **45,000** creators qualified and registered as of Sept 30, 2026. — [Roblox 10-Q Q3 2026](https://www.sec.gov/Archives/edgar/data/0001315098/000162828026068253/rblx-20260930.htm) (from a search-result excerpt of the filing)
- (Older) More than 16,500 registered at the end of 2023 and 11,000 at the end of 2022. — [FY2023 ARS](https://www.sec.gov/Archives/edgar/data/1315098/000155837024004977/rblx-20231231xars.pdf) (search excerpt)

### Inferences
- The minimum cash-out is worth $114 at the standard rate, or $162 if all 30,000 Robux came from qualifying US 18+ spend.
- A 400-Robux game pass pays the creator 280 earned Robux (70%). That is about $1.06 at the standard rate, or about $1.51 at the US 18+ rate. A vendor guide gives the same $1.06 figure. — [GeneralistProgrammer](https://generalistprogrammer.com/tutorials/how-much-do-roblox-game-developers-make-earnings-data)
- An incremental or idle game can qualify for the US 18+ rate by setting avatars to "R15 Only" or by having no visible player characters. The uplift applies only to spend from age-checked US adults, so how much it helps depends on how many such players the game has.
- A developer under 13 can earn Robux but cannot cash out until turning 13. Earned Robux balances aren't stated to expire. That last point is an assumption; Roblox didn't confirm it in any source I read.

### Gaps
- Roblox's own DevEx help pages (FAQ and Terms) returned HTTP 403. I couldn't confirm from primary sources: the ID-verification method, processing time, Tipalti, the tax forms, parental consent for minors, or whether Premium or Plus is still required.
- I couldn't confirm what the "Roblox Plus incentive" for DevEx actually is (the DevForum post calls it "not additive" with the 18+ rate).
- Third-party guides cite a $600 threshold for 1099 reporting. I didn't verify that threshold for tax year 2026.

## 2. Total creator payouts by year (2023–2026) and how earnings are distributed

### Takeaway
DevEx payouts by year:
- **2023:** $740.8M
- **2024:** $922.8M
- **2025:** $1,503.1M (+63%)
- **2026, first nine months:** $1,189M (+16% year over year)

Growth turned negative in Q3 2026, which fell 6% year over year to $403M. Earnings are extremely concentrated. In the 12 months to June 30, 2026 (about $1.7B in DevEx), the top 10 creators averaged about $65.7M each, the top 100 about $10.8M, and the top 1,000 about $1.4M. The **median** among more than 42,000 DevEx participants received only about **$1,500**.

### Cited Findings
**Annual and recent totals**
- **2023:** $740.8M (2022: $623.9M). — [FY2023 ARS](https://www.sec.gov/Archives/edgar/data/1315098/000155837024004977/rblx-20231231xars.pdf). Press coverage reported $741M, up 19%. — [Tubefilter, Feb 21, 2024](https://tubefilter.com/2024/02/21/roblox-pays-creators-741-million-in-2023/); [Bloomberg, Feb 21, 2024](https://www.bloomberg.com/news/articles/2024-02-21/how-much-do-roblox-game-makers-earn-741-million-in-2023)
- **2024:** $922.8M. **2025:** $1,503.1M (+63%). The 10-K credits three drivers: differential Robux pricing (launched November 2024), Creator Rewards (July 2025), and the 8.5% rate increase (Sept 5, 2025). — [10-K FY2025](https://www.sec.gov/Archives/edgar/data/1315098/000131509826000024/rblx-20251231.htm)
- **Q4 2025:** $477M, up 70% year over year. Management said creators earned "over $1.5 billion" in 2025 for the first time. — [Q4 2025 earnings call transcript (Motley Fool), Feb 5, 2026](https://www.fool.com/earnings/call-transcripts/2026/02/05/roblox-rblx-q4-2025-earnings-call-transcript/); [Yahoo Finance](https://finance.yahoo.com/news/roblox-q4-earnings-call-highlights-050828535.html)
- **2026 by quarter:**
  - Q2 2026: $363M (+15%). — [10-Q Q2 2026](https://www.sec.gov/Archives/edgar/data/0001315098/000162828026051082/rblx-20260630.htm) (search excerpt)
  - Q3 2026: **$403M, down 6%** from $428M.
  - Nine-month total: **$1,189M** vs $1,026M a year earlier.
  - DevEx fees were **24% of bookings** in Q3 2026 (22% a year earlier) and 26% of revenue (31% a year earlier). — [Q3 2026 shareholder letter (8-K Ex. 99.1), Oct 30, 2026](https://www.sec.gov/Archives/edgar/data/1315098/000162828026068235/ex991-q32026earningsshar.htm)
- **12 months to June 30, 2026:** about **$1.7B** in DevEx, up about 50% year over year. Cumulative payouts since 2013 exceed **$5B**. — [IBTimes UK, Sept 13, 2026, citing Roblox](https://www.ibtimes.co.uk/roblox-top-creators-devex-payouts-2026-1819403)
- The Roblox newsroom (Sept 3, 2026) says: "In 2025, Roblox creators earned over $1.5 billion" (2024: $923M). — [Roblox Newsroom](https://about.roblox.com/newsroom/2026/09/global-impact-of-creation-on-roblox)

**How earnings are distributed**
- **12 months to June 30, 2026** (figures Roblox presented at RDC 2026):
  - Top 10: about **$65.7M average** (about $657M combined, roughly 39% of the pool)
  - Top 100: about **$10.8M average**
  - Top 1,000: about **$1.4M average**
  - Median: about **$1,500**, across more than 42,000 participants

  — [IBTimes UK](https://www.ibtimes.co.uk/roblox-top-creators-devex-payouts-2026-1819403); [TweakTown](https://www.tweaktown.com/news/113585/robloxs-top-10-creators-averaged-dollars65-7-million-each-while-the-median-made-dollars1500-and-roblox-everywhere-is-the-fix/index.html). Roblox's newsroom independently confirms the median (about $1,500) and the participant count (more than 42,000). — [Roblox Newsroom, Sept 3, 2026](https://about.roblox.com/newsroom/2026/09/global-impact-of-creation-on-roblox)
- **Calendar 2025:** the top 1,000 creators averaged **$1.3M** (+50% year over year). The median DevEx creator got **$1,550** in the 12 months ended Dec 31, 2025. Roblox says "over 35,000" are in DevEx out of "the millions of creators monetizing." — [Creator Hub: Earning on Roblox](https://create.roblox.com/docs/production/earning-on-roblox); [Q4 2025 call](https://www.fool.com/earnings/call-transcripts/2026/02/05/roblox-rblx-q4-2025-earnings-call-transcript/)
- (Earlier report, Sept 2025) The top 10 averaged **$33.9M** and the top 100 **$6M**, up more than 450% and 500% respectively since 2019. — [Roblox Annual Economic Impact Report, Sept 2025](https://about.roblox.com/newsroom/2025/09/roblox-annual-economic-impact-report)
- (Older, 2023)
  - 12,000 developers cashed out.
  - About 3,500 earned at least $10,000; about 750 earned more than $100,000.
  - 100 games each had at least $1M in sales, and 9 developers each had at least $10M in yearly sales.
  - The top 10 games took 30% of all playtime.

  — [Tubefilter, Feb 2024, citing a company filing and Bloomberg](https://tubefilter.com/2024/02/21/roblox-pays-creators-741-million-in-2023/)
- **Who the creators are** (US survey and payout data):
  - 83% of surveyed US creators are individuals rather than established studios.
  - 66% of 2025 US payments (about $444M) went to areas with below-average concentrations of tech workers.
  - US GDP impact in 2025 was $752M (+69%) with 7,525 full-time-equivalent jobs; worldwide, nearly 12,000.

  — [Roblox Newsroom, Sept 3, 2026](https://about.roblox.com/newsroom/2026/09/global-impact-of-creation-on-roblox)
- **Conflicting secondary figures** (I treat the official figures above as authoritative):
  - RoWatcher: top 10 averaged $38.5M (June 2024–July 2025); top 1,000 averaged $980K; 2024 median $1,575. — [RoWatcher](https://rowatcher.com/news/the-roblox-income-ladder-what-developers-really-earn)
  - GeneralistProgrammer (June 24, 2026): top 1,000 about $820K; median about $1,575. — [GeneralistProgrammer](https://generalistprogrammer.com/tutorials/how-much-do-roblox-game-developers-make-earnings-data)

### Inferences
- **Concentration, 12 months to June 2026** (rough, from rounded averages): the top 1,000 took about $1.4B, or about 80% of roughly $1.7B. The top 100 took about $1.08B (about 64%) and the top 10 about 39%. That leaves around $0.3B for the remaining ~41,000 participants: an average of about $7K, with a median of about $1.5K.
- **Concentration, calendar 2025:** the top 1,000 took about $1.3B of $1.5B, or about 87%.
- The median of about $1,500 a year equals roughly 395,000 earned Robux a year at $0.0038, or about 1,080 Robux a day. And that median covers only the creators who reached DevEx. Only about 23,500 creators cashed out at all in 2025, against "millions" who monetize. Reaching the $114 cash-out threshold therefore already puts a creator in a small minority.
- Growth stalled in 2026. After +63% in 2025, Q3 2026 payouts fell 6% year over year even with the higher rates, because platform users and bookings declined (see section 6).

### Gaps
- I found no official 2024–2026 counts of creators above $10K, $100K, or $1M a year. The most recent threshold counts are for 2023, from press reports of a filing.
- No full-year 2026 total exists yet. Q4 2026 results are expected around February 2027.
- TechSpot's article on the RDC 2026 figures returned 403. The RDC 2026 averages for the top 10, 100, and 1,000 come from secondary coverage of Roblox's presentation; Roblox's written newsroom post confirms only the median and the participant count.

## 3. Monetization routes and Roblox's cut of each (including 2025–2026 changes)

### Takeaway
Revenue shares by route:
- **Robux sales inside your game:** creators keep **70%** (game passes, developer products, Robux subscriptions, private servers, Paid Access in Robux).
- **Avatar items:** creators earn **30%** (up to 70% in the Marketplace at high multiples of the price floor). When an item sells inside a game, that game's owner gets 40%.
- **Creator Store:** sales of plugins and models in USD pay **100% of net proceeds**, with only taxes and payment processing deducted.
- **Real-money sales:** "up to 90%."

On top of direct sales, Roblox pays **Creator Rewards**, which replaced Premium Payouts on July 24, 2025, plus Roblox Plus incentives (since Apr 30, 2026) and rewarded-video ad revenue.

Pricing tools launched in 2024–2026: Price Optimization, Regional Pricing, and Managed Pricing.

Across the whole platform, creators received about **24% of every bookings dollar** through DevEx in Q3 2026.

### Cited Findings
**Overall split (official)**
- "Creators generally earn 70% of anything they sell in Robux" in their game, "30% of Marketplace sales," and "up to 90% for things they sell in real money." Models and plugins sold on the Creator Store "earn 100% of net proceeds." — [Creator Hub: Earning on Roblox](https://create.roblox.com/docs/production/earning-on-roblox)
- Product types: game passes (one-time purchase), developer products (can be bought repeatedly, e.g., currency or boosts), subscriptions (monthly, priced in Robux or local currency), private servers (monthly Robux fee, or free), and Paid Access (one-time fee in Robux or local currency). — [Creator Hub: Monetization](https://create.roblox.com/docs/production/monetization)
- DevEx fees equaled 24% of bookings in Q3 2026, up from 22% in Q3 2025. — [Q3 2026 letter](https://www.sec.gov/Archives/edgar/data/1315098/000162828026068235/ex991-q32026earningsshar.htm)

**Creator Rewards (replaced Engagement-Based "Premium" Payouts and the Creator Affiliate program on July 24, 2025)**
- **Daily Engagement:** **5 Robux per qualifying user per day**.
  - The user must be an "Active Spender": at least $9.99 of qualifying purchases (Robux, Premium, or UGC subscriptions) in the past 60 days, and not a new or reactivated user.
  - The user must spend 10+ minutes in your experience, and it must be one of the first three experiences they launch that day.
  - No enrollment is needed.

  — [Creator Hub: Creator Rewards](https://create.roblox.com/docs/en-us/creator-rewards.md)
- **Audience Expansion:** a **35% revenue share on the first $100** a new or reactivated user spends anywhere on Roblox during their first 60 days.
  - The user must arrive through your share link, your direct link, or a search for your experience's name, and play 10+ minutes.
  - The experience must **average 100+ DAU for 60 days**, and the creator needs an ID-verified account in good standing.
  - Limited to one reward per user.

  — [Creator Hub: Creator Rewards](https://create.roblox.com/docs/en-us/creator-rewards.md); [DevForum announcement](https://devforum.roblox.com/t/introducing-creator-rewards-earn-more-by-growing-the-community/3777628)
- Creator Rewards are paid as Earned Robux after a **60-day holding period**. — [Creator Hub: Creator Rewards](https://create.roblox.com/docs/en-us/creator-rewards.md)

**Roblox Plus (launched Apr 30, 2026, $4.99/month; replaced Premium, which had $4.99/$9.99/$19.99 tiers)**
- Roblox pays for the subscriber discounts itself (20% off in-game purchases after three straight months of subscribing), so creators earn the same per purchase.
- Creators earn a bonus for each new subscriber who signs up through a prompt in their game. Tubefilter reports "up to 750 Robux per month for each new signup"; games.gg describes it as 250 Robux a month for each of the subscriber's first three months. The two accounts conflict.
- Paid private servers: up to 100 Robux for each Plus subscriber who spends 60+ minutes in the server over 30 days. Only the 5 servers with the most playtime each month qualify, and Plus subscribers can't be charged for access.
- Tubefilter reports that **a Plus subscription is required to publish or trade avatar items on the Marketplace**.

  — [Tubefilter, Apr 13, 2026](https://www.tubefilter.com/2026/04/13/roblox-plus-creator-payouts/); [games.gg](https://games.gg/news/roblox-plus-subscription-replaces-premium/)
- As of Q3 2026, Plus has "millions of active subscribers." Subscribers average 2x the playtime and spend 7x more Robux than non-subscribers. — [Q3 2026 letter](https://www.sec.gov/Archives/edgar/data/1315098/000162828026068235/ex991-q32026earningsshar.htm)

**Avatar items (UGC)**
- **Sold in an experience:** creator 30%, game owner (affiliate) 40%, Roblox 30%.
- **Sold in the Marketplace:** the creator's share starts at 30% and rises with the price's multiple of the floor: 41% at 1.5x, 50% at 2x, 62% at 3x, and **70% at 6x or more**.
- Commissions are held in a **30-day escrow**.

  — [Creator Hub: Marketplace fees and commissions](https://create.roblox.com/docs/marketplace/marketplace-fees-and-commissions)
- **Upload costs:**
  - Upload fee: 80 Robux per submission (500 if the item uses an emissive mask).
  - Refundable publishing advance, for example: hat 1,500 Robux (13,000 for a paid Limited), body 2,500 (20,000).
  - Creators recover the advance out of Roblox's commission on sales.
- **Limited resale:** reseller 50%, creator 10%, affiliate 10%, Roblox 30%.
- **Account requirement:** uploading avatar items requires **government-ID verification, or a linked parent account that is ID-verified**.

  — [same](https://create.roblox.com/docs/marketplace/marketplace-fees-and-commissions)

**Creator Store (plugins and models sold for USD)**
- **Prices:** plugins $4.99–$249.99; models $2.99–$49.99. USD only, no Robux pricing.
- **Fees:** "100% of net proceeds… bypassing platform fees and DevEx rates." Only taxes and payment processing are deducted.
- **Payouts:** each sale sits in a 30-day escrow, then pays out through Stripe on the 1st of each month. Refunds and chargebacks are deducted from the seller.
- **Seller requirements:** **18+, or 13–17 with a parent or guardian completing the Stripe form**; 2-step verification; residence in a country Stripe supports (Brazil, China, India, and Russia aren't supported yet); individual accounts only, not groups.

  — [Creator Hub: Creator Store](https://create.roblox.com/docs/en-us/production/creator-store.md)
- Roblox announced model sales on the DevForum ("Buy and Sell Models on the Creator Store"). — [DevForum](https://devforum.roblox.com/t/buy-and-sell-models-on-the-creator-store/4142112)

**Ads**
- **Rewarded video:**
  - Opened to more creators in August 2025, then to "all ads eligible creators" on **Feb 18, 2026**.
  - Eligibility per the February 2026 post: a public, unrestricted experience with **more than 2,000 unique monthly visitors**. The same post contradicts itself on whether experiences with AI interaction qualify.
  - Earnings = EPM (earnings per 1,000 impressions) × impressions. A forecast tool is in Creator Hub under Monetization > Ads.
  - Roblox projected rewarded video at up to about 3% of creator earnings in the first months.

  — [DevForum, Feb 2026](https://devforum.roblox.com/t/rewarded-video-ads-are-now-available-to-all-ads-eligible-creators/4063278); [DevForum, Aug 2025](https://devforum.roblox.com/t/more-creators-can-now-use-rewarded-video-ads/3838678) (details from search excerpts)
- In Q3 2026, **more than 20% of games using rewarded video earned over 10% of their in-game earnings from ads**. Skippable pre-roll video ads are planned. — [Q3 2026 letter](https://www.sec.gov/Archives/edgar/data/1315098/000162828026068235/ex991-q32026earningsshar.htm)
- **Immersive ads:** Roblox serves advertisers' image and portal ad units in experiences. No creator payout terms are published on the monetization page. — [Creator Hub: Monetization](https://create.roblox.com/docs/production/monetization)

**Commerce (physical merchandise)**
- Roblox's Commerce APIs, with Shopify as the first partner, were announced in September 2024 and launched first on PC. They let creators sell physical goods inside games. — [Retail Dive](https://www.retaildive.com/news/roblox-shopify-sellers-metaverse-physical-product-purchases/726817)
- I found no published revenue share for physical goods.

**Pricing tools (2024–2026)**
- **Price Optimization** (October 2024): Roblox reports a **median earnings increase of 4%** for eligible creators who ran a pricing test. Eligibility requires 60,000 or more transactions in the past month. — [DevForum: Introducing Price Optimization](https://devforum.roblox.com/t/introducing-price-optimization-find-the-best-prices-for-in-experience-items-and-passes/3186081)
- **Regional Pricing:**
  - Launched April 2025 for in-experience items and passes. In early tests, the share of users who spend rose about 17% in Mexico, 26% in Brazil, and 52% in the Philippines. — [Roblox Newsroom, Apr 2025](https://about.roblox.com/newsroom/2025/04/roblox-launches-regional-pricing-for-in-experience-items); [Tubefilter](https://www.tubefilter.com/2025/04/22/roblox-regional-pricing-in-experience-items/)
  - Later expanded to developer products. Roblox reported a 4–10% average increase in overall Robux spend for games using it. — [DevForum: Regional Pricing for Developer Products](https://devforum.roblox.com/t/introducing-regional-pricing-for-developer-products/3971235) (search excerpt; which Roblox post the 4–10% figure comes from is unclear)
- **Managed Pricing:** an opt-in system that combines regional pricing and price optimization. — [Creator Hub: Monetization](https://create.roblox.com/docs/production/monetization); [DevForum: Managed Pricing](https://devforum.roblox.com/t/managed-pricing-one-system-for-better-pricing-and-earnings-growth/4684738)

### Inferences
- The likely revenue mix for an idle or incremental game:
  - developer products (boosts, currency packs, rebirth skips)
  - game passes (multipliers, auto-collect)
  - private servers
  - Creator Rewards, which reward daily return visits by engaged spenders
  - rewarded-video "watch for boost" ads, once the game passes 2,000 monthly unique visitors
  - the US 18+ rate on passes and products
- Creator Rewards are small per user. 1,000 qualifying spender-days earn 5,000 Robux, about $19. Audience Expansion can pay up to $35 (35% of $100) per new or returning spender you bring in, but only once the game averages 100+ DAU.
- The Creator Store is the one route where Luau skills earn USD directly, with no platform fee and no DevEx conversion. A hobbyist could sell plugins at $4.99–$249.99 or models at $2.99–$49.99. Under-18 sellers need a parent to complete onboarding.
- Roblox's effective take is large. In-game Robux sales lose 30% to Roblox, and the fixed DevEx rate sits well below what players pay for Robux. Overall, creators received about 24 cents per bookings dollar in Q3 2026.

### Gaps
- **Paid Access in real currency:** I couldn't verify the current revenue share beyond Creator Hub's "up to 90%." Coverage from September 2024 described tiered shares, but I couldn't confirm them.
- **Not found:** the commerce revenue share and eligibility rules; an official rewarded-video EPM; immersive-ad payout rates.
- **Plus:** the exact sign-up bonus and whether the official docs require Plus to publish UGC. The official fees page I read mentions Plus or Premium only for reselling Limiteds.

## 4. Discovery and success factors for small developers

### Takeaway
Roblox's "Recommended for You" ranking uses **per-user averages**, so a game isn't penalized for being small. The signals listed as "Most important" are:
- **play-through rate**
- **first-play bounce rate** (under 60 seconds and 61–180 seconds)
- **play days per user** (day 1, days 2–7, days 8–28)
- **playtime per user** (capped at 60 minutes a day)

Since June 2026, ranking has measured retention over 28 days instead of 7.

New games can break out: about 40% of the weekly top 100 by recommendation impressions were less than three months old in Q3 2026. But the odds of real income are slim. The median DevEx participant earns about $1,500 a year, and most monetizing creators never reach DevEx at all. More than 70% of top-100 games buy Sponsored Ads.

### Cited Findings
- **Official ranking signals:**
  - Most important: play-through rate ("the rate at which users play your game after seeing it in the Recommended for You sort"); first-play bounce rate (a negative signal, measured under 60 seconds and at 61–180 seconds); play days per user (day-1, days 2–7, and days 8–28 averages); and playtime per user (capped at 60 minutes per user, per game, per day).
  - Important: intentional co-play days, qualified play sessions, spend days per user, and Robux spent per user.
  - Signals are per-user averages, "so smaller games with engaged users aren't disadvantaged," and count only users who arrived organically from Recommended for You.
  - Games enter through "explore and expand" phases. Even a small number of players can signal that a game deserves wider distribution. Traffic from ads, search, social media, and similar sources can speed up consideration.
  - A **custom thumbnail is required** to get Home recommendations. Giveaway-led games, games with mismatched metadata, and non-unique games get less exposure.

  — [Creator Hub: Discovery](https://create.roblox.com/docs/en-us/discovery.md)
- **June 2026 algorithm change:** on June 15, 2026, Roblox dropped "qualified play-through rate," added play-through rate and first-play bounce rate, and moved Recommended for You from a 7-day to a **28-day** retention view. — [Dubit](https://dubit.io/library/what-makes-a-new-roblox-game-take-off). The Q2 2026 shareholder letter lists play-through rate, first-play bounce rate, spend days, and Robux spent per user, and reports a lift to long-term retention. — [Q2 2026 letter](https://www.sec.gov/Archives/edgar/data/0001315098/000162828026051059/ex991-robloxq22026earnin.htm) (search excerpt)
- **Q3 2026:**
  - Recommended for You now uses age-cohort data.
  - About **40% of the weekly Recommended for You top 100** (by impressions) were created in the last three months.
  - **More than 70% of the top 100 games** (by Robux spent) ran Sponsored Ads.
  - US adult (18+) users are 37% of US age-checked DAUs and monetize "50%+" more than under-18 users.

  — [Q3 2026 letter](https://www.sec.gov/Archives/edgar/data/1315098/000162828026068235/ex991-q32026earningsshar.htm)
- In August 2026, 28% of the top 100 games by hours, and 33% of the top 1,000, had launched within the previous 90 days. — [IBTimes UK, Sept 2026](https://www.ibtimes.co.uk/roblox-top-creators-devex-payouts-2026-1819403)
- **AI-built competition:**
  - Roblox's "Build" prompt-to-game tool had more than 500,000 users and more than 70,000 published games during its alpha (New Zealand, Singapore, Serbia, Thailand). It will have a free base tier and paid tiers, with a broader rollout planned.
  - The number of games published with AI grew more than 50% quarter over quarter.

  — [Q3 2026 letter](https://www.sec.gov/Archives/edgar/data/1315098/000162828026068235/ex991-q32026earningsshar.htm)
- **Documented hits (no official revenue figures):**
  - *Grow a Garden* (an idle-style farming game): launched March 2025. Its first version was **reportedly built by a 16-year-old in about three days** before a team expanded it. It passed 20M concurrent players.
  - *Steal a Brainrot*: launched May 2025 and passed 20M concurrent players in August 2025.
  - Roblox does not link its top-10 payouts to specific games.

  — [IBTimes UK](https://www.ibtimes.co.uk/roblox-top-creators-devex-payouts-2026-1819403)
  - **Third-party estimates only:** Grow a Garden "an estimated $12 million in one month" (May 2025, unsourced). — [RoWatcher](https://rowatcher.com/news/the-roblox-income-ladder-what-developers-really-earn). Steal a Brainrot "$1.4M to $4.4M a month." — [Grey Journal](https://greyjournal.net/hustle/how-much-does-steal-a-brainrot-make/)
- **Small-game benchmarks** (mostly author estimates; the developer-reported examples come from unlinked DevForum posts):

  | Game size and monetization | Robux | USD | Type |
  |---|---|---|---|
  | 100 CCU, "decently monetized" | 50,000–150,000/yr | ~$190–$570/yr | Estimate |
  | 100 CCU, strong monetization | | ~$1,000–$1,500/yr | Estimate |
  | 60–78 average CCU, direct sales only | ~25,000/yr | | Developer-reported |
  | Same game, including Creator Rewards | ~75,000/yr | | Developer-reported |
  | 500–1,000 CCU, poorly monetized (passes only) | 1,000–1,250/day | | Developer-reported |
  | 1,000 CCU, well-designed simulator or tycoon | 50,000–100,000+/day | | Estimate |

  — [RoWatcher](https://rowatcher.com/news/the-roblox-income-ladder-what-developers-really-earn). Two of the article's own Robux-to-USD conversions don't add up, so treat it with caution.
- Author tiers from a vendor guide dated June 24, 2026: the "long tail" earns $0; hobbyists $100–$5,000 a year; mid-tier $10K–$250K; top earners $500K–$30M+. The guide calls these "orders of magnitude, not guarantees." — [GeneralistProgrammer](https://generalistprogrammer.com/tutorials/how-much-do-roblox-game-developers-make-earnings-data)
- 83% of surveyed US creators are individuals. — [Roblox Newsroom, Sept 2026](https://about.roblox.com/newsroom/2026/09/global-impact-of-creation-on-roblox)

### Inferences
- Idle and incremental games fit the "play days per user" signal well, because their reasons to come back (offline progress, daily rewards) drive day 2–7 and day 8–28 returns. But first-play bounce in the first 60–180 seconds is a "most important" signal, so onboarding has to hook players almost immediately. Playtime above 60 minutes a day doesn't count toward ranking, so long AFK sessions don't help discovery. (Interpretation of the official signal list.)
- Organic recommendations need an initial cohort. Small developers typically seed one through Sponsored Ads, share links (which can also earn Audience Expansion Rewards), and social media.
- Discovery turns over fast (28–40% of top games are under three months old), and AI tools make building faster. Both lower the barrier to a hit and raise competition and churn. A small-team breakout is possible, as Grow a Garden showed, but it is a long-tail outcome.
- Odds: the most defensible expectation for a hobbyist game is somewhere between $0 and a few thousand dollars a year. Most monetizing creators never reach the $114 DevEx threshold. Reaching it puts you near the median of about $1,500.

### Gaps
- I found no Ads Manager pricing (CPC or CPM) or details on ad credits.
- I found no verifiable post-mortems from small incremental or idle developers with audited revenue. The DevForum examples above are unlinked or secondhand.
- I found no data on typical hours invested before a game earns money, beyond anecdotes like Grow a Garden's three days.
- Roblox doesn't officially disclose revenue for named hits.

## 5. Freelance and commission work for Roblox scripters and builders

### Takeaway
Talent Hub (Roblox's official board for finding collaborators and jobs) and the DevForum remain the main official places to find work. No 2026 changes surfaced. No official rate data exists. Vendor guides put newer scripters at about **$10–$35/hour**, experienced developers with live-game credits at about **$25–$60/hour**, and senior systems engineers with shipped titles at **$50–$150+/hour**. Per-job pricing runs from **$50–$250 for a single feature** to **$1,000–$10,000 for a full backend**. Many DevForum posts pay in Robux, which is worth very little in cash (1,800 Robux ≈ $6.84 at the DevEx rate).

### Cited Findings
- Roblox's Help Center describes Talent Hub as a place where creators "can find other people to work with, hire someone for their team, or search for jobs related to their skills," and publishes parental guidance for it. — [Roblox Help: Parental guidance on Talent Hub](https://en.help.roblox.com/hc/en-us/articles/4404630280980-Parental-guidance-on-Talent-Hub) (search excerpt; the page itself wasn't fetched)
- **Freelance rates (vendor and third-party estimates):**
  - BLOXG: newer scripters with no live games charge $10–$25/hour; experienced developers with live-game credits $25–$60/hour; the overall range is $10–$120/hour. Most work is priced per job: $50–$250 for a well-scoped feature, $1,000–$10,000 for a full backend (saving, monetization, anti-exploit). — [BLOXG](https://bloxg.com/blog/how-much-to-pay-a-roblox-developer)
  - Roblox DevMatch: junior $20–$35/hour, mid-level $35–$60/hour, experts $100–$150+/hour. — [Roblox DevMatch](https://robloxdevmatch.com/blog/how-to-hire-roblox-scripters)
  - Game-Ace: a single-role Talent Hub freelancer charges about $15–$60/hour; agencies recruiting through the DevForum or Clutch charge $25–$80/hour; senior systems engineers with shipped titles $50–$120+/hour. — [Game-Ace](https://game-ace.com/blog/how-to-hire-the-best-roblox-game-developer/)
- **Actual postings:**
  - A DevForum post titled "Hiring Roblox Scripter – 1800 Robux per task." — [DevForum](https://devforum.roblox.com/t/hiring-roblox-scripter-%E2%80%93-1800-robux-per-task/4438381)
  - A full-time Roblox Studio scripter job at $1,500 a month (August 2024, older). — [Freelancer.com](https://www.freelancer.com/projects/roblox/roblox-studio-scripter-full-time)
  - A posting offering $4/hour. — [OnlineJobs.ph](https://www.onlinejobs.ph/jobseekers/job/Full-Time-Roblox-DeveloperScripter-1410439)
- **Salaries:** a vendor guide cites ZipRecruiter's average for a "Roblox developer" at about $110,000 a year ($52.84/hour), and its own table puts US in-house Luau or systems work at $45–$75/hour. — [Innovecs Games, 2026](https://www.innovecsgames.com/blog/roblox-game-developers-for-hire/)
- Roblox Corporation itself hires full-time "Software Engineer, Game Developer" roles in its Creator group, on a rolling basis (2026 post). — [DevForum](https://devforum.roblox.com/t/2026-software-engineer-game-developer-applications-now-open/4632709)

### Inferences
- Robux-denominated commissions pay very little in cash. 1,800 Robux is worth about $6.84 at $0.0038, and you can't cash out at all until your balance reaches 30,000 Robux. A hobbyist freelancer should prefer USD contracts paid through a platform with escrow.
- For a capable Luau scripter, freelance commissions at roughly $15–$40/hour probably produce more predictable side income than a typical game, given the roughly $1,500 median DevEx payout. But the rate data comes from vendors with an interest in the numbers.
- From what the vendors describe, studios hire on shipped credits: live games with player counts, systems work like DataStores, monetization, and anti-exploit, plus a portfolio on Talent Hub or the DevForum. This comes from vendor descriptions, not studio data.

### Gaps
- I found no official or survey-based data on Roblox freelance rates, and no reliable salary data for specific Roblox studios such as Gamefam or Super League.
- Talent Hub's 2026 status, usage numbers, and minimum age weren't confirmed beyond the Help Center's parental-guidance page.

## 6. Risks: policy churn, moderation, age rules for young developers, and single-platform dependence

### Takeaway
The creator economy changed rules repeatedly in 2025–2026:
- Creator Rewards replaced Premium Payouts.
- The DevEx rate rose twice.
- Plus replaced Premium.
- Age checks became mandatory for chat.
- New publishing requirements gate younger audiences.
- Discovery signals changed.

The platform also shrank in Q3 2026: DAU fell 9%, bookings 12%, and DevEx payouts 6% year over year. Q4 2026 bookings guidance is −10% to −15%.

Young developers face these limits: DevEx requires age 13+; selling on the Creator Store requires age 18+, or 13–17 with a parent; uploading avatar items requires a government ID or an ID-verified linked parent account; and creators under 18 must pass a facial age check to publish to Kids or Select audiences.

### Cited Findings
**Platform decline in 2026**
- Q3 2026, all year over year:
  - DAUs 138M (−9%)
  - hours engaged about 34B (−15%)
  - bookings $1,697M (−12%)
  - monthly unique payers 30M (−16%)
  - DevEx $403M (−6%)

  Q4 2026 guidance is bookings of $1,890M–$2,000M (−10% to −15%). — [Q3 2026 letter](https://www.sec.gov/Archives/edgar/data/1315098/000162828026068235/ex991-q32026earningsshar.htm). Investing.com described it as the "first user decline." — [Investing.com](https://www.investing.com/news/company-news/roblox-q3-2026-slides-first-user-decline-marks-inflection-point-93CH-4985385)
- "Beginning in January 2026, we implemented mandatory age-check systems in all chat-enabled regions." These safety changes "have and may continue to impact engagement, retention, revenue, and bookings." — [10-K FY2025](https://www.sec.gov/Archives/edgar/data/1315098/000131509826000024/rblx-20251231.htm). By the end of Q3 2026, 64% of global DAUs had completed an age check (US 75%). — [Q3 2026 letter](https://www.sec.gov/Archives/edgar/data/1315098/000162828026068235/ex991-q32026earningsshar.htm)

**Policy changes, 2025–2026**
- July 24, 2025: Creator Rewards replaced Engagement-Based (Premium) Payouts. — [Creator Hub: Creator Rewards](https://create.roblox.com/docs/en-us/creator-rewards.md)
- Sept 5, 2025: DevEx +8.5%. — [10-K FY2025](https://www.sec.gov/Archives/edgar/data/1315098/000131509826000024/rblx-20251231.htm)
- Apr 30, 2026: Plus replaced Premium. — [Tubefilter](https://www.tubefilter.com/2026/04/13/roblox-plus-creator-payouts/)
- June 8, 2026: the US 18+ DevEx rate took effect, with an R15 requirement. Roblox can remove eligibility. — [DevForum](https://devforum.roblox.com/t/introducing-the-us-18-devex-rate-earn-42-more-on-spend-from-18-us-players/4607091)
- June 15, 2026: discovery signals changed. — [Dubit](https://dubit.io/library/what-makes-a-new-roblox-game-take-off)

**New publishing requirements: Roblox Kids (ages 5–8), Roblox Select (ages 9–15), and Roblox (age-checked 16+)**
- **To reach the 16+ audience:** an account in good standing, at least 2 days old, and an age check.
- **To reach Kids and Select audiences, a creator needs all of the following:**
  - good standing
  - **facial age estimation if under 18, or a government ID if 18+**
  - two-factor authentication
  - a Content Ratings Questionnaire result of Minimal, Mild, or Moderate (9+)
  - *either* a one-time refundable fee *or* a Plus or Premium subscription held for 2 consecutive months
  - a passed evaluation
- **The evaluation:** the game first runs only for age-checked 16+ users and needs **250 unique plays by highly engaged age-checked players within 60 days**.
- **Expedited review:** 50,000 Robux (refundable).
- **Fee refunds:** the fee comes back 90 days after the game becomes eligible, but not if the game is permanently moderated.

  — [Creator Hub: Roblox Kids and Select](https://create.roblox.com/docs/production/publishing/kids-and-select)
- **Search excerpts of DevForum posts add:**
  - The publishing fee is 1,000 Robux per game.
  - Rollout began May 19, 2026, in New Zealand, the Netherlands, Australia, and Indonesia, then went global in early June 2026.
  - Users under 17 without a government ID can meet ID requirements by linking a parent account.
  - Games with fewer than 100 highly engaged players over 60 days can lose Kids/Select eligibility. That threshold differs from the official 250-play evaluation threshold.

  — [DevForum: New Publishing Requirements](https://devforum.roblox.com/t/new-publishing-requirements-evaluation-process-for-games/4573166); [DevForum: Alternate Publishing Requirements](https://devforum.roblox.com/t/alternate-publishing-requirements-for-roblox-kids-and-select/4630944)

**Age-specific rules for young developers**
- DevEx: 13+. — [Creator Hub](https://create.roblox.com/docs/production/earning-on-roblox)
- Creator Store sellers: 18+, or 13–17 with a parent or guardian (18+) who agrees to the terms and provides their information to Stripe. Anyone sharing assets on the Creator Store must pass an age check or government-ID verification; phone verification doesn't count. — [Creator Hub: Creator Store](https://create.roblox.com/docs/en-us/production/creator-store.md)
- Avatar items: government-ID verification, or a linked parent account with government-ID verification. — [Marketplace fees](https://create.roblox.com/docs/marketplace/marketplace-fees-and-commissions)
- Audience Expansion Rewards: an ID-verified account. — [Creator Rewards](https://create.roblox.com/docs/en-us/creator-rewards.md)

**Holds, clawbacks, and moderation**
- Creator Rewards carry a 60-day hold. — [Creator Rewards](https://create.roblox.com/docs/en-us/creator-rewards.md)
- Avatar items and Creator Store sales carry a 30-day escrow.
- On the Creator Store, refunds and chargebacks are deducted from the seller. Payouts are frozen if a large share of an asset's sales comes from accounts with chargeback histories. Sellers also reimburse buyers if an asset is moderated after purchase and the appeal fails. — [Creator Store](https://create.roblox.com/docs/en-us/production/creator-store.md)
- Chargebacks and refunds were about 2.5% of bookings in 2025. — [10-K FY2025](https://www.sec.gov/Archives/edgar/data/1315098/000131509826000024/rblx-20251231.htm)
- Games with reduced exposure get a banner in Creator Dashboard. — [Discovery](https://create.roblox.com/docs/en-us/discovery.md)

**Single-platform dependence**
- In its 10-K, Roblox warns that creators "may shift their resources to developing content on other platforms," and it lists regulation of Robux as a security as a forward-looking risk. — [10-K FY2025](https://www.sec.gov/Archives/edgar/data/1315098/000131509826000024/rblx-20251231.htm)
- "Roblox Everywhere" will let creators self-publish standalone games to app stores. Its first phase, for select top games, is expected in the first half of 2027. — [Q3 2026 letter](https://www.sec.gov/Archives/edgar/data/1315098/000162828026068235/ex991-q32026earningsshar.htm)

### Inferences
- Income from Roblox depends on rules Roblox can change unilaterally: payout formulas, exchange rates, discovery signals, and audience gates. It changed most of them within 18 months.
- The platform's contraction in 2026 also means a shrinking pool of payers: −16% unique payers in Q3 2026.
- Incremental and idle games often target younger players. Under the 2026 rules, a new game first reaches only age-checked 16+ users until it passes the 250-play evaluation, or until the creator pays the expedited-review fee. That may slow early growth for kid-oriented games, while the 18+ DevEx rate rewards an adult audience.
- For a minor, the practical sequence is:
  - **Under 13:** can build and publish, but can't cash out.
  - **13–17:** can use DevEx, and can sell on the Creator Store or upload UGC with a parent involved (Stripe consent, or a linked ID-verified parent account).
  - **18+:** no restrictions beyond government-ID verification.

### Gaps
- I couldn't access Roblox's Terms of Use and DevEx Terms (403), so I couldn't confirm parental consent requirements for DevEx under 18, or any under-13 rules for publishing to 16+ audiences.
- A search excerpt mentions a docs table requiring parent approval for creators under 9. I didn't verify it.
- I found no data on how often small games are moderated or demonetized.
