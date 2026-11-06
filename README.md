# Ticker Royale v2

Free trading battles on the Robinhood Chain testnet (vibe/vibe). Players trade live BTC / ETH / SOL / NVDA / AAPL / TSLA
prices (Pyth Network) with $1,000 of virtual money and win **your token**.

| Mode | Seats | Length | Rules | Prize |
|---|---|---|---|---|
| Battle Royale | 10 | 10 min | Bottom 30% cut every 2 min. 10 prize games per day (UTC) | 100 / 50 / 25 |
| Spin & Go | 3 | 5 min | Out if you drop 15%. Prize spun before the match | 25 / 50 / 100 / 250 / 1,000 (winner takes all) |
| 1v1 Duel | 2 | 5 min | Highest account value wins | 20 |
| Practice | 12 | 5 min | Solo vs bots | none |

**Matchmaking:** a player taps Join and waits 1 minute. Anyone who joins in that time plays together, and **aggressive bots**
fill the empty seats. Bots come from a shared random seed, so every player in a match sees the same bots doing the same things.

**Token utilities included**
- **Game prizes:** above, with daily caps per player (5 Spin wins, 10 Duel wins) so nobody farms the bots all day.
- **Daily quests:** play 3 battles (+10), win a duel (+15), make the top 3 in a Battle Royale (+20), daily streak (+5 × days, up to 7).
- **Referrals:** each player gets a `?ref=` link. When a friend finishes their first battle, both get +25.
- **Staking:** `contracts/TickerStaking.sol` pays a fixed APR. Staking ≥ 1,000 gives +25% on every game prize and a ⭐ badge.
- **Trading competition:** the Compete tab ranks wallets by buy and sell volume of your token on vibe.fun, read from the explorer.

All the numbers are at the top of the `<script>` in `index.html` (`MODES`, `QUESTS`, `SPIN_TABLE`, `CONFIG`).

---

## Setup

### 1. Database (Supabase)
1. supabase.com → New project → **SQL Editor** → paste `supabase.sql` → Run.
2. Settings → API: copy the **Project URL** and **anon public key** into `CONFIG` in `index.html`.

Without Supabase the site still works in **demo mode**: you play against bots only and tokens are saved in your browser.

### 2. Token details
In `CONFIG`, set `TOKEN_SYMBOL`, `TOKEN_ADDRESS` (your vibe.fun token), and `VIBE_TRADE_URL` (its trade page).

### 3. Staking contract (optional, ~10 min)
1. Open remix.ethereum.org → new file → paste `contracts/TickerStaking.sol`.
2. Compile with Solidity 0.8.20+.
3. Deploy → Environment: **Injected Provider** (your wallet on Robinhood Chain testnet, chain 46630).
   Constructor: `_token` = your token address, `_aprBps` = `2000` (20% APR).
4. Send reward tokens to the contract address. That's the reward pool.
5. Put the contract address into `CONFIG.STAKING_ADDRESS`.

### 4. Trading competition
Set `COMP_START`, `COMP_END` and `COMP_PRIZES` in `CONFIG`. The leaderboard updates itself from the Robinhood testnet explorer.
When it ends, screenshot the board and pay the winners in the same airdrop.

### 5. Publish
Drag the folder onto **app.netlify.com/drop**.

---

## Paying out (manual airdrop)

1. Open `your-site.netlify.app/?admin=1` → **Ranks** tab → **Copy CSV**. That gives you the unpaid tokens per wallet.
   (Or run the airdrop query at the bottom of `supabase.sql`.)
2. Send the tokens with a multisender, or one by one.
3. Run the `update rewards set paid = true …` line from `supabase.sql` so nobody is paid twice.

Players who haven't added a wallet keep their tokens until they add one.

## Known limits (fine for testnet)
- Scores and claims are calculated in each player's browser, so a skilled cheater could fake wins.
  Check the airdrop list before paying (e.g. hundreds of wins in a day is suspicious). For mainnet or real value, move scoring to a server.
- The database is open to anyone holding the anon key (testnet setting).
- Stocks only move in US market hours. Crypto trades 24/7.
- The daily quests and limits reset at 00:00 UTC (6:00 AM in Dhaka).
