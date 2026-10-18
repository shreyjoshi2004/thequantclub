# TheQuantClub: Wiki, Interview, Trade — Design Spec

Date: 2026-10-17
Status: Approved for planning

## Context

TheQuantClub is a brand-new Rails 8 app (Hotwire/Turbo/Stimulus, importmap-rails,
Propshaft, SQLite) with no models, no routes beyond the Rails defaults, and no
git history. This spec covers the first real feature work: three top-level
routes.

- `/wiki` — a reference wiki blending Wikipedia's encyclopedia conventions
  with Investopedia's financial-glossary conventions, plus scaffolding for a
  proper wiki including an Obsidian-style interlink graph view.
- `/interview` — a mock quant interview screen: browse problems, start a
  session, and have a full voice conversation with an AI interviewer.
- `/trade` — a placeholder route for now.

Three independent subsystems share one site identity and one small
foundation layer, so this spec covers all three but keeps each section
self-contained enough to plan/build separately if needed.

## Foundation (shared by all three routes)

### Routing & entry point
The app currently has no root route. Add:
- `root "home#index"` — a minimal landing page: wordmark, one-line tagline,
  three entry cards (Wiki / Interview / Trade).
- `get "trade", to: "trade#index"`.
- Wiki and Interview routes are detailed in their own sections below.

### Shared layout
- A `_nav.html.erb` partial rendered from the application layout: wordmark
  "TheQuantClub" + links to Wiki / Interview / Trade, active-link state via
  `current_page?`.
- `app/assets/stylesheets/application.css` becomes a set of imports
  (`@import`) under `app/assets/stylesheets/`: `tokens.css` (variables),
  `base.css` (reset/typography/nav), `wiki.css`, `interview.css`. Propshaft
  supports plain CSS `@import` across files it serves, so no preprocessor is
  needed.

### Design tokens (one visual identity across all pages)
- **Color**: ink `#14181F` (text), paper `#F7F7F4` (page background), navy
  `#10192B` (nav bar background only), ledger-green `#0B6E4F` (links,
  primary actions — the one accent used for interactive affordances),
  hairline `#DADAD2` (borders/rules), amber `#C27803` (reserved exclusively
  for the interview screen's "recording" state — functional, not
  decorative).
- **Type**: serif stack `"Source Serif 4", Georgia, "Iowan Old Style", serif`
  for article bodies and problem statements (reference-book register); sans
  stack `"IBM Plex Sans", system-ui, sans-serif` for nav/chrome/labels/UI.
  Load `Source Serif 4` and `IBM Plex Sans` via a Google Fonts `<link>` in
  the layout `<head>`, with the system fallbacks active if the request has
  no network access. No all-caps labels, no eyebrow labels, no em-dash
  label chrome.
- **Layout**: left-aligned editorial columns, article/problem text capped
  at ~72ch measure, hairline `border` rules instead of card shadows.

### Client-side graph/voice libraries, no bundler
The app only has importmap-rails (no esbuild/webpack/vite). Both new
client capabilities are added as importmap pins, not a build step:
- `d3-selection` and `d3-force` pinned from a CDN (esm.sh) for the wiki
  graph view.
- Interview voice loop uses only browser-native Web APIs
  (`SpeechRecognition` / `speechSynthesis`) — no library needed.

### Testing approach (applies to both subsystems)
- Model tests: link-parsing/stub-creation (wiki), associations/validations
  (both).
- Request/controller tests per route.
- One system test per subsystem smoke-covering the primary flow (visit
  article → graph page renders nodes; browse problems → start session →
  POST a message → mock interviewer reply persisted and rendered). Voice
  I/O itself (mic capture, TTS playback) is not headless-testable; verified
  manually in-browser after build, and documented as a known gap in
  automated coverage.

---

## `/wiki`

### Purpose
A reference work: Wikipedia's "encyclopedia article" conventions (TOC,
backlinks, neutral tone) blended with Investopedia's "financial glossary"
conventions (Key Facts sidebar, Term of the Day, Related Terms), plus
genuine wiki scaffolding — editable articles and an interlink graph — not
just static pages.

