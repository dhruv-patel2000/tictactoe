# TicTacToe — Feature Documentation

A cross‑platform **Flutter** Tic‑Tac‑Toe game with offline AI play, local pass‑and‑play, and real‑money‑style **coin‑staked online multiplayer**. Backed by **Firebase** (Auth, Realtime Database, Storage, App Check) and built on the **BLoC** state‑management pattern.

- **App name:** TicTacToe (`tic_tac_toe`)
- **Flutter SDK:** `^3.6.0`
- **Orientation:** Portrait only
- **Mascot:** *Dora*, the clever fox (the AI opponent and brand character)

---

## Table of Contents

1. [High‑Level Overview](#1-high-level-overview)
2. [Authentication & Onboarding](#2-authentication--onboarding)
3. [Home & Navigation](#3-home--navigation)
4. [Game Modes](#4-game-modes)
5. [Core Game Engine](#5-core-game-engine)
6. [Board Sizes, Rounds & Turn Timer](#6-board-sizes-rounds--turn-timer)
7. [Online Multiplayer & Matchmaking](#7-online-multiplayer--matchmaking)
8. [Coin Economy](#8-coin-economy)
9. [Leaderboard & Ranking](#9-leaderboard--ranking)
10. [Match History](#10-match-history)
11. [Skins](#11-skins)
12. [Shop](#12-shop)
13. [More Games (WebView)](#13-more-games-webview)
14. [Settings & Profile](#14-settings--profile)
15. [Architecture & Tech Stack](#15-architecture--tech-stack)
16. [Data Model Reference](#16-data-model-reference)
17. [Configuration Reference](#17-configuration-reference)

---

## 1. High‑Level Overview

TicTacToe is a competitive twist on classic Tic‑Tac‑Toe. Beyond the standard 3×3 grid, players can choose larger **4×4** and **5×5** boards and play best‑of multi‑round matches. The app supports three ways to play:

| Mode | Opponent | Network | Stakes |
|------|----------|---------|--------|
| **Offline Play** | Dora AI | Local | None |
| **Pass N Play** | Local friend | Local | None |
| **Random Play** | Real player (matchmade) | Online (Firebase RTDB) | Coins (2× pot) |

A persistent **coin economy** underpins online play: players stake coins to enter a match, the winner takes the pot (2× the entry fee), and a draw returns each player's stake. Progress is tracked through a global **leaderboard**, per‑user **match history**, unlockable **skins**, and a **coin shop**.

---

## 2. Authentication & Onboarding

**Entry flow:** Splash Screen → (if not signed in) Auth Options → Home.

### Sign‑in methods (`auth_options_screen.dart`)

The Auth Options screen offers three ways in:

1. **Sign in with Google** — Firebase Google OAuth (`google_sign_in`).
2. **Play as a Guest** — anonymous Firebase session for instant play.
3. **Sign in with Email** — email/password, with dedicated **Login** and **Sign‑up** screens and a **Forgot Password** dialog.

> Apple Sign‑In support is wired into the codebase (`sign_in_with_apple`, `apple_login.dart`) for iOS.

The login layer is abstracted behind a `Login` interface (`login.dart`) with concrete implementations per provider (`google_login.dart`, `apple_login.dart`, `email_login.dart`, `guest_login.dart`), all coordinated by the **`AuthenticationBloc`**.

### Account provisioning

- On first login, a `UserModel` is created in the Realtime Database under `users/{uid}` with a **starting balance of 500 coins**, a default profile picture, and the **DORA Classic** skin assigned.
- **Email is never stored** in the database — it is re‑attached at runtime from Firebase Auth.
- The current user node is kept synced locally (`keepSynced(true)`) so balance and stats are available offline and update live.

### App security

- **Firebase App Check** is activated at startup (Play Integrity on Android, App Attest on iOS; debug providers in debug builds) to protect backend resources from abuse.

---

## 3. Home & Navigation

The **Home screen** (`home_screen.dart`) is the hub. Its app bar shows:

- **Profile avatar** → opens Settings.
- **Coin balance** — live, formatted compactly (e.g. `1.2K`) via a `watch` on the `AuthenticationBloc`.
- **Leaderboard shortcut** → opens the Leaderboard.

The body presents the three **game‑mode cards**:

1. **Offline Play** — "Play with The Clever Fox Dora"
2. **Random Play** — "Find your Match Around the World"
3. **Pass N Play** — "Pass N Play With your Friend"

Selecting a mode opens a sequence of selection dialogs (rounds, board size, and—for online—entry fee) before launching the game.

Routing is centralized in `AppRoutes` (`routes.dart`) using a custom `GradientRouter` page transition.

---

## 4. Game Modes

All three modes share the same abstract `Game` engine (see [§5](#5-core-game-engine)) and differ only in how opponents and moves are handled.

### 4.1 Offline Play (vs. Dora AI) — `offline_game.dart`

- The human is **"You"**; the AI opponent is **"Dora"**.
- The starting player is decided by a random coin toss. If Dora wins the toss she opens automatically.
- Dora "thinks" for a randomized short delay (up to ~9 seconds) before moving, for a natural feel.
- **Selection flow:** choose number of rounds → choose board size.

### 4.2 Pass N Play (local two‑player) — `pass_n_play.dart`

- Two humans share one device ("User1" / "User2"), alternating turns.
- `restrictedMoves` is **false** — both sides may freely tap the board (no AI/network lock).
- **Selection flow:** choose board size.

### 4.3 Random Play (online multiplayer) — `multiplayer_game.dart`

- Matchmade against a real opponent over Firebase Realtime Database.
- Coin‑staked: winner earns **2× the entry fee**.
- **Selection flow:** choose entry fee → choose number of rounds → choose board size → matchmaking (Connection screen). See [§7](#7-online-multiplayer--matchmaking).

---

## 5. Core Game Engine

The abstract `Game` class (`core/game_logic/game.dart`) implements all shared rules; each mode subclasses it.

### Responsibilities

- **Board generation** — an `N×N` grid of `GamePosition` cells.
- **Win detection** (`checkWin`) — evaluates **rows, columns, and both diagonals**. A win on any full line of one player's marks fires a `GameOverEvent` carrying the winning row/column and diagonal direction (`main` or `anti`) so the UI can draw the winning line. A full board with no winner fires a `GameDrawEvent`.
- **Turn management** (`setNextPlayer`) — alternates the current player and resets/starts the per‑turn countdown.
- **Lifecycle hooks** — `onGameStart`, `onUpdate`, `onGameOver`, `onGameDraw`, `onDispose` are overridden per mode.
- **Multi‑round support** (`setNextRound`) — regenerates the board for the next round.

### The Dora AI (`dora_ai.dart`)

A fast, heuristic (non‑minimax) opponent that picks moves by priority:

1. **Win** — complete any line where the AI has `N‑1` marks.
2. **Block** — stop the opponent from completing a line.
3. **Take center** — on odd‑sized boards.
4. **Strategic positions** — corners first, then edge midpoints.
5. **Random** — any remaining empty cell.

This scales to 3×3, 4×4, and 5×5 boards.

### Game UI (`screens/game/`)

- **Maze screen** — the live game board.
- **Tile widgets**, animated **winning‑line** drawing (`line_animation.dart`), **neon borders**, and **dashed avatars**.
- **Dialogs** — Game Over, Draw, and Next Round.
- **Player profiles** showing both players, their avatars, and active skins.

---

## 6. Board Sizes, Rounds & Turn Timer

### Board sizes (`AppSettings.matrixSizes`)

| Size | Label |
|------|-------|
| 3×3 | Classic Mode |
| 4×4 | Advanced Mode |
| 5×5 | Expert Mode |

### Rounds (`AppSettings.rounds`)

Matches can be **best‑of 1, 3, 5, or 7** rounds. Rounds are tracked via `currentRound` / `rounds`; in multiplayer the round advances in the database and both clients sync.

### Per‑turn countdown (`AppSettings.turnDurationFor`)

Each turn is time‑limited, scaling with board size (larger boards need more thinking time):

- 3×3 → **20 s**
- 4×4 → **30 s**
- 5×5 → **40 s**

(Base 20 s + 10 s per size step above classic.) The clock resets at every turn change; multiplayer also resets it from the database's `current_turn` listener.

---

## 7. Online Multiplayer & Matchmaking

### Connection / matchmaking (`connection_screen.dart` + `GameConnectionBloc`)

1. The player's **stake is escrowed** (debited) before any lobby action.
2. The app searches for an existing **waiting** game that matches **all three settings** — same entry fee, same number of rounds, and same board size. Players are never paired into mismatched games.
3. **If a match is found** → the player joins as Player 2; the game flips from `waiting` to `inProgress` atomically with the `player2` write.
4. **If none is found** → the player **hosts** a new waiting game and shows a countdown timer (default **60 s**, `multiplayerConnectionSearchTime`).
5. On a successful pairing, both clients navigate into the Maze screen as a `MultiplayerGame`.

### Live sync (`multiplayer_game.dart`)

The active game listens to the Firebase game node and reacts to changes:

- **`board`** — opponent's move replaces the local board.
- **`current_turn`** — switches the active player and resets the clock.
- **`current_round`** — advances to the next round.
- **`result`** — settles the game (win/draw), guarded so a client doesn't re‑process its own result echo (no duplicate end dialogs).

### Cleanup & integrity (`firebase_service.dart`)

- **Timeout / back‑out:** if no opponent joins before the timer expires, or the host leaves the waiting screen, the hosted game is **closed** so it can't be joined as a "ghost."
- The `waiting → closed` flip is a **transaction**, so only the first caller wins and refunds the stake — the timer and the manual back‑out can never **double‑refund**.
- If creating/joining fails after the debit, the stake is **refunded**.

---

## 8. Coin Economy

The coin system (`DatabaseService`, `core/services/firebase_service.dart`) is built for correctness under concurrency.

### Principles

- **Starting balance:** 500 coins for new accounts.
- **Atomic transactions:** every balance change (`debitCoins` / `creditCoins`) runs as a Firebase transaction so concurrent writes (a settling match, an ad reward, another debit) can never clobber each other.
- **Escrow model:** a player's stake is debited the moment they enter a lobby and only released on settlement — the pot can never be spent twice or lost to an error.
- **`debitCoins`** aborts (returns `false`, changes nothing) when the balance can't cover the amount → surfaced as a "not enough coins" message.

### Settlement & payout (`setGameResult`)

Because both clients detect game‑over, the **result is claimed via a transaction** on the `result` node — whichever client writes first past `notDeclared` wins the claim and is the **only** one that runs the payout. The pot is therefore paid **exactly once**.

| Outcome | Winner | Loser |
|---------|--------|-------|
| **Win** | +2× entry fee (net +fee) | nothing (net −fee) |
| **Draw** | each player's stake returned (net 0) | — |

The same single claimer also writes **both players'** stats and history records.

---

## 9. Leaderboard & Ranking

A global ranking of players (`leaderboard_screen.dart`, `leaderboard_repository.dart`, `leaderboard_ranking.dart`).

### Scoring (`AppSettings`)

Applied once per finished match at settlement:

- **Win:** +10 score
- **Draw:** +5 score
- **Loss:** +0 score
- `matchplayed` always increments; `matchwon` increments for the winner.

### Ordering & tiebreak (`leaderboard_ranking.dart`)

- Players are ordered by **score first**, then by **who joined earlier** (`createdAt`) when scores tie.
- Both are packed into a single sortable **`rankKey`** (`score * 4e9 − createdAtSeconds`), so Firebase can **order and limit server‑side** with one `orderByChild` — a player's own rank is read with a bounded query instead of downloading every user.
- `rankKey` is rewritten alongside `score` on every stat update; legacy users without one are **backfilled** from their Firebase Auth account‑creation time.
- Ranking logic is **pure and Firebase‑free**, making it trivially unit‑testable and the single source of truth for ordering.

---

## 10. Match History

Per‑user record of finished online matches (`history_screen.dart`, `history_model.dart`).

- Stored under `history/{uid}`; each entry holds a **status** (won / lost / tie), the **net coin change**, and a **timestamp**.
- Net coin change: **+entryFee** for a win, **−entryFee** for a loss, **0** for a draw (the stake is returned).
- The History screen **streams** records **newest‑first**, updating live as matches settle.
- Both players' history rows are written by the single result claimer (same pattern as the payout).

---

## 11. Skins

Cosmetic mark sets that customize the **X** and **O** pieces (`skins_screen.dart`, `skin_model.dart`).

- A `Skin` defines a name, an **X artwork** (`skinX`), an **O artwork** (`skinO`), a selection status, and an optional `priceId` for in‑app purchase.
- **Built‑in skins:** *DORA Classic* (default) and *DORA Enhance*.
- New users start with the default skin assigned; available skins can also be **streamed from the database** (`availableSkins` node), falling back to the built‑in list.
- **Activation** (`updateSkin`) deactivates all other skins and marks the chosen one active; if the user doesn't own it yet, it's added. The active skin is applied to the board pieces in every mode.
- UI includes **skin tiles**, a **claim button**, and a **confirmation dialog**.

---

## 12. Shop

Coin top‑up store (`shop_screen.dart`, `shop_item_model.dart`).

- Two item types:
  - **Purchase** — paid coin packs with a USD price.
  - **Rewarded Ad** — free coins for watching an ad.
- Displayed as a 2‑column grid, **streamed from the `shopItems` database node** with a placeholder catalogue fallback.
- **Default catalogue:** 100 / 500 / 1,000 / 200 / 5,000‑coin packs, plus a 50‑coin rewarded‑ad entry.
- Coin artwork is chosen by pack size (small/medium/large stacks → coin bags for the largest tiers).

---

## 13. More Games (WebView)

A built‑in directory of external HTML5 games (`more_games_screen.dart`, `game_webview_screen.dart`, `more_game_model.dart`).

- Games are listed from `AppSettings.moreGames` and opened in an in‑app **WebView** (`webview_flutter`).
- **Bundled titles:** *2048*, *Tetris*, and *Kour.io*.
- Adding a new game requires only a new `MoreGame(name, url)` entry — no other code changes.

---

## 14. Settings & Profile

The Settings screen (`settings_screen.dart`) shows a **profile card** (avatar, stats) and a menu:

| Menu item | Action |
|-----------|--------|
| **History** | Opens match history |
| **Shop** | Opens coin shop |
| **Skin** | Opens skin selection |
| **Play More Games** | Opens WebView game directory |
| Change Language | *(placeholder)* |
| Contact Us | *(placeholder)* |
| About Us | *(placeholder)* |
| Terms And Conditions | *(placeholder)* |
| Privacy Policy | *(placeholder)* |
| Share App | *(placeholder)* |
| Rate Us | *(placeholder)* |

The profile pulls live stats from the user node: **username, avatar, coins, score, matches played, matches won**.

---

## 15. Architecture & Tech Stack

### Pattern

- **BLoC** (`flutter_bloc`, `bloc_concurrency`) for state management.
  - `AuthenticationBloc` — sign‑in/out, current user.
  - `GameBloc` — in‑game state (moves, board replacement, game over / draw / next round).
  - `GameConnectionBloc` — matchmaking lifecycle.
- **Abstract `Game` engine** with mode‑specific subclasses (Strategy pattern).
- **Singleton `DatabaseService`** as the single gateway to Firebase Realtime Database.
- **Pure ranking module** decoupled from data access.

### Stack

| Concern | Package |
|---------|---------|
| Backend / realtime sync | `firebase_database` |
| Auth | `firebase_auth`, `google_sign_in`, `sign_in_with_apple` |
| Asset storage | `firebase_storage` |
| Abuse protection | `firebase_app_check` |
| Local storage | `shared_preferences` |
| Images | `cached_network_image`, `flutter_svg` |
| Embedded games | `webview_flutter` (pinned `>=4.7.0 <4.10.0`) |
| UI | `dotted_border`, `dotted_line`, `auto_size_text`, `cupertino_icons` |
| IDs | `uuid` |

### Project layout (`lib/`)

```
core/
  game_logic/    game engine, Dora AI, mode implementations
  services/      Firebase data service, login providers
  routes/        centralized routing
  theme/         colors, font sizes
  error_management/
data/
  bloc/          authentication, game, connection blocs
  models/        game, user, skin, shop, history, leaderboard models
  repositories/  leaderboard data + ranking
screens/         auth, home, game, skins, shop, leaderboard,
                 history, settings, more_games, splash
common/          shared widgets, extensions, utilities, local storage
```

---

## 16. Data Model Reference

| Model | Purpose | Key fields |
|-------|---------|-----------|
| `UserModel` | Player profile | username, userId, coin, score, matchPlayed, matchWon, profilePic, type, createdAt, rankKey |
| `GameModel` | Online match | gameKey, status, player1/2, board, currentTurn, result, matrixSize, rounds, currentRound, entryFee |
| `Player` | A participant | playerId, name, profile, skinX, skinO, activeSkinType |
| `GamePosition` | One board cell | playerId, skin, isBlank |
| `Skin` | Cosmetic mark set | id, name, skinX, skinO, selectedStatus, priceId |
| `ShopItem` | Store entry | id, coins, priceUsd, type (purchase / rewardedAd), image |
| `HistoryModel` | Finished‑match record | status (won/lost/tie), amount, dateTime |
| `LeaderboardModel` | Ranking entry | score, createdAt, rankKey, rank |
| `MatrixSize` | Board option | size, title |
| `GameRound` | Round option | digit, name |
| `MoreGame` | External game | name, url |

### Key enums (`game_model.dart`)

- `GameStatus` — `waiting`, `inProgress`, `completed`, `closed`
- `PlayerTurn` — `player1`, `player2`
- `GameResult` — `player1`, `player2`, `draw`, `notDeclared`

---

## 17. Configuration Reference

All tunable game constants live in **`lib/settings.dart`** (`AppSettings`):

| Setting | Value | Meaning |
|---------|-------|---------|
| `appName` | `TicTacToe` | App display name |
| `multiplayerFees` | `[10, 25, 50, 100]` | Selectable entry fees (coins) |
| `matrixSizes` | 3×3, 4×4, 5×5 | Board options |
| `rounds` | 1, 3, 5, 7 | Best‑of round options |
| `multiplayerConnectionSearchTime` | `60` s | Matchmaking wait timeout |
| `scoreForWin` | `10` | Leaderboard points for a win |
| `scoreForDraw` | `5` | Leaderboard points for a draw |
| `scoreForLoss` | `0` | Leaderboard points for a loss |
| Turn time | 20 / 30 / 40 s | Per‑turn clock by board size |
| `defaultSkin` | DORA Classic | Skin assigned to new users |
| `moreGames` | 2048, Tetris, Kour.io | WebView game directory |

> **Starting coin balance (500)** is set in `UserModel.toMap()` / `fromMap()` rather than `AppSettings`.

---

*Generated from source inspection of the `re-design` branch. Some Settings‑menu entries (Change Language, Contact Us, About Us, Terms, Privacy, Share, Rate) are present as navigation stubs and not yet wired to destinations.*