### Data model
- `WikiArticle`
  - `title:string`, `slug:string` (unique, derived from title), `summary:text`
    (one-paragraph dek shown on homepage/search/cards), `body:text`
    (markdown, supports `[[Target Title]]` wiki-link syntax), `category:string`
    (e.g. "Derivatives", "Market Structure", "Probability"), timestamps.
- `WikiLink`
  - `from_article_id`, `to_article_id` (both `WikiArticle`), unique on the
    pair. Rebuilt on every `WikiArticle` save: body is scanned for
    `[[...]]`, each target title is resolved to an existing article or used
    to create a stub article (title only, empty body — a "redlink" that
    renders but invites completion), and `WikiLink` rows are
    replaced/diffed to match the current body.

### Routes (RESTful, namespaced `Wiki::`)
| Verb | Path | Action | Purpose |
|---|---|---|---|
| GET | `/wiki` | `articles#index` | Homepage (see below) |
| GET | `/wiki/search` | `articles#search` | Title/body substring search |
| GET | `/wiki/graph` | `graphs#show` | Full graph view page |
| GET | `/wiki/graph.json` | `graphs#data` | Nodes/edges JSON for the graph page and article local-graph snippet |
| GET | `/wiki/new` | `articles#new` | New article form |
| POST | `/wiki` | `articles#create` | Create |
| GET | `/wiki/:slug/edit` | `articles#edit` | Edit form |
| PATCH | `/wiki/:slug` | `articles#update` | Update |
| GET | `/wiki/:slug` | `articles#show` | Article page |

### Pages
- **Homepage** (`#index`): masthead with search box; a "Term of the Day"
  hero module (deterministic pick, e.g. day-of-year modulo article count,
  so it's stable within a day without extra state) rendered with full
  serif treatment; category rows (articles grouped by `category`);
  "Recently added" list.
- **Article page** (`#show`): left TOC rail generated from the body's
  markdown headings; center serif article body with `[[links]]` rendered
  as real `<a>` tags (green accent, redlink styling — dashed underline —
  for stub articles); right "Key Facts" infobox card (category, backlink
  count, related-terms list pulled from `WikiLink`); footer section listing
  backlinks ("Articles that link here"); a small local-graph snippet
  (this article + 1-hop neighbors) rendered via the same JS graph
  controller, scoped to `graph.json?root=:slug`.
- **Graph page** (`#graphs/show`): full-bleed canvas, Stimulus controller
  fetches `/wiki/graph.json`, renders a `d3-force` node-link diagram;
  clicking a node navigates to that article; hovering highlights 1-hop
  neighbors.
- **Search** (`#search`): simple `title`/`body` `LIKE` query, no
  external search engine — explicitly scaffolding-level, matches "proper
  wiki" ask without overbuilding.
- **New/Edit** (`#new`/`#create`/`#edit`/`#update`): plain form (title,
  summary, category, body textarea) — this is the "scaffolding" for real
  editing; no rich-text editor, no auth/permissions layer (none exists in
  the app yet, out of scope here).

### Seed content
Seven cross-linked articles, so the graph is populated and demoable on
first load: Black-Scholes Model, Options, Delta Hedging, Market Making,
Order Book, Volatility, Brownian Motion. Each body references at least two
of the others via `[[...]]`.

---

## `/interview`

### Purpose
Browse real quant-interview problems, start a mock session, and hold a
full spoken conversation with an AI interviewer: speak an answer, hear the
interviewer respond, with a live transcript.

### Data model
- `InterviewProblem`: `title:string`, `category:string` (enum-like string:
  `probability`, `brainteaser`, `market_making`, `mental_math`, `coding`),
  `difficulty:string` (`easy`/`medium`/`hard`), `prompt:text` (shown to the
  candidate), `interviewer_notes:text` (talking points/expected approach —
  fed to the interviewer adapter, never rendered to the candidate).
- `InterviewSession`: `interview_problem_id`, `status:string`
  (`in_progress`/`completed`), timestamps.
- `InterviewMessage`: `interview_session_id`, `role:string`
  (`interviewer`/`candidate`), `content:text`, timestamps (ordered
  transcript).

### Routes (RESTful, namespaced `Interview::`)
| Verb | Path | Action | Purpose |
|---|---|---|---|
| GET | `/interview` | `problems#index` | Problem bank, filterable by category/difficulty |
| POST | `/interview/problems/:problem_id/sessions` | `sessions#create` | Start a session for a problem |
| GET | `/interview/sessions/:id` | `sessions#show` | The mock interview screen |
| POST | `/interview/sessions/:id/messages` | `messages#create` | Candidate turn in → interviewer reply out (JSON) |

### Pages
- **Problem bank** (`#index`): cards grouped/filterable by category and
  difficulty, each showing title + difficulty + a one-line teaser (first
  sentence of `prompt`). Clicking "Start" POSTs to create a session and
  redirects to it.
- **Interview screen** (`sessions#show`): two-column layout. Left: the
  problem card, serif "exam paper" styling, persistent for the session.
  Right: live transcript (candidate/interviewer messages, chat-log style)
  with a mic button and a status indicator (idle / listening / thinking /
  speaking). A visible fallback text input + send button is always present
  for browsers without `SpeechRecognition` support.

### Voice loop (client-side Stimulus controller + server round-trip)
1. Candidate clicks the mic button → `webkitSpeechRecognition` (feature
   detected; falls back to the visible text input if unavailable) starts
   listening; UI shows "listening" (amber pulse — the one place the amber
   token is used).
2. On a finalized recognition result, the controller POSTs the transcript
   to `/interview/sessions/:id/messages` as the `candidate` message.
3. `Interview::MessagesController#create` persists the candidate message,
   then calls `Ai::InterviewerAdapter.current.respond(session:, problem:,
   history:)` to produce the interviewer's reply, persists it as an
   `interviewer` message, and returns both as JSON.
4. The controller appends both messages to the transcript, then plays the
   interviewer reply through `speechSynthesis` (status indicator shows
   "speaking" while audio plays).
5. Loop repeats until the candidate ends the session.

### `Ai::InterviewerAdapter` (pluggable, no API key yet)
- `Ai::InterviewerAdapter` — the interface: class method `respond(session:,
  problem:, history:)` returning a `String`.
- `Ai::MockInterviewerAdapter` — the working default implementation.
  Not a stub: real scripted logic keyed on `problem.category` and
  `history.size` (e.g. acknowledges the candidate's last answer, then asks
  the next scripted follow-up drawn from `problem.interviewer_notes` for
  that category, escalating specificity each turn, and wraps up after N
  turns). Fully functional today — every call returns a real,
  context-appropriate reply.
- Adapter selection via `Rails.application.config.interviewer_adapter`
  (defaults to `Ai::MockInterviewerAdapter`), set in
  `config/initializers/interviewer_adapter.rb` with a comment documenting
  how to point it at a real LLM-backed adapter once credentials exist —
  the extension point is real and documented, no second adapter is
  half-implemented.

### Seed content
Six problems spanning all five categories (one extra in the most
content-rich category), each with a real `prompt` and `interviewer_notes`
usable by the mock adapter's scripted follow-ups:
1. Probability — expected number of flips to get two heads in a row.
2. Brainteaser — 25 horses, 5 tracks, find the fastest 3.
3. Market making — bid/ask a two-sided market on a coin-flip payout.
4. Mental math — multiply two 2-digit numbers rapidly, explain technique.
5. Coding — find the longest increasing subsequence.
6. Market making — size a quote given adverse-selection risk.

### Known limitation
`SpeechRecognition` (Web Speech API STT) has solid support in
Chrome/Edge/Chromium-based browsers but not Firefox/Safari as of this
writing. The screen degrades to the always-visible text input + send
button; `speechSynthesis` (TTS) has broader support and is used regardless
of STT availability.

---

## `/trade`

`TradeController#index` — a single static page using the shared nav and
tokens: "Trade" heading, one sentence ("Trading simulator — coming soon."),
no model, no params. Entire scope.

## Out of scope (explicitly, for this spec)
- Authentication/authorization (no user accounts exist anywhere in the app
  yet; wiki editing and interview sessions are unauthenticated).
- Any real LLM/voice-API integration (adapter interface only, per approved
  scope).
- Wiki markdown rendering beyond `[[links]]` + heading-based TOC (no full
  CommonMark pipeline, no image uploads).
- Trade subsystem design (explicitly deferred by the request).
