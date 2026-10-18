# Wiki, Interview, Trade Routes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add three top-level routes to TheQuantClub: `/wiki` (a cross-linked
reference wiki with an Obsidian-style graph view), `/interview` (a mock quant
interview with a full voice loop against a pluggable AI interviewer), and
`/trade` (a placeholder page).

**Architecture:** Standard Rails MVC, two new namespaced resource groups
(`Wiki::`, `Interview::`) plus `Home`/`Trade` controllers, backed by five new
ActiveRecord models across two SQLite tables-per-subsystem. No JS bundler is
added — the wiki graph uses `d3-force`/`d3-selection` pinned via
importmap-rails from esm.sh, and the interview voice loop uses only
browser-native `SpeechRecognition`/`speechSynthesis`.

**Tech Stack:** Rails 8.1 (Propshaft, SQLite, Turbo/Stimulus, importmap-rails,
Minitest), no new gems.

**Spec:** `docs/superpowers/specs/2026-10-17-wiki-interview-trade-design.md`

## Global Constraints

- Rails `~> 8.1.4`, SQLite, Propshaft, importmap-rails, Turbo/Stimulus — do
  not add a JS bundler or new gems.
- Color tokens (CSS custom properties): ink `#14181F`, paper `#F7F7F4`, navy
  `#10192B`, ledger-green `#0B6E4F`, hairline `#DADAD2`, amber `#C27803`.
  Amber is used **only** for the interview "listening" state — nowhere else.
- Type: serif (`"Source Serif 4", Georgia, "Iowan Old Style", serif`) for
  article bodies and problem statements; sans (`"IBM Plex Sans", system-ui,
  sans-serif`) for nav/chrome/labels. No all-caps labels, no eyebrow labels,
  no `→` appended to link/button text, no em-dash label chrome.
- No authentication/authorization anywhere in this plan — wiki editing and
  interview sessions are unauthenticated.
- No real LLM/voice-API integration — `Ai::InterviewerAdapter` interface +
  `Ai::MockInterviewerAdapter` implementation only, per spec.
- Wiki body rendering supports only `[[Title]]` links and `## Heading` →
  TOC entries — no full Markdown/CommonMark pipeline, no image uploads.
- `SpeechRecognition` (STT) is Chrome/Edge-only — the interview screen must
  always show a working text-input fallback, not just a disabled mic button.

## Review Focus

- An empty/stub wiki article (auto-created from an unresolved `[[Link]]`)
  must render without erroring and visibly read as unwritten — pinned by a
  dedicated test in Task 6.
- Case-variant duplicate wiki titles (`"Options"` vs `"options"`) must not
  silently create two articles — pinned in Task 3.
- An interview problem with blank `interviewer_notes` (no scripted
  follow-ups) must still produce a real reply, not an error or blank string
  — pinned in Task 11.
- A blank/missing wiki search query must return zero results, not the
  entire article list — pinned in Task 6.
- Posting a blank candidate message must be rejected with `422` and create
  no transcript rows, not raise or silently store an empty message —
  pinned in Task 14.

---

## Task 1: Routing skeleton, Home, and Trade

**Files:**
- Modify: `config/routes.rb`
- Create: `app/controllers/home_controller.rb`
- Create: `app/controllers/trade_controller.rb`
- Create: `app/views/home/index.html.erb`
- Create: `app/views/trade/index.html.erb`
- Test: `test/controllers/home_controller_test.rb`
- Test: `test/controllers/trade_controller_test.rb`

**Interfaces:**
- Produces: route helpers `root_path`, `trade_path`, `wiki_path`,
  `interview_problems_path` (the latter two are declared here as routes so
  later tasks can rely on them, even though their controllers don't exist
  until Tasks 6 and 12 — Rails routing doesn't require the controller to
  exist for the route/helper to be defined, only for the route to be hit).

- [ ] **Step 1: Write the failing tests**

```ruby
# test/controllers/home_controller_test.rb
require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "root shows entry points to wiki, interview, and trade" do
    get root_path
    assert_response :success
    assert_select "a[href=?]", wiki_path
    assert_select "a[href=?]", interview_problems_path
    assert_select "a[href=?]", trade_path
  end
end
```

```ruby
# test/controllers/trade_controller_test.rb
require "test_helper"

class TradeControllerTest < ActionDispatch::IntegrationTest
  test "index renders a coming-soon placeholder" do
    get trade_path
    assert_response :success
    assert_select "h1", text: "Trade"
  end
end
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `bin/rails test test/controllers/home_controller_test.rb test/controllers/trade_controller_test.rb`
Expected: FAIL — `root_path`/`wiki_path`/etc. undefined, no route matches.

- [ ] **Step 3: Replace `config/routes.rb`**

```ruby
Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  root "home#index"

  get "trade", to: "trade#index"

  get   "wiki",            to: "wiki/articles#index",  as: :wiki
  get   "wiki/search",     to: "wiki/articles#search",  as: :wiki_search
  get   "wiki/graph",      to: "wiki/graphs#show",      as: :wiki_graph
  get   "wiki/graph.json", to: "wiki/graphs#data",      as: :wiki_graph_data, defaults: { format: :json }
  get   "wiki/new",        to: "wiki/articles#new",     as: :new_wiki_article
  post  "wiki",            to: "wiki/articles#create",  as: :wiki_articles
  get   "wiki/:slug/edit", to: "wiki/articles#edit",    as: :edit_wiki_article
  patch "wiki/:slug",      to: "wiki/articles#update"
  get   "wiki/:slug",      to: "wiki/articles#show",    as: :wiki_article

  get  "interview",                               to: "interview/problems#index", as: :interview_problems
  post "interview/problems/:problem_id/sessions", to: "interview/sessions#create", as: :interview_problem_sessions
  get  "interview/sessions/:id",                  to: "interview/sessions#show",   as: :interview_session
  post "interview/sessions/:id/messages",         to: "interview/messages#create", as: :interview_session_messages
end
```

- [ ] **Step 4: Create the controllers**

```ruby
# app/controllers/home_controller.rb
class HomeController < ApplicationController
  def index
  end
end
```

```ruby
# app/controllers/trade_controller.rb
class TradeController < ApplicationController
  def index
  end
end
```

- [ ] **Step 5: Create the views**

```erb
<%# app/views/home/index.html.erb %>
<% content_for :title, "TheQuantClub" %>

<main class="home-landing">
  <h1>TheQuantClub</h1>
  <p class="home-tagline">Learn the mechanics, practice the interview, trade the idea.</p>

  <ul class="home-entry-cards">
    <li class="home-entry-card">
      <h2><%= link_to "Wiki", wiki_path %></h2>
      <p>A reference wiki for options, market structure, and probability, with an interlink graph.</p>
    </li>
    <li class="home-entry-card">
      <h2><%= link_to "Interview", interview_problems_path %></h2>
      <p>Practice quant interview problems and talk through your reasoning with an AI interviewer.</p>
    </li>
    <li class="home-entry-card">
      <h2><%= link_to "Trade", trade_path %></h2>
      <p>Coming soon.</p>
    </li>
  </ul>
</main>
```

```erb
<%# app/views/trade/index.html.erb %>
<% content_for :title, "Trade — TheQuantClub" %>

<main class="trade-placeholder">
  <h1>Trade</h1>
  <p>Trading simulator — coming soon.</p>
</main>
```

- [ ] **Step 6: Run tests to verify they pass**

Run: `bin/rails test test/controllers/home_controller_test.rb test/controllers/trade_controller_test.rb`
Expected: PASS

- [ ] **Step 7: Commit**

```bash
git add config/routes.rb app/controllers/home_controller.rb app/controllers/trade_controller.rb app/views/home app/views/trade test/controllers/home_controller_test.rb test/controllers/trade_controller_test.rb
git commit -m "Add root, trade, and route skeleton for wiki/interview"
```

---

## Task 2: Shared layout, nav, and design tokens

**Files:**
- Create: `app/assets/stylesheets/tokens.css`
- Create: `app/assets/stylesheets/base.css`
- Modify: `app/assets/stylesheets/application.css`
- Create: `app/views/layouts/_nav.html.erb`
- Modify: `app/views/layouts/application.html.erb`

**Interfaces:**
- Consumes: `wiki_path`, `interview_problems_path`, `trade_path`, `root_path` (Task 1).
- Produces: CSS custom properties `--color-ink`, `--color-paper`,
  `--color-navy`, `--color-ledger-green`, `--color-hairline`,
  `--color-amber`, `--font-serif`, `--font-sans`, `--measure`, used by every
  later stylesheet in this plan.

- [ ] **Step 1: Create the design tokens**

```css
/* app/assets/stylesheets/tokens.css */
:root {
  --color-ink: #14181f;
  --color-paper: #f7f7f4;
  --color-navy: #10192b;
  --color-ledger-green: #0b6e4f;
  --color-hairline: #dadad2;
  --color-amber: #c27803;

  --font-serif: "Source Serif 4", Georgia, "Iowan Old Style", serif;
  --font-sans: "IBM Plex Sans", system-ui, sans-serif;

  --measure: 72ch;
}
```

- [ ] **Step 2: Create the base stylesheet**

```css
/* app/assets/stylesheets/base.css */
* {
  box-sizing: border-box;
}

body {
  margin: 0;
  background: var(--color-paper);
  color: var(--color-ink);
  font-family: var(--font-sans);
  line-height: 1.5;
}

a {
  color: var(--color-ledger-green);
}

h1,
h2,
h3 {
  font-family: var(--font-serif);
  font-weight: 600;
}

main {
  max-width: var(--measure);
  margin: 0 auto;
  padding: 2rem 1.5rem;
}

.site-nav {
  display: flex;
  align-items: center;
  justify-content: space-between;
  background: var(--color-navy);
  color: #fff;
  padding: 1rem 1.5rem;
}

.site-nav-brand {
  color: #fff;
  font-family: var(--font-serif);
  font-size: 1.25rem;
  text-decoration: none;
}

.site-nav-links a {
  color: #d7dbe4;
  margin-left: 1.5rem;
  text-decoration: none;
}

.site-nav-links a.is-active,
.site-nav-links a:hover {
  color: #fff;
}

.home-entry-cards {
  list-style: none;
  padding: 0;
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(14rem, 1fr));
  gap: 1.5rem;
}

.home-entry-card {
  border: 1px solid var(--color-hairline);
  padding: 1.5rem;
}
```

- [ ] **Step 3: Import both files from the manifest**

```css
/* app/assets/stylesheets/application.css */
@import "tokens";
@import "base";
```

- [ ] **Step 4: Create the nav partial**

```erb
<%# app/views/layouts/_nav.html.erb %>
<nav class="site-nav">
  <%= link_to "TheQuantClub", root_path, class: "site-nav-brand" %>
  <div class="site-nav-links">
    <%= link_to "Wiki", wiki_path, class: ("is-active" if current_page?(wiki_path)) %>
    <%= link_to "Interview", interview_problems_path, class: ("is-active" if current_page?(interview_problems_path)) %>
    <%= link_to "Trade", trade_path, class: ("is-active" if current_page?(trade_path)) %>
  </div>
</nav>
```

- [ ] **Step 5: Render the nav and load fonts in the layout**

Replace `app/views/layouts/application.html.erb` with:

```erb
<!DOCTYPE html>
<html>
  <head>
    <title><%= content_for(:title) || "TheQuantClub" %></title>
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <meta name="apple-mobile-web-app-capable" content="yes">
    <meta name="application-name" content="TheQuantClub">
    <meta name="mobile-web-app-capable" content="yes">
    <%= csrf_meta_tags %>
    <%= csp_meta_tag %>

    <%= yield :head %>

    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Source+Serif+4:opsz,wght@8..60,400;8..60,600&family=IBM+Plex+Sans:wght@400;500;600&display=swap" rel="stylesheet">

    <link rel="icon" href="/icon.png" type="image/png">
    <link rel="icon" href="/icon.svg" type="image/svg+xml">
    <link rel="apple-touch-icon" href="/icon.png">

    <%= stylesheet_link_tag :app, "data-turbo-track": "reload" %>
    <%= javascript_importmap_tags %>
  </head>

  <body>
    <%= render "layouts/nav" %>
    <%= yield %>
  </body>
</html>
```

- [ ] **Step 6: Run Task 1's tests to verify the nav renders correctly**

Run: `bin/rails test test/controllers/home_controller_test.rb`
Expected: PASS — the `assert_select "a[href=?]"` assertions now match links
inside `.site-nav`.

- [ ] **Step 7: Commit**

```bash
git add app/assets/stylesheets app/views/layouts
git commit -m "Add shared nav and design tokens"
```

---

## Task 3: `WikiArticle` model

**Files:**
- Create: `db/migrate/20261017120001_create_wiki_articles.rb`
- Create: `app/models/wiki_article.rb`
- Test: `test/models/wiki_article_test.rb`

**Interfaces:**
- Produces: `WikiArticle` with columns `title`, `slug`, `summary`, `body`,
  `category`; `WikiArticle#to_param` (returns `slug`); `WikiArticle#stub?`
  (true when `body` is blank). Slug is auto-assigned from `title` on save.
  Title uniqueness is case-insensitive.

- [ ] **Step 1: Write the failing tests**

```ruby
# test/models/wiki_article_test.rb
require "test_helper"

class WikiArticleTest < ActiveSupport::TestCase
  test "assigns a slug from the title on save" do
    article = WikiArticle.create!(title: "Black-Scholes Model", summary: "s", body: "b", category: "Derivatives")
    assert_equal "black-scholes-model", article.slug
  end

  test "rejects a case-variant duplicate title" do
    WikiArticle.create!(title: "Options", summary: "s", body: "b", category: "Derivatives")
    duplicate = WikiArticle.new(title: "options", summary: "s2", body: "b2", category: "Derivatives")

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:title], "has already been taken"
  end

  test "requires a title" do
    article = WikiArticle.new(summary: "s", body: "b")
    assert_not article.valid?
  end

  test "to_param returns the slug" do
    article = WikiArticle.create!(title: "Volatility", summary: "s", body: "b", category: "Risk")
    assert_equal article.slug, article.to_param
  end

  test "stub? is true for an article with no body" do
    stub = WikiArticle.create!(title: "Delta Hedging", summary: "", body: "", category: "")
    assert stub.stub?
  end
end
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `bin/rails test test/models/wiki_article_test.rb`
Expected: FAIL — uninitialized constant `WikiArticle`.

- [ ] **Step 3: Create the migration**

```ruby
# db/migrate/20261017120001_create_wiki_articles.rb
class CreateWikiArticles < ActiveRecord::Migration[8.1]
  def change
    create_table :wiki_articles do |t|
      t.string :title, null: false
      t.string :slug, null: false
      t.text :summary, default: "", null: false
      t.text :body, default: "", null: false
      t.string :category, default: "", null: false

      t.timestamps
    end

    add_index :wiki_articles, :slug, unique: true
  end
end
```

- [ ] **Step 4: Create the model**

```ruby
# app/models/wiki_article.rb
class WikiArticle < ApplicationRecord
  validates :title, presence: true, uniqueness: { case_sensitive: false }
  validates :slug, presence: true, uniqueness: true

  before_validation :assign_slug, if: -> { slug.blank? && title.present? }

  def to_param
    slug
  end

  def stub?
    body.blank?
  end

  private

  def assign_slug
    base = title.to_s.parameterize
    candidate = base
    suffix = 2

    while WikiArticle.where.not(id: id).exists?(slug: candidate)
      candidate = "#{base}-#{suffix}"
      suffix += 1
    end

    self.slug = candidate
  end
end
```

- [ ] **Step 5: Run the migration and tests**

Run: `bin/rails db:migrate && bin/rails test test/models/wiki_article_test.rb`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add db/migrate app/models/wiki_article.rb test/models/wiki_article_test.rb db/schema.rb
git commit -m "Add WikiArticle model"
```

---

## Task 4: Wiki interlinking (`WikiLink`, `Wiki::LinkParser`)

**Files:**
- Create: `db/migrate/20261017120002_create_wiki_links.rb`
- Create: `app/models/wiki_link.rb`
- Create: `app/services/wiki/link_parser.rb`
- Modify: `app/models/wiki_article.rb`
- Test: `test/models/wiki_link_test.rb`
- Test: `test/services/wiki/link_parser_test.rb`

**Interfaces:**
- Consumes: `WikiArticle` (Task 3).
- Produces: `Wiki::LinkParser.titles_in(body)` → `Array<String>` of unique
  `[[Title]]` targets, in order of first appearance.
  `WikiArticle.find_or_create_stub!(title)` → existing or newly created
  (empty-body) `WikiArticle`, matched case-insensitively.
  `WikiArticle#outgoing_links`/`#incoming_links` (`WikiLink` associations),
  `#linked_articles`/`#backlinked_articles` (`WikiArticle` associations).
  Saving a `WikiArticle` keeps its `WikiLink` rows in sync with the
  `[[...]]` references currently in `body`.

- [ ] **Step 1: Write the failing tests**

```ruby
# test/services/wiki/link_parser_test.rb
require "test_helper"

class Wiki::LinkParserTest < ActiveSupport::TestCase
  test "extracts unique titles from [[wiki links]] in order" do
    body = "See [[Delta Hedging]] and [[Options]], also [[Delta Hedging]] again."
    assert_equal ["Delta Hedging", "Options"], Wiki::LinkParser.titles_in(body)
  end

  test "returns an empty array when there are no links" do
    assert_equal [], Wiki::LinkParser.titles_in("Plain text, no links.")
  end
end
```

```ruby
# test/models/wiki_link_test.rb
require "test_helper"

class WikiLinkTest < ActiveSupport::TestCase
  test "creates a stub article and a link for an unresolved [[wiki link]]" do
    article = WikiArticle.create!(title: "Options", summary: "s", body: "See [[Delta Hedging]] for more.", category: "Derivatives")

    stub = WikiArticle.find_by(title: "Delta Hedging")
    assert stub.present?
    assert stub.stub?
    assert_equal [stub.id], article.outgoing_links.pluck(:to_article_id)
  end

  test "links to an existing article instead of creating a duplicate" do
    target = WikiArticle.create!(title: "Volatility", summary: "s", body: "b", category: "Risk")
    article = WikiArticle.create!(title: "Options", summary: "s", body: "See [[Volatility]].", category: "Derivatives")

    assert_equal 1, WikiArticle.where(title: "Volatility").count
    assert_equal [target.id], article.outgoing_links.pluck(:to_article_id)
  end

  test "removes a link when the body no longer references it" do
    article = WikiArticle.create!(title: "Options", summary: "s", body: "See [[Volatility]].", category: "Derivatives")
    assert_equal 1, article.outgoing_links.count

    article.update!(body: "No more links here.")
    assert_equal 0, article.reload.outgoing_links.count
  end

  test "backlinked_articles lists articles pointing at this one" do
    target = WikiArticle.create!(title: "Volatility", summary: "s", body: "b", category: "Risk")
    source = WikiArticle.create!(title: "Options", summary: "s", body: "See [[Volatility]].", category: "Derivatives")

    assert_equal [source], target.backlinked_articles
  end
end
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `bin/rails test test/services/wiki/link_parser_test.rb test/models/wiki_link_test.rb`
Expected: FAIL — `Wiki::LinkParser`/`WikiLink` undefined.

- [ ] **Step 3: Create the migration**

```ruby
# db/migrate/20261017120002_create_wiki_links.rb
class CreateWikiLinks < ActiveRecord::Migration[8.1]
  def change
    create_table :wiki_links do |t|
      t.references :from_article, null: false, foreign_key: { to_table: :wiki_articles }
      t.references :to_article, null: false, foreign_key: { to_table: :wiki_articles }

      t.timestamps
    end

    add_index :wiki_links, [:from_article_id, :to_article_id], unique: true, name: "index_wiki_links_on_from_and_to"
  end
end
```

- [ ] **Step 4: Create the link parser**

```ruby
# app/services/wiki/link_parser.rb
module Wiki
  module LinkParser
    LINK_PATTERN = /\[\[([^\]]+)\]\]/

    module_function

    def titles_in(body)
      body.to_s.scan(LINK_PATTERN).flatten.map(&:strip).reject(&:blank?).uniq
    end
  end
end
```

- [ ] **Step 5: Create the `WikiLink` model**

```ruby
# app/models/wiki_link.rb
class WikiLink < ApplicationRecord
  belongs_to :from_article, class_name: "WikiArticle"
  belongs_to :to_article, class_name: "WikiArticle"

  validates :to_article_id, uniqueness: { scope: :from_article_id }
end
```

- [ ] **Step 6: Add associations and link-sync to `WikiArticle`**

Replace `app/models/wiki_article.rb` with:

```ruby
class WikiArticle < ApplicationRecord
  has_many :outgoing_links, class_name: "WikiLink", foreign_key: :from_article_id, dependent: :destroy, inverse_of: :from_article
  has_many :incoming_links, class_name: "WikiLink", foreign_key: :to_article_id, dependent: :destroy, inverse_of: :to_article
  has_many :linked_articles, through: :outgoing_links, source: :to_article
  has_many :backlinked_articles, through: :incoming_links, source: :from_article

  validates :title, presence: true, uniqueness: { case_sensitive: false }
  validates :slug, presence: true, uniqueness: true

  before_validation :assign_slug, if: -> { slug.blank? && title.present? }
  after_save :sync_wiki_links

  def self.find_or_create_stub!(title)
    find_by("lower(title) = ?", title.downcase.strip) ||
      create!(title: title.strip, body: "", summary: "", category: "")
  end

  def to_param
    slug
  end

  def stub?
    body.blank?
  end

  private

  def assign_slug
    base = title.to_s.parameterize
    candidate = base
    suffix = 2

    while WikiArticle.where.not(id: id).exists?(slug: candidate)
      candidate = "#{base}-#{suffix}"
      suffix += 1
    end

    self.slug = candidate
  end

  def sync_wiki_links
    target_ids = Wiki::LinkParser.titles_in(body).map { |t| WikiArticle.find_or_create_stub!(t).id }.uniq - [id]

    WikiLink.where(from_article_id: id).where.not(to_article_id: target_ids).destroy_all
    existing_ids = WikiLink.where(from_article_id: id).pluck(:to_article_id)
    (target_ids - existing_ids).each { |to_id| WikiLink.create!(from_article_id: id, to_article_id: to_id) }
  end
end
```

- [ ] **Step 7: Run the migration and tests**

Run: `bin/rails db:migrate && bin/rails test test/services/wiki/link_parser_test.rb test/models/wiki_link_test.rb test/models/wiki_article_test.rb`
Expected: PASS

- [ ] **Step 8: Commit**

```bash
git add db/migrate app/models app/services db/schema.rb test/models/wiki_link_test.rb test/services
git commit -m "Add wiki article interlinking (WikiLink, Wiki::LinkParser)"
```

---

## Task 5: `Wiki::BodyRenderer`

**Files:**
- Create: `app/services/wiki/body_renderer.rb`
- Test: `test/services/wiki/body_renderer_test.rb`

**Interfaces:**
- Consumes: `WikiArticle.find_by` (Task 3), `WikiArticle#stub?` (Task 3).
- Produces: `Wiki::BodyRenderer.render(body)` → an object with `.html`
  (an HTML-safe `String`) and `.headings` (`Array` of objects responding to
  `.text`/`.id`), used by `Wiki::ArticlesController#show` (Task 6).

- [ ] **Step 1: Write the failing tests**

```ruby
# test/services/wiki/body_renderer_test.rb
require "test_helper"

class Wiki::BodyRendererTest < ActiveSupport::TestCase
  test "renders paragraphs and headings with ids" do
    result = Wiki::BodyRenderer.render("Intro paragraph.\n\n## Background\n\nMore text.")

    assert_includes result.html, "<p>Intro paragraph.</p>"
    assert_includes result.html, '<h2 id="background">Background</h2>'
    assert_equal [["Background", "background"]], result.headings.map { |h| [h.text, h.id] }
  end

  test "renders a resolved [[link]] with the target's slug" do
    target = WikiArticle.create!(title: "Volatility", summary: "s", body: "b", category: "Risk")
    result = Wiki::BodyRenderer.render("See [[Volatility]].")

    assert_includes result.html, %(<a href="/wiki/#{target.slug}" class="wiki-link">Volatility</a>)
  end

  test "renders a stub [[link]] with the stub styling class" do
    WikiArticle.create!(title: "Delta Hedging", summary: "", body: "", category: "")
    result = Wiki::BodyRenderer.render("See [[Delta Hedging]].")

    assert_includes result.html, "wiki-link--stub"
  end

  test "escapes HTML in the body" do
    result = Wiki::BodyRenderer.render("<script>alert(1)</script>")
    assert_includes result.html, "&lt;script&gt;"
    assert_not_includes result.html, "<script>"
  end
end
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `bin/rails test test/services/wiki/body_renderer_test.rb`
Expected: FAIL — uninitialized constant `Wiki::BodyRenderer`.

- [ ] **Step 3: Create the renderer**

```ruby
# app/services/wiki/body_renderer.rb
module Wiki
  class BodyRenderer
    Heading = Struct.new(:text, :id, keyword_init: true)
    Result = Struct.new(:html, :headings, keyword_init: true)

    def self.render(body)
      new(body).render
    end

    def initialize(body)
      @body = body.to_s
    end

    def render
      headings = []

      blocks = @body.split(/\n{2,}/).filter_map do |block|
        block = block.strip
        next if block.empty?

        if block.start_with?("## ")
          text = block.sub(/\A##\s+/, "")
          id = text.parameterize
          headings << Heading.new(text: text, id: id)
          %(<h2 id="#{ERB::Util.html_escape(id)}">#{linkify(text)}</h2>)
        else
          %(<p>#{linkify(block)}</p>)
        end
      end

      Result.new(html: blocks.join("\n").html_safe, headings: headings)
    end

    private

    def linkify(text)
      ERB::Util.html_escape(text).gsub(/\[\[([^\]]+)\]\]/) do
        title = Regexp.last_match(1).strip
        target = WikiArticle.find_by("lower(title) = ?", title.downcase)
        next ERB::Util.html_escape(title) unless target

        css_class = target.stub? ? "wiki-link wiki-link--stub" : "wiki-link"
        %(<a href="/wiki/#{target.slug}" class="#{css_class}">#{ERB::Util.html_escape(title)}</a>)
      end.html_safe
    end
  end
end
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `bin/rails test test/services/wiki/body_renderer_test.rb`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add app/services/wiki/body_renderer.rb test/services/wiki/body_renderer_test.rb
git commit -m "Add Wiki::BodyRenderer"
```

---

## Task 6: `Wiki::ArticlesController` and article views

**Files:**
- Create: `app/controllers/wiki/articles_controller.rb`
- Create: `app/views/wiki/articles/index.html.erb`
- Create: `app/views/wiki/articles/show.html.erb`
- Create: `app/views/wiki/articles/search.html.erb`
- Create: `app/views/wiki/articles/new.html.erb`
- Create: `app/views/wiki/articles/edit.html.erb`
- Create: `app/views/wiki/articles/_form.html.erb`
- Create: `app/assets/stylesheets/wiki.css`
- Modify: `app/assets/stylesheets/application.css`
- Test: `test/controllers/wiki/articles_controller_test.rb`

**Interfaces:**
- Consumes: `WikiArticle` (Task 3), `WikiArticle` link associations (Task 4),
  `Wiki::BodyRenderer.render` (Task 5), route helpers `wiki_path`,
  `wiki_search_path`, `new_wiki_article_path`, `wiki_articles_path`,
  `edit_wiki_article_path`, `wiki_article_path` (Task 1).
- Produces: working `/wiki`, `/wiki/search`, `/wiki/:slug`, `/wiki/new`,
  `/wiki/:slug/edit` pages; the `.wiki-search-result` CSS class used by
  Task 6's own blank-query test.

- [ ] **Step 1: Write the failing tests**

```ruby
# test/controllers/wiki/articles_controller_test.rb
require "test_helper"

class Wiki::ArticlesControllerTest < ActionDispatch::IntegrationTest
  test "index shows categories and recent articles" do
    WikiArticle.create!(title: "Options", summary: "An option contract.", body: "b", category: "Derivatives")

    get wiki_path
    assert_response :success
    assert_select "h3", text: "Derivatives"
  end

  test "show renders the article body and backlinks" do
    target = WikiArticle.create!(title: "Volatility", summary: "s", body: "b", category: "Risk")
    WikiArticle.create!(title: "Options", summary: "s", body: "See [[Volatility]].", category: "Derivatives")

    get wiki_article_path(target)
    assert_response :success
    assert_select "h2", text: "Articles that link here"
    assert_select "a", text: "Options"
  end

  test "show renders a stub article without erroring" do
    WikiArticle.create!(title: "Options", summary: "s", body: "See [[Delta Hedging]].", category: "Derivatives")
    stub = WikiArticle.find_by(title: "Delta Hedging")

    get wiki_article_path(stub)
    assert_response :success
    assert_select "h1", text: "Delta Hedging"
  end

  test "search finds articles by title or body" do
    WikiArticle.create!(title: "Market Making", summary: "s", body: "quotes both sides", category: "Market Structure")

    get wiki_search_path(q: "quotes")
    assert_select ".wiki-search-result", count: 1
  end

  test "search with a blank query returns no results" do
    WikiArticle.create!(title: "Options", summary: "s", body: "b", category: "Derivatives")

    get wiki_search_path(q: "")
    assert_response :success
    assert_select ".wiki-search-result", count: 0
  end

  test "create saves a valid article and redirects to it" do
    assert_difference -> { WikiArticle.count }, 1 do
      post wiki_articles_path, params: { wiki_article: { title: "Risk Neutral Pricing", summary: "s", body: "b", category: "Derivatives" } }
    end
    assert_redirected_to wiki_article_path(WikiArticle.last)
  end

  test "create re-renders the form with errors when invalid" do
    post wiki_articles_path, params: { wiki_article: { title: "", summary: "s", body: "b", category: "Derivatives" } }
    assert_response :unprocessable_entity
  end

  test "update saves changes to an existing article" do
    article = WikiArticle.create!(title: "Options", summary: "old", body: "b", category: "Derivatives")
    patch wiki_article_path(article), params: { wiki_article: { summary: "new summary" } }
    assert_redirected_to wiki_article_path(article.reload)
    assert_equal "new summary", article.summary
  end
end
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `bin/rails test test/controllers/wiki/articles_controller_test.rb`
Expected: FAIL — uninitialized constant `Wiki::ArticlesController`.

- [ ] **Step 3: Create the controller**

```ruby
# app/controllers/wiki/articles_controller.rb
module Wiki
  class ArticlesController < ApplicationController
    before_action :set_article, only: [:show, :edit, :update]

    def index
      @categories = WikiArticle.where.not(body: "").group(:category).order(:category).count
      @recent = WikiArticle.where.not(body: "").order(created_at: :desc).limit(5)
      @term_of_the_day = term_of_the_day
    end

    def search
      @query = params[:q].to_s.strip
      @results = @query.present? ? WikiArticle.where("title LIKE :q OR body LIKE :q", q: "%#{@query}%") : WikiArticle.none
    end

    def show
      rendered = Wiki::BodyRenderer.render(@article.body)
      @body_html = rendered.html
      @headings = rendered.headings
      @backlinks = @article.backlinked_articles
      @related = @article.linked_articles
    end

    def new
      @article = WikiArticle.new
    end

    def create
      @article = WikiArticle.new(article_params)

      if @article.save
        redirect_to wiki_article_path(@article), notice: "Article created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @article.update(article_params)
        redirect_to wiki_article_path(@article), notice: "Article updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_article
      @article = WikiArticle.find_by!(slug: params[:slug])
    end

    def article_params
      params.require(:wiki_article).permit(:title, :summary, :body, :category)
    end

    def term_of_the_day
      published = WikiArticle.where.not(body: "").order(:id).to_a
      return nil if published.empty?

      published[Date.current.yday % published.count]
    end
  end
end
```

- [ ] **Step 4: Create the views**

```erb
<%# app/views/wiki/articles/index.html.erb %>
<% content_for :title, "Wiki — TheQuantClub" %>

<main class="wiki-home">
  <div class="wiki-masthead">
    <h1>TheQuantClub Wiki</h1>
    <%= form_with url: wiki_search_path, method: :get, class: "wiki-search" do %>
      <%= text_field_tag :q, params[:q], placeholder: "Search the wiki" %>
      <%= submit_tag "Search" %>
    <% end %>
  </div>

  <p>
    <%= link_to "View the article graph", wiki_graph_path %>
    ·
    <%= link_to "New article", new_wiki_article_path %>
  </p>

  <% if @term_of_the_day %>
    <section class="wiki-term-of-day">
      <h2>Term of the day: <%= link_to @term_of_the_day.title, wiki_article_path(@term_of_the_day) %></h2>
      <p><%= @term_of_the_day.summary %></p>
    </section>
  <% end %>

  <section class="wiki-categories">
    <% @categories.each do |category, count| %>
      <div class="wiki-category-card">
        <h3><%= category.presence || "Uncategorized" %></h3>
        <p><%= pluralize(count, "article") %></p>
      </div>
    <% end %>
  </section>

  <section>
    <h2>Recently added</h2>
    <ul>
      <% @recent.each do |article| %>
        <li><%= link_to article.title, wiki_article_path(article) %></li>
      <% end %>
    </ul>
  </section>
</main>
```

```erb
<%# app/views/wiki/articles/show.html.erb %>
<% content_for :title, "#{@article.title} — TheQuantClub Wiki" %>

<main class="wiki-article-layout">
  <article class="wiki-article-body">
    <nav class="wiki-toc">
      <% @headings.each do |heading| %>
        <div><%= link_to heading.text, "##{heading.id}" %></div>
      <% end %>
    </nav>

    <h1><%= @article.title %></h1>
    <%= @body_html %>

    <% if @backlinks.any? %>
      <section class="wiki-backlinks">
        <h2>Articles that link here</h2>
        <ul>
          <% @backlinks.each do |article| %>
            <li><%= link_to article.title, wiki_article_path(article) %></li>
          <% end %>
        </ul>
      </section>
    <% end %>
  </article>

  <aside class="wiki-infobox">
    <h3>Key facts</h3>
    <dl>
      <dt>Category</dt>
      <dd><%= @article.category.presence || "Uncategorized" %></dd>
      <dt>Related</dt>
      <dd>
        <% @related.each do |article| %>
          <%= link_to article.title, wiki_article_path(article) %><br>
        <% end %>
      </dd>
    </dl>
    <%= link_to "Edit this article", edit_wiki_article_path(@article) %>
  </aside>
</main>
```

```erb
<%# app/views/wiki/articles/search.html.erb %>
<% content_for :title, "Search — TheQuantClub Wiki" %>

<main class="wiki-search-page">
  <h1>Search results for "<%= @query %>"</h1>

  <ul class="wiki-search-results">
    <% @results.each do |article| %>
      <li class="wiki-search-result">
        <%= link_to article.title, wiki_article_path(article) %>
        <p><%= article.summary %></p>
      </li>
    <% end %>
  </ul>

  <% if @results.none? %>
    <p>No articles matched your search.</p>
  <% end %>
</main>
```

```erb
<%# app/views/wiki/articles/new.html.erb %>
<% content_for :title, "New Article — TheQuantClub Wiki" %>

<main class="wiki-form-page">
  <h1>New article</h1>
  <%= render "form", article: @article %>
</main>
```

```erb
<%# app/views/wiki/articles/edit.html.erb %>
<% content_for :title, "Edit #{@article.title} — TheQuantClub Wiki" %>

<main class="wiki-form-page">
  <h1>Edit <%= @article.title %></h1>
  <%= render "form", article: @article %>
</main>
```

```erb
<%# app/views/wiki/articles/_form.html.erb %>
<%= form_with model: article, url: (article.persisted? ? wiki_article_path(article) : wiki_articles_path), class: "wiki-form" do |form| %>
  <% if article.errors.any? %>
    <ul class="wiki-form-errors">
      <% article.errors.full_messages.each do |message| %>
        <li><%= message %></li>
      <% end %>
    </ul>
  <% end %>

  <label>
    Title
    <%= form.text_field :title %>
  </label>

  <label>
    Category
    <%= form.text_field :category %>
  </label>

  <label>
    Summary
    <%= form.text_area :summary %>
  </label>

  <label>
    Body
    <%= form.text_area :body %>
  </label>

  <%= form.submit article.persisted? ? "Save changes" : "Create article" %>
<% end %>
```

- [ ] **Step 5: Create the wiki stylesheet and import it**

```css
/* app/assets/stylesheets/wiki.css */
.wiki-masthead {
  display: flex;
  gap: 1rem;
  align-items: center;
  margin-bottom: 2rem;
}

.wiki-search input[type="text"] {
  padding: 0.5rem 0.75rem;
  border: 1px solid var(--color-hairline);
  min-width: 20rem;
}

.wiki-term-of-day {
  border: 1px solid var(--color-hairline);
  padding: 1.5rem;
  margin-bottom: 2rem;
}

.wiki-term-of-day h2 {
  margin-top: 0;
}

.wiki-categories {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(12rem, 1fr));
  gap: 1rem;
  margin-bottom: 2rem;
}

.wiki-category-card {
  border: 1px solid var(--color-hairline);
  padding: 1rem;
}

.wiki-article-layout {
  display: grid;
  grid-template-columns: 1fr 16rem;
  gap: 2rem;
  align-items: start;
}

.wiki-article-body {
  font-family: var(--font-serif);
  font-size: 1.0625rem;
  line-height: 1.7;
}

.wiki-toc {
  border-left: 2px solid var(--color-hairline);
  padding-left: 1rem;
  margin-bottom: 2rem;
  font-family: var(--font-sans);
  font-size: 0.9rem;
}

.wiki-infobox {
  border: 1px solid var(--color-hairline);
  padding: 1rem;
}

.wiki-infobox h3 {
  margin-top: 0;
  font-size: 1rem;
}

a.wiki-link--stub {
  border-bottom: 1px dashed var(--color-ledger-green);
  text-decoration: none;
}

.wiki-backlinks {
  margin-top: 2rem;
  padding-top: 1rem;
  border-top: 1px solid var(--color-hairline);
}

.wiki-form label {
  display: block;
  margin-bottom: 1rem;
}

.wiki-form input[type="text"],
.wiki-form textarea {
  width: 100%;
  padding: 0.5rem;
  border: 1px solid var(--color-hairline);
  font-family: inherit;
}

.wiki-form textarea {
  min-height: 12rem;
}
```

```css
/* app/assets/stylesheets/application.css */
@import "tokens";
@import "base";
@import "wiki";
```

- [ ] **Step 6: Run tests to verify they pass**

Run: `bin/rails test test/controllers/wiki/articles_controller_test.rb`
Expected: PASS

- [ ] **Step 7: Commit**

```bash
git add app/controllers/wiki app/views/wiki/articles app/assets/stylesheets test/controllers/wiki
git commit -m "Add wiki article pages (home, show, search, CRUD)"
```

---

## Task 7: Wiki graph view

**Files:**
- Create: `app/controllers/wiki/graphs_controller.rb`
- Create: `app/views/wiki/graphs/show.html.erb`
- Create: `app/javascript/controllers/wiki_graph_controller.js`
- Modify: `app/views/wiki/articles/show.html.erb`
- Modify: `app/assets/stylesheets/wiki.css`
- Modify: `config/importmap.rb`
- Test: `test/controllers/wiki/graphs_controller_test.rb`
- Test: `test/controllers/wiki/articles_controller_test.rb`

**Interfaces:**
- Consumes: `WikiArticle`/`WikiLink` (Tasks 3–4), route helpers
  `wiki_graph_path`, `wiki_graph_data_path` (Task 1).
- Produces: `GET /wiki/graph.json` → `{ nodes: [{id,title,slug,stub}],
  edges: [{source,target}] }`, optionally scoped to one article's 1-hop
  neighborhood via `?root=:slug`. The Stimulus `wiki-graph` controller
  (`data-controller="wiki-graph" data-wiki-graph-url-value="..."`) renders
  that JSON as a force-directed graph into its host element.

- [ ] **Step 1: Write the failing tests**

```ruby
# test/controllers/wiki/graphs_controller_test.rb
require "test_helper"

class Wiki::GraphsControllerTest < ActionDispatch::IntegrationTest
  test "data returns all articles and links as JSON" do
    a = WikiArticle.create!(title: "Options", summary: "s", body: "See [[Volatility]].", category: "Derivatives")
    b = WikiArticle.find_by(title: "Volatility")

    get wiki_graph_data_path(format: :json)
    assert_response :success

    json = JSON.parse(response.body)
    node_ids = json["nodes"].map { |n| n["id"] }
    assert_includes node_ids, a.id
    assert_includes node_ids, b.id
    assert_includes json["edges"], { "source" => a.id, "target" => b.id }
  end

  test "data scoped to a root slug only includes direct neighbors" do
    a = WikiArticle.create!(title: "Options", summary: "s", body: "See [[Volatility]].", category: "Derivatives")
    WikiArticle.create!(title: "Unrelated", summary: "s", body: "No links.", category: "Misc")

    get wiki_graph_data_path(format: :json, root: a.slug)
    json = JSON.parse(response.body)

    assert_equal 2, json["nodes"].length
    assert_not_includes json["nodes"].map { |n| n["title"] }, "Unrelated"
  end

  test "show renders the graph container" do
    get wiki_graph_path
    assert_response :success
    assert_select "#wiki-graph"
  end
end
```

Add to `test/controllers/wiki/articles_controller_test.rb` (new test, keep
all existing tests from Task 6 unchanged):

```ruby
  test "article show page includes a local graph container" do
    article = WikiArticle.create!(title: "Options", summary: "s", body: "b", category: "Derivatives")

    get wiki_article_path(article)
    assert_select "#wiki-local-graph"
  end
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `bin/rails test test/controllers/wiki/graphs_controller_test.rb test/controllers/wiki/articles_controller_test.rb`
Expected: FAIL — uninitialized constant `Wiki::GraphsController`; the new
local-graph test fails with no `#wiki-local-graph` element.

- [ ] **Step 3: Create the controller**

```ruby
# app/controllers/wiki/graphs_controller.rb
module Wiki
  class GraphsController < ApplicationController
    def show
    end

    def data
      articles =
        if params[:root].present?
          root = WikiArticle.find_by!(slug: params[:root])
          neighbor_ids = (root.outgoing_links.pluck(:to_article_id) + root.incoming_links.pluck(:from_article_id)).uniq
          WikiArticle.where(id: [root.id] + neighbor_ids)
        else
          WikiArticle.all
        end

      article_ids = articles.pluck(:id)
      links = WikiLink.where(from_article_id: article_ids, to_article_id: article_ids)

      render json: {
        nodes: articles.map { |a| { id: a.id, title: a.title, slug: a.slug, stub: a.stub? } },
        edges: links.map { |l| { source: l.from_article_id, target: l.to_article_id } }
      }
    end
  end
end
```

- [ ] **Step 4: Create the graph page view**

```erb
<%# app/views/wiki/graphs/show.html.erb %>
<% content_for :title, "Wiki Graph — TheQuantClub" %>

<main class="wiki-graph-page">
  <h1>Article graph</h1>
  <p class="wiki-graph-hint">Click a node to open that article. Hover to see its direct links.</p>
  <div id="wiki-graph" data-controller="wiki-graph" data-wiki-graph-url-value="<%= wiki_graph_data_path(format: :json) %>"></div>
</main>
```

- [ ] **Step 5: Add the local graph section to the article show view**

Replace `app/views/wiki/articles/show.html.erb` with:

```erb
<% content_for :title, "#{@article.title} — TheQuantClub Wiki" %>

<main class="wiki-article-layout">
  <article class="wiki-article-body">
    <nav class="wiki-toc">
      <% @headings.each do |heading| %>
        <div><%= link_to heading.text, "##{heading.id}" %></div>
      <% end %>
    </nav>

    <h1><%= @article.title %></h1>
    <%= @body_html %>

    <% if @backlinks.any? %>
      <section class="wiki-backlinks">
        <h2>Articles that link here</h2>
        <ul>
          <% @backlinks.each do |article| %>
            <li><%= link_to article.title, wiki_article_path(article) %></li>
          <% end %>
        </ul>
      </section>
    <% end %>

    <section class="wiki-local-graph">
      <h2>Local graph</h2>
      <div id="wiki-local-graph" data-controller="wiki-graph" data-wiki-graph-url-value="<%= wiki_graph_data_path(format: :json, root: @article.slug) %>"></div>
    </section>
  </article>

  <aside class="wiki-infobox">
    <h3>Key facts</h3>
    <dl>
      <dt>Category</dt>
      <dd><%= @article.category.presence || "Uncategorized" %></dd>
      <dt>Related</dt>
      <dd>
        <% @related.each do |article| %>
          <%= link_to article.title, wiki_article_path(article) %><br>
        <% end %>
      </dd>
    </dl>
    <%= link_to "Edit this article", edit_wiki_article_path(@article) %>
  </aside>
</main>
```

- [ ] **Step 6: Pin the graph library and write the Stimulus controller**

```ruby
# config/importmap.rb — append these two lines
pin "d3-force", to: "https://esm.sh/d3-force@3?bundle"
pin "d3-selection", to: "https://esm.sh/d3-selection@3?bundle"
```

```js
// app/javascript/controllers/wiki_graph_controller.js
import { Controller } from "@hotwired/stimulus"
import { forceSimulation, forceLink, forceManyBody, forceCenter } from "d3-force"
import { select } from "d3-selection"

export default class extends Controller {
  static values = { url: String }

  async connect() {
    const response = await fetch(this.urlValue, { headers: { Accept: "application/json" } })
    const { nodes, edges } = await response.json()
    this.render(nodes, edges)
  }

  render(nodes, edges) {
    const width = this.element.clientWidth || 800
    const height = 600

    const svg = select(this.element)
      .append("svg")
      .attr("viewBox", `0 0 ${width} ${height}`)
      .attr("class", "wiki-graph-svg")

    const simulation = forceSimulation(nodes)
      .force("link", forceLink(edges).id((d) => d.id).distance(90))
      .force("charge", forceManyBody().strength(-220))
      .force("center", forceCenter(width / 2, height / 2))
      .stop()

    for (let i = 0; i < 300; i += 1) simulation.tick()

    svg.append("g")
      .attr("class", "wiki-graph-edges")
      .selectAll("line")
      .data(edges)
      .join("line")
      .attr("x1", (d) => d.source.x)
      .attr("y1", (d) => d.source.y)
      .attr("x2", (d) => d.target.x)
      .attr("y2", (d) => d.target.y)

    const nodeGroup = svg.append("g")
      .attr("class", "wiki-graph-nodes")
      .selectAll("g")
      .data(nodes)
      .join("g")
      .attr("class", (d) => `wiki-graph-node${d.stub ? " wiki-graph-node--stub" : ""}`)
      .attr("transform", (d) => `translate(${d.x}, ${d.y})`)
      .style("cursor", "pointer")
      .on("click", (_event, d) => { window.location.href = `/wiki/${d.slug}` })

    nodeGroup.append("circle").attr("r", 8)
    nodeGroup.append("text").attr("dy", -12).attr("text-anchor", "middle").text((d) => d.title)
  }
}
```

- [ ] **Step 7: Append graph styles to the wiki stylesheet**

```css
/* append to app/assets/stylesheets/wiki.css */
.wiki-graph-page {
  max-width: none;
}

#wiki-graph {
  width: 100%;
  height: 600px;
  border: 1px solid var(--color-hairline);
}

.wiki-graph-svg {
  width: 100%;
  height: 100%;
}

.wiki-graph-node circle {
  fill: var(--color-ledger-green);
  stroke: #fff;
  stroke-width: 1.5;
}

.wiki-graph-node--stub circle {
  fill: var(--color-hairline);
}

.wiki-graph-node text {
  font-family: var(--font-sans);
  font-size: 0.7rem;
  fill: var(--color-ink);
}

.wiki-graph-edges line {
  stroke: var(--color-hairline);
  stroke-width: 1;
}

.wiki-local-graph {
  margin-top: 2rem;
}

#wiki-local-graph {
  width: 100%;
  height: 320px;
  border: 1px solid var(--color-hairline);
}
```

- [ ] **Step 8: Run tests to verify they pass**

Run: `bin/rails test test/controllers/wiki/graphs_controller_test.rb test/controllers/wiki/articles_controller_test.rb`
Expected: PASS

- [ ] **Step 9: Commit**

```bash
git add app/controllers/wiki/graphs_controller.rb app/views/wiki/graphs app/views/wiki/articles/show.html.erb app/javascript/controllers/wiki_graph_controller.js app/assets/stylesheets/wiki.css config/importmap.rb test/controllers/wiki
git commit -m "Add wiki graph view (global and per-article)"
```

---

## Task 8: Wiki seed content

**Files:**
- Modify: `db/seeds.rb`

**Interfaces:**
- Consumes: `WikiArticle` (Tasks 3–4).
- Produces: 7 persisted, cross-linked `WikiArticle` rows for manual/demo use.

- [ ] **Step 1: Append the wiki seed block to `db/seeds.rb`**

```ruby
wiki_articles = {
  "Black-Scholes Model" => {
    category: "Derivatives",
    summary: "A closed-form model for pricing European options.",
    body: <<~BODY
      The Black-Scholes Model gives a closed-form price for European [[Options]] under constant volatility.

      ## Assumptions

      It assumes the underlying follows [[Brownian Motion]] and that [[Volatility]] is constant over the life of the option.

      ## Hedging

      Traders use [[Delta Hedging]] to manage the risk of an option position priced with this model.
    BODY
  },
  "Options" => {
    category: "Derivatives",
    summary: "Contracts giving the right, not the obligation, to buy or sell an asset.",
    body: <<~BODY
      An option is a contract giving its holder the right, but not the obligation, to buy or sell an asset at a fixed price.

      ## Pricing

      Options are commonly priced with the [[Black-Scholes Model]] and quoted on an [[Order Book]] by firms doing [[Market Making]].
    BODY
  },
  "Delta Hedging" => {
    category: "Risk Management",
    summary: "Offsetting an option position's directional risk by trading the underlying.",
    body: <<~BODY
      Delta hedging offsets the directional risk of an [[Options]] position by trading the underlying asset.

      ## Why it matters

      A [[Market Making]] desk delta hedges continuously to stay close to risk-neutral while quoting an [[Order Book]].
    BODY
  },
  "Market Making" => {
    category: "Market Structure",
    summary: "Continuously quoting both sides of a market to earn the bid-ask spread.",
    body: <<~BODY
      A market maker continuously quotes both a bid and an ask on an [[Order Book]], earning the spread between them.

      ## Risk

      Market makers manage inventory risk with [[Delta Hedging]] and price [[Volatility]] into their quotes.
    BODY
  },
  "Order Book" => {
    category: "Market Structure",
    summary: "The ledger of resting buy and sell orders for an instrument.",
    body: <<~BODY
      An order book lists resting buy and sell orders for an instrument, ranked by price and time priority.

      ## Who trades on it

      [[Market Making]] desks post resting quotes on the order book; other participants cross the spread to trade immediately.
    BODY
  },
  "Volatility" => {
    category: "Risk Management",
    summary: "A measure of how much an asset's price fluctuates over time.",
    body: <<~BODY
      Volatility measures how much an asset's price fluctuates over a given period, and is a key input to the [[Black-Scholes Model]].

      ## Realized vs. implied

      Realized volatility is measured from historical prices; implied volatility is backed out of [[Options]] prices.
    BODY
  },
  "Brownian Motion" => {
    category: "Probability",
    summary: "A continuous-time random process used to model asset price paths.",
    body: <<~BODY
      Brownian motion is a continuous-time stochastic process with independent, normally distributed increments.

      ## In finance

      The [[Black-Scholes Model]] assumes the underlying asset's log-price follows a Brownian motion with constant [[Volatility]].
    BODY
  }
}.freeze

wiki_articles.each do |title, attrs|
  article = WikiArticle.find_or_initialize_by(title: title)
  article.assign_attributes(summary: attrs[:summary], body: attrs[:body], category: attrs[:category])
  article.save!
end
```

- [ ] **Step 2: Seed the development database and verify**

Run: `bin/rails db:seed`
Run: `bin/rails runner 'puts WikiArticle.count; puts WikiLink.count'`
Expected: `WikiArticle.count` prints `7` (every `[[link]]` target is itself
one of the 7 seeded titles, so no extra stubs are created);
`WikiLink.count` prints a number greater than `0`.

- [ ] **Step 3: Commit**

```bash
git add db/seeds.rb
git commit -m "Seed wiki with cross-linked quant/finance articles"
```

---

## Task 9: `InterviewProblem` model

**Files:**
- Create: `db/migrate/20261017120003_create_interview_problems.rb`
- Create: `app/models/interview_problem.rb`
- Test: `test/models/interview_problem_test.rb`

**Interfaces:**
- Produces: `InterviewProblem` with columns `title`, `category`,
  `difficulty`, `prompt`, `interviewer_notes`; constants
  `InterviewProblem::CATEGORIES` and `InterviewProblem::DIFFICULTIES`
  (arrays of allowed `String` values); `InterviewProblem#teaser` (first
  sentence of `prompt`).

- [ ] **Step 1: Write the failing tests**

```ruby
# test/models/interview_problem_test.rb
require "test_helper"

class InterviewProblemTest < ActiveSupport::TestCase
  test "requires a known category" do
    problem = InterviewProblem.new(title: "x", category: "nonsense", difficulty: "easy", prompt: "p")
    assert_not problem.valid?
    assert_includes problem.errors[:category], "is not included in the list"
  end

  test "requires a known difficulty" do
    problem = InterviewProblem.new(title: "x", category: "coding", difficulty: "nonsense", prompt: "p")
    assert_not problem.valid?
    assert_includes problem.errors[:difficulty], "is not included in the list"
  end

  test "teaser returns the first sentence of the prompt" do
    problem = InterviewProblem.create!(
      title: "Coin flips", category: "probability", difficulty: "easy",
      prompt: "Flip a fair coin until two heads in a row appear. What is the expected number of flips? Explain your approach."
    )
    assert_equal "Flip a fair coin until two heads in a row appear.", problem.teaser
  end
end
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `bin/rails test test/models/interview_problem_test.rb`
Expected: FAIL — uninitialized constant `InterviewProblem`.

- [ ] **Step 3: Create the migration**

```ruby
# db/migrate/20261017120003_create_interview_problems.rb
class CreateInterviewProblems < ActiveRecord::Migration[8.1]
  def change
    create_table :interview_problems do |t|
      t.string :title, null: false
      t.string :category, null: false
      t.string :difficulty, null: false
      t.text :prompt, null: false
      t.text :interviewer_notes, default: "", null: false

      t.timestamps
    end
  end
end
```

- [ ] **Step 4: Create the model**

```ruby
# app/models/interview_problem.rb
class InterviewProblem < ApplicationRecord
  CATEGORIES = %w[probability brainteaser market_making mental_math coding].freeze
  DIFFICULTIES = %w[easy medium hard].freeze

  has_many :interview_sessions, dependent: :destroy

  validates :title, presence: true
  validates :category, inclusion: { in: CATEGORIES }
  validates :difficulty, inclusion: { in: DIFFICULTIES }
  validates :prompt, presence: true

  def teaser
    prompt.to_s.split(/(?<=[.!?])\s/).first
  end
end
```

- [ ] **Step 5: Run the migration and tests**

Run: `bin/rails db:migrate && bin/rails test test/models/interview_problem_test.rb`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add db/migrate app/models/interview_problem.rb test/models/interview_problem_test.rb db/schema.rb
git commit -m "Add InterviewProblem model"
```

---

## Task 10: `InterviewSession` and `InterviewMessage` models

**Files:**
- Create: `db/migrate/20261017120004_create_interview_sessions.rb`
- Create: `db/migrate/20261017120005_create_interview_messages.rb`
- Create: `app/models/interview_session.rb`
- Create: `app/models/interview_message.rb`
- Test: `test/models/interview_session_test.rb`
- Test: `test/models/interview_message_test.rb`

**Interfaces:**
- Consumes: `InterviewProblem` (Task 9).
- Produces: `InterviewSession#status` (defaults to `"in_progress"`),
  `InterviewSession#interview_messages` (ordered by `created_at`);
  `InterviewMessage#role` (`"interviewer"`/`"candidate"`),
  `InterviewMessage#content`.

- [ ] **Step 1: Write the failing tests**

```ruby
# test/models/interview_session_test.rb
require "test_helper"

class InterviewSessionTest < ActiveSupport::TestCase
  test "defaults to in_progress status" do
    problem = InterviewProblem.create!(title: "x", category: "coding", difficulty: "medium", prompt: "p")
    session = InterviewSession.create!(interview_problem: problem)
    assert_equal "in_progress", session.status
  end

  test "orders messages by creation time" do
    problem = InterviewProblem.create!(title: "x", category: "coding", difficulty: "medium", prompt: "p")
    session = InterviewSession.create!(interview_problem: problem)
    second = session.interview_messages.create!(role: "interviewer", content: "second")
    first = session.interview_messages.create!(role: "candidate", content: "first")
    first.update!(created_at: second.created_at - 1.minute)

    assert_equal [first, second], session.interview_messages.to_a
  end
end
```

```ruby
# test/models/interview_message_test.rb
require "test_helper"

class InterviewMessageTest < ActiveSupport::TestCase
  test "rejects an unknown role" do
    problem = InterviewProblem.create!(title: "x", category: "coding", difficulty: "medium", prompt: "p")
    session = InterviewSession.create!(interview_problem: problem)
    message = InterviewMessage.new(interview_session: session, role: "moderator", content: "hi")

    assert_not message.valid?
  end

  test "requires content" do
    problem = InterviewProblem.create!(title: "x", category: "coding", difficulty: "medium", prompt: "p")
    session = InterviewSession.create!(interview_problem: problem)
    message = InterviewMessage.new(interview_session: session, role: "candidate", content: "")

    assert_not message.valid?
  end
end
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `bin/rails test test/models/interview_session_test.rb test/models/interview_message_test.rb`
Expected: FAIL — uninitialized constants.

- [ ] **Step 3: Create the migrations**

```ruby
# db/migrate/20261017120004_create_interview_sessions.rb
class CreateInterviewSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :interview_sessions do |t|
      t.references :interview_problem, null: false, foreign_key: true
      t.string :status, default: "in_progress", null: false

      t.timestamps
    end
  end
end
```

```ruby
# db/migrate/20261017120005_create_interview_messages.rb
class CreateInterviewMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :interview_messages do |t|
      t.references :interview_session, null: false, foreign_key: true
      t.string :role, null: false
      t.text :content, null: false

      t.timestamps
    end
  end
end
```

- [ ] **Step 4: Create the models**

```ruby
# app/models/interview_session.rb
class InterviewSession < ApplicationRecord
  STATUSES = %w[in_progress completed].freeze

  belongs_to :interview_problem
  has_many :interview_messages, -> { order(:created_at) }, dependent: :destroy

  validates :status, inclusion: { in: STATUSES }

  after_initialize :set_default_status, if: :new_record?

  private

  def set_default_status
    self.status ||= "in_progress"
  end
end
```

```ruby
# app/models/interview_message.rb
class InterviewMessage < ApplicationRecord
  ROLES = %w[interviewer candidate].freeze

  belongs_to :interview_session

  validates :role, inclusion: { in: ROLES }
  validates :content, presence: true
end
```

- [ ] **Step 5: Run the migrations and tests**

Run: `bin/rails db:migrate && bin/rails test test/models/interview_session_test.rb test/models/interview_message_test.rb`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add db/migrate app/models/interview_session.rb app/models/interview_message.rb test/models/interview_session_test.rb test/models/interview_message_test.rb db/schema.rb
git commit -m "Add InterviewSession and InterviewMessage models"
```

---

## Task 11: `Ai::InterviewerAdapter` and the mock implementation

**Files:**
- Create: `app/services/ai/interviewer_adapter.rb`
- Create: `app/services/ai/mock_interviewer_adapter.rb`
- Create: `config/initializers/interviewer_adapter.rb`
- Test: `test/services/ai/interviewer_adapter_test.rb`
- Test: `test/services/ai/mock_interviewer_adapter_test.rb`

**Interfaces:**
- Consumes: `InterviewProblem#interviewer_notes` (Task 9),
  `InterviewSession`/`InterviewMessage` (Task 10).
- Produces: `Ai::InterviewerAdapter.current` → the configured adapter
  class. `<Adapter>.respond(session:, problem:, history:)` → `String`,
  where `history` is an `Array`/relation of objects responding to `.role`.
  Used by `Interview::MessagesController` (Task 14).

- [ ] **Step 1: Write the failing tests**

```ruby
# test/services/ai/interviewer_adapter_test.rb
require "test_helper"

class Ai::InterviewerAdapterTest < ActiveSupport::TestCase
  test "current resolves the configured adapter class" do
    assert_equal Ai::MockInterviewerAdapter, Ai::InterviewerAdapter.current
  end

  test "the base class raises NotImplementedError" do
    assert_raises(NotImplementedError) do
      Ai::InterviewerAdapter.respond(session: nil, problem: InterviewProblem.new, history: [])
    end
  end
end
```

```ruby
# test/services/ai/mock_interviewer_adapter_test.rb
require "test_helper"

class Ai::MockInterviewerAdapterTest < ActiveSupport::TestCase
  def build_problem(notes: "What assumptions are you making?\nHow would a biased coin change your answer?")
    InterviewProblem.create!(title: "Coin flips", category: "probability", difficulty: "easy", prompt: "p", interviewer_notes: notes)
  end

  test "asks the first scripted follow-up after the candidate's first turn" do
    problem = build_problem
    session = InterviewSession.create!(interview_problem: problem)
    session.interview_messages.create!(role: "candidate", content: "My answer...")

    reply = Ai::MockInterviewerAdapter.respond(session: session, problem: problem, history: session.interview_messages.reload)
    assert_includes reply, "What assumptions are you making?"
  end

  test "asks the second scripted follow-up after the candidate's second turn" do
    problem = build_problem
    session = InterviewSession.create!(interview_problem: problem)
    session.interview_messages.create!(role: "candidate", content: "first answer")
    session.interview_messages.create!(role: "candidate", content: "second answer")

    reply = Ai::MockInterviewerAdapter.respond(session: session, problem: problem, history: session.interview_messages.reload)
    assert_includes reply, "How would a biased coin change your answer?"
  end

  test "wraps up once the scripted follow-ups are exhausted" do
    problem = build_problem
    session = InterviewSession.create!(interview_problem: problem)
    3.times { |n| session.interview_messages.create!(role: "candidate", content: "answer #{n}") }

    reply = Ai::MockInterviewerAdapter.respond(session: session, problem: problem, history: session.interview_messages.reload)
    assert_equal Ai::MockInterviewerAdapter::CLOSING, reply
  end

  test "still responds when the problem has no scripted follow-ups" do
    problem = build_problem(notes: "")
    session = InterviewSession.create!(interview_problem: problem)
    session.interview_messages.create!(role: "candidate", content: "my answer")

    reply = Ai::MockInterviewerAdapter.respond(session: session, problem: problem, history: session.interview_messages.reload)
    assert_equal Ai::MockInterviewerAdapter::CLOSING, reply
  end
end
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `bin/rails test test/services/ai/interviewer_adapter_test.rb test/services/ai/mock_interviewer_adapter_test.rb`
Expected: FAIL — uninitialized constants.

- [ ] **Step 3: Create the base adapter**

```ruby
# app/services/ai/interviewer_adapter.rb
module Ai
  class InterviewerAdapter
    def self.current
      Rails.application.config.interviewer_adapter.constantize
    end

    def self.respond(session:, problem:, history:)
      raise NotImplementedError, "#{name} must implement .respond(session:, problem:, history:)"
    end
  end
end
```

- [ ] **Step 4: Create the mock adapter**

```ruby
# app/services/ai/mock_interviewer_adapter.rb
module Ai
  class MockInterviewerAdapter < InterviewerAdapter
    OPENERS = [
      "Good start — walk me through how you got there.",
      "Okay, I follow so far — what's your next step?",
      "Makes sense. Can you justify that assumption?"
    ].freeze

    CLOSING = "That's a solid answer — I think we've covered this one. Nice work."

    def self.respond(session:, problem:, history:)
      candidate_turns = history.count { |message| message.role == "candidate" }
      follow_ups = follow_ups_for(problem)
      index = candidate_turns - 1

      return CLOSING if index >= follow_ups.length

      "#{OPENERS[index % OPENERS.length]} #{follow_ups[index]}"
    end

    def self.follow_ups_for(problem)
      problem.interviewer_notes.to_s.split("\n").map(&:strip).reject(&:empty?)
    end
    private_class_method :follow_ups_for
  end
end
```

- [ ] **Step 5: Create the initializer**

```ruby
# config/initializers/interviewer_adapter.rb
# The interview screen asks whichever adapter is configured here to produce
# the AI interviewer's next line. Ai::MockInterviewerAdapter is a fully
# working scripted responder with no external dependency.
#
# To wire a real LLM once credentials exist: implement
# `self.respond(session:, problem:, history:)` on a new class under
# `app/services/ai/`, add the provider's API key to Rails credentials, and
# point this config at the new class.
Rails.application.config.interviewer_adapter = "Ai::MockInterviewerAdapter"
```

- [ ] **Step 6: Run tests to verify they pass**

Run: `bin/rails test test/services/ai/interviewer_adapter_test.rb test/services/ai/mock_interviewer_adapter_test.rb`
Expected: PASS

- [ ] **Step 7: Commit**

```bash
git add app/services/ai config/initializers/interviewer_adapter.rb test/services/ai
git commit -m "Add pluggable Ai::InterviewerAdapter with a working mock"
```

---

## Task 12: `Interview::ProblemsController` and problem bank view

**Files:**
- Create: `app/controllers/interview/problems_controller.rb`
- Create: `app/views/interview/problems/index.html.erb`
- Create: `app/assets/stylesheets/interview.css`
- Modify: `app/assets/stylesheets/application.css`
- Test: `test/controllers/interview/problems_controller_test.rb`

**Interfaces:**
- Consumes: `InterviewProblem` (Task 9), route helpers
  `interview_problems_path`, `interview_problem_sessions_path` (Task 1).
- Produces: working `/interview` page listing/filtering problems; the
  `.interview-problem-card`, `.interview-message`, `.interview-status`
  etc. CSS classes used by Tasks 13–14's views.

- [ ] **Step 1: Write the failing tests**

```ruby
# test/controllers/interview/problems_controller_test.rb
require "test_helper"

class Interview::ProblemsControllerTest < ActionDispatch::IntegrationTest
  test "index lists problems" do
    InterviewProblem.create!(title: "Coin flips", category: "probability", difficulty: "easy", prompt: "p")

    get interview_problems_path
    assert_response :success
    assert_select "h2", text: "Coin flips"
  end

  test "index filters by category" do
    InterviewProblem.create!(title: "Coin flips", category: "probability", difficulty: "easy", prompt: "p")
    InterviewProblem.create!(title: "LIS", category: "coding", difficulty: "medium", prompt: "p")

    get interview_problems_path(category: "coding")
    assert_select "h2", text: "LIS"
    assert_select "h2", text: "Coin flips", count: 0
  end
end
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `bin/rails test test/controllers/interview/problems_controller_test.rb`
Expected: FAIL — uninitialized constant `Interview::ProblemsController`.

- [ ] **Step 3: Create the controller**

```ruby
# app/controllers/interview/problems_controller.rb
module Interview
  class ProblemsController < ApplicationController
    def index
      @category = params[:category].presence
      @difficulty = params[:difficulty].presence

      @problems = InterviewProblem.all
      @problems = @problems.where(category: @category) if @category
      @problems = @problems.where(difficulty: @difficulty) if @difficulty
      @problems = @problems.order(:category, :difficulty)
    end
  end
end
```

- [ ] **Step 4: Create the view**

```erb
<%# app/views/interview/problems/index.html.erb %>
<% content_for :title, "Interview — TheQuantClub" %>

<main class="interview-bank">
  <h1>Problem bank</h1>
  <p class="interview-bank-hint">Pick a problem, then talk through your reasoning with the AI interviewer.</p>

  <%= form_with url: interview_problems_path, method: :get, class: "interview-filters" do %>
    <select name="category">
      <option value="">All categories</option>
      <% InterviewProblem::CATEGORIES.each do |c| %>
        <option value="<%= c %>" <%= "selected" if @category == c %>><%= c.humanize %></option>
      <% end %>
    </select>
    <select name="difficulty">
      <option value="">All difficulties</option>
      <% InterviewProblem::DIFFICULTIES.each do |d| %>
        <option value="<%= d %>" <%= "selected" if @difficulty == d %>><%= d.humanize %></option>
      <% end %>
    </select>
    <%= submit_tag "Filter" %>
  <% end %>

  <ul class="interview-problem-list">
    <% @problems.each do |problem| %>
      <li class="interview-problem-card">
        <span class="interview-problem-category"><%= problem.category.humanize %></span>
        <span class="interview-problem-difficulty"><%= problem.difficulty.humanize %></span>
        <h2><%= problem.title %></h2>
        <p><%= problem.teaser %></p>
        <%= button_to "Start", interview_problem_sessions_path(problem), method: :post %>
      </li>
    <% end %>
  </ul>
</main>
```

- [ ] **Step 5: Create the interview stylesheet and import it**

```css
/* app/assets/stylesheets/interview.css */
.interview-bank-hint {
  color: #4b5160;
}

.interview-filters {
  display: flex;
  gap: 1rem;
  margin: 1.5rem 0;
}

.interview-problem-list {
  list-style: none;
  padding: 0;
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(16rem, 1fr));
  gap: 1rem;
}

.interview-problem-card {
  border: 1px solid var(--color-hairline);
  padding: 1rem;
}

.interview-problem-category,
.interview-problem-difficulty {
  display: inline-block;
  font-size: 0.8rem;
  color: #4b5160;
  margin-right: 0.5rem;
}

.interview-session {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 2rem;
  max-width: none;
}

.interview-problem-card p,
.interview-problem-card h1 {
  font-family: var(--font-serif);
}

.interview-transcript-panel {
  border-left: 1px solid var(--color-hairline);
  padding-left: 2rem;
}

.interview-status {
  font-size: 0.85rem;
  color: var(--color-amber);
}

.interview-transcript {
  list-style: none;
  padding: 0;
  max-height: 24rem;
  overflow-y: auto;
}

.interview-message {
  margin-bottom: 1rem;
}

.interview-message-role {
  display: block;
  font-size: 0.75rem;
  color: #4b5160;
}

.interview-message--interviewer p {
  color: var(--color-ink);
}

.interview-message--candidate p {
  color: var(--color-ledger-green);
}

.interview-controls {
  display: flex;
  gap: 1rem;
  align-items: center;
  margin-top: 1rem;
}
```

```css
/* app/assets/stylesheets/application.css */
@import "tokens";
@import "base";
@import "wiki";
@import "interview";
```

- [ ] **Step 6: Run tests to verify they pass**

Run: `bin/rails test test/controllers/interview/problems_controller_test.rb`
Expected: PASS

- [ ] **Step 7: Commit**

```bash
git add app/controllers/interview/problems_controller.rb app/views/interview/problems app/assets/stylesheets test/controllers/interview
git commit -m "Add interview problem bank page"
```

---

## Task 13: `Interview::SessionsController` and the mock interview screen

**Files:**
- Create: `app/controllers/interview/sessions_controller.rb`
- Create: `app/views/interview/sessions/show.html.erb`
- Test: `test/controllers/interview/sessions_controller_test.rb`

**Interfaces:**
- Consumes: `InterviewProblem`/`InterviewSession`/`InterviewMessage`
  (Tasks 9–10), route helpers `interview_problem_sessions_path`,
  `interview_session_path`, `interview_session_messages_path` (Task 1).
- Produces: `POST /interview/problems/:problem_id/sessions` creates a
  session with one opening `interviewer` message
  (`Interview::SessionsController::OPENING_LINE`) and redirects to it.
  `GET /interview/sessions/:id` renders the interview screen with
  `data-controller="interview"`, `data-interview-session-id-value`, and
  `data-interview-messages-url-value` attributes, consumed by Task 14's
  Stimulus controller.

- [ ] **Step 1: Write the failing tests**

```ruby
# test/controllers/interview/sessions_controller_test.rb
require "test_helper"

class Interview::SessionsControllerTest < ActionDispatch::IntegrationTest
  test "create starts a session with an opening interviewer message" do
    problem = InterviewProblem.create!(title: "Coin flips", category: "probability", difficulty: "easy", prompt: "p")

    assert_difference -> { InterviewSession.count }, 1 do
      post interview_problem_sessions_path(problem)
    end

    session = InterviewSession.last
    assert_redirected_to interview_session_path(session)
    assert_equal "interviewer", session.interview_messages.first.role
    assert_equal Interview::SessionsController::OPENING_LINE, session.interview_messages.first.content
  end

  test "show renders the problem and transcript" do
    problem = InterviewProblem.create!(title: "Coin flips", category: "probability", difficulty: "easy", prompt: "Flip until two heads.")
    session = problem.interview_sessions.create!
    session.interview_messages.create!(role: "interviewer", content: "Let's dive in.")

    get interview_session_path(session)
    assert_response :success
    assert_select "h1", text: "Coin flips"
    assert_select ".interview-message--interviewer"
  end
end
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `bin/rails test test/controllers/interview/sessions_controller_test.rb`
Expected: FAIL — uninitialized constant `Interview::SessionsController`.

- [ ] **Step 3: Create the controller**

```ruby
# app/controllers/interview/sessions_controller.rb
module Interview
  class SessionsController < ApplicationController
    OPENING_LINE = "Let's dive in — talk me through your thinking out loud."

    def create
      problem = InterviewProblem.find(params[:problem_id])
      session = problem.interview_sessions.create!
      session.interview_messages.create!(role: "interviewer", content: OPENING_LINE)

      redirect_to interview_session_path(session)
    end

    def show
      @session = InterviewSession.find(params[:id])
      @problem = @session.interview_problem
      @messages = @session.interview_messages
    end
  end
end
```

- [ ] **Step 4: Create the view**

```erb
<%# app/views/interview/sessions/show.html.erb %>
<% content_for :title, "#{@problem.title} — Mock Interview" %>

<main class="interview-session" data-controller="interview" data-interview-session-id-value="<%= @session.id %>" data-interview-messages-url-value="<%= interview_session_messages_path(@session) %>">
  <section class="interview-problem-card">
    <span class="interview-problem-category"><%= @problem.category.humanize %></span>
    <h1><%= @problem.title %></h1>
    <p><%= @problem.prompt %></p>
  </section>

  <section class="interview-transcript-panel">
    <p class="interview-status" data-interview-target="status">Idle</p>

    <ol class="interview-transcript" data-interview-target="transcript">
      <% @messages.each do |message| %>
        <li class="interview-message interview-message--<%= message.role %>">
          <span class="interview-message-role"><%= message.role.humanize %></span>
          <p><%= message.content %></p>
        </li>
      <% end %>
    </ol>

    <div class="interview-controls">
      <button type="button" data-interview-target="micButton" data-action="interview#toggleListening">Speak</button>
      <form data-action="submit->interview#submitTyped">
        <input type="text" data-interview-target="textInput" placeholder="Type your answer instead">
        <button type="submit">Send</button>
      </form>
    </div>
  </section>
</main>
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `bin/rails test test/controllers/interview/sessions_controller_test.rb`
Expected: PASS — the page renders even though the `interview` Stimulus
controller referenced by `data-controller="interview"` doesn't exist until
Task 14; an unregistered Stimulus controller doesn't break server-rendered
HTML or these request-level tests.

- [ ] **Step 6: Commit**

```bash
git add app/controllers/interview/sessions_controller.rb app/views/interview/sessions test/controllers/interview/sessions_controller_test.rb
git commit -m "Add interview session creation and the mock interview screen"
```

---

## Task 14: `Interview::MessagesController` and the voice loop

**Files:**
- Create: `app/controllers/interview/messages_controller.rb`
- Create: `app/javascript/controllers/interview_controller.js`
- Test: `test/controllers/interview/messages_controller_test.rb`

**Interfaces:**
- Consumes: `InterviewSession`/`InterviewMessage` (Task 10),
  `Ai::InterviewerAdapter.current` (Task 11), the `data-interview-*`
  attributes rendered by Task 13's view.
- Produces: `POST /interview/sessions/:id/messages` → on success, JSON
  `{ candidate_message: {role, content}, interviewer_message: {role,
  content} }`; on a blank `content` param, `422` with `{ errors: [...] }}`
  and no new rows. The `interview` Stimulus controller drives the
  browser-side mic capture, the fetch round-trip, transcript updates, and
  text-to-speech playback.

- [ ] **Step 1: Write the failing tests**

```ruby
# test/controllers/interview/messages_controller_test.rb
require "test_helper"

class Interview::MessagesControllerTest < ActionDispatch::IntegrationTest
  test "creates a candidate message and returns a scripted interviewer reply" do
    problem = InterviewProblem.create!(
      title: "Coin flips", category: "probability", difficulty: "easy",
      prompt: "p", interviewer_notes: "What assumptions are you making?"
    )
    session = problem.interview_sessions.create!
    session.interview_messages.create!(role: "interviewer", content: "Let's dive in.")

    post interview_session_messages_path(session), params: { content: "I'd use linearity of expectation." }, as: :json

    assert_response :success
    json = JSON.parse(response.body)
    assert_equal "I'd use linearity of expectation.", json["candidate_message"]["content"]
    assert_includes json["interviewer_message"]["content"], "What assumptions are you making?"
    assert_equal 3, session.interview_messages.count
  end

  test "rejects a blank candidate message" do
    problem = InterviewProblem.create!(title: "x", category: "coding", difficulty: "easy", prompt: "p")
    session = problem.interview_sessions.create!

    post interview_session_messages_path(session), params: { content: "" }, as: :json

    assert_response :unprocessable_entity
    assert_equal 0, session.interview_messages.count
  end
end
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `bin/rails test test/controllers/interview/messages_controller_test.rb`
Expected: FAIL — uninitialized constant `Interview::MessagesController`.

- [ ] **Step 3: Create the controller**

```ruby
# app/controllers/interview/messages_controller.rb
module Interview
  class MessagesController < ApplicationController
    def create
      session = InterviewSession.find(params[:id])
      candidate_message = session.interview_messages.new(role: "candidate", content: params[:content])

      unless candidate_message.save
        return render json: { errors: candidate_message.errors.full_messages }, status: :unprocessable_entity
      end

      reply_text = Ai::InterviewerAdapter.current.respond(
        session: session, problem: session.interview_problem, history: session.interview_messages.reload
      )
      interviewer_message = session.interview_messages.create!(role: "interviewer", content: reply_text)

      render json: {
        candidate_message: { role: candidate_message.role, content: candidate_message.content },
        interviewer_message: { role: interviewer_message.role, content: interviewer_message.content }
      }
    end
  end
end
```

- [ ] **Step 4: Create the Stimulus controller for the voice loop**

```js
// app/javascript/controllers/interview_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["transcript", "status", "micButton", "textInput"]
  static values = { sessionId: Number, messagesUrl: String }

  connect() {
    const Recognition = window.SpeechRecognition || window.webkitSpeechRecognition
    this.recognition = null
    this.listening = false

    if (Recognition) {
      this.recognition = new Recognition()
      this.recognition.lang = "en-US"
      this.recognition.interimResults = false
      this.recognition.onresult = (event) => {
        const transcript = event.results[event.results.length - 1][0].transcript
        this.send(transcript)
      }
      this.recognition.onend = () => {
        this.listening = false
        this.setStatus("Idle")
      }
    } else {
      this.micButtonTarget.disabled = true
      this.micButtonTarget.title = "Speech recognition isn't supported in this browser — use the text field."
    }
  }

  toggleListening() {
    if (!this.recognition) return

    if (this.listening) {
      this.recognition.stop()
      return
    }

    this.listening = true
    this.setStatus("Listening…")
    this.recognition.start()
  }

  submitTyped(event) {
    event.preventDefault()
    const value = this.textInputTarget.value.trim()
    if (!value) return

    this.textInputTarget.value = ""
    this.send(value)
  }

  async send(content) {
    this.appendMessage("candidate", content)
    this.setStatus("Thinking…")

    const response = await fetch(this.messagesUrlValue, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Accept: "application/json",
        "X-CSRF-Token": document.querySelector("meta[name='csrf-token']").content
      },
      body: JSON.stringify({ content })
    })

    const data = await response.json()
    this.appendMessage("interviewer", data.interviewer_message.content)
    this.speak(data.interviewer_message.content)
  }

  appendMessage(role, content) {
    const item = document.createElement("li")
    item.className = `interview-message interview-message--${role}`
    item.innerHTML = `<span class="interview-message-role">${role}</span><p></p>`
    item.querySelector("p").textContent = content
    this.transcriptTarget.appendChild(item)
  }

  speak(text) {
    if (!window.speechSynthesis) return

    this.setStatus("Speaking…")
    const utterance = new SpeechSynthesisUtterance(text)
    utterance.onend = () => this.setStatus("Idle")
    window.speechSynthesis.speak(utterance)
  }

  setStatus(text) {
    this.statusTarget.textContent = text
  }
}
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `bin/rails test test/controllers/interview/messages_controller_test.rb`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add app/controllers/interview/messages_controller.rb app/javascript/controllers/interview_controller.js test/controllers/interview/messages_controller_test.rb
git commit -m "Add interview message round-trip and the voice loop controller"
```

---

## Task 15: Interview seed content

**Files:**
- Modify: `db/seeds.rb`

**Interfaces:**
- Consumes: `InterviewProblem` (Task 9).
- Produces: 6 persisted `InterviewProblem` rows across all 5 categories.

- [ ] **Step 1: Append the interview seed block to `db/seeds.rb`**

```ruby
interview_problems = [
  {
    title: "Two heads in a row",
    category: "probability",
    difficulty: "easy",
    prompt: "Flip a fair coin repeatedly until you see two heads in a row. What is the expected number of flips?",
    interviewer_notes: "What assumptions are you making about the coin being fair?\nCan you set up a recursive equation for the expected number of flips?\nHow would your answer change for a biased coin with P(heads) = 0.6?"
  },
  {
    title: "25 horses, 5 tracks",
    category: "brainteaser",
    difficulty: "medium",
    prompt: "You have 25 horses and a track that can race 5 at a time, with no stopwatch, only finishing order. What's the minimum number of races to find the fastest 3 horses?",
    interviewer_notes: "How many races do you need just to rank all 25 if you ignore the 'fastest 3 only' simplification?\nWhich races become unnecessary once a horse has already lost to two faster horses?\nCan you prove 7 is both sufficient and necessary?"
  },
  {
    title: "Quote a coin-flip payout",
    category: "market_making",
    difficulty: "medium",
    prompt: "A coin pays $100 on heads and $0 on tails. The coin may be unfair. Make a two-sided market (bid/ask) on this payout.",
    interviewer_notes: "What's your fair value if you have no information about the coin's bias?\nHow wide do you quote the spread, and why that width?\nHow does your quote change once someone lifts your offer three times in a row?"
  },
  {
    title: "Fast mental multiplication",
    category: "mental_math",
    difficulty: "easy",
    prompt: "Multiply 47 by 68 without a calculator, and explain the technique you used.",
    interviewer_notes: "Can you break the multiplication into friendlier round numbers?\nWhat's a technique that generalizes to any two 2-digit numbers?\nHow would you sanity-check the answer's order of magnitude quickly?"
  },
  {
    title: "Longest increasing subsequence",
    category: "coding",
    difficulty: "hard",
    prompt: "Given an array of integers, find the length of the longest strictly increasing subsequence.",
    interviewer_notes: "What's the brute-force time complexity, and why is it too slow?\nCan you get this down to O(n log n) using patience sorting with binary search?\nWhat changes if the subsequence needs to be contiguous instead of just increasing in order?"
  },
  {
    title: "Sizing a quote under adverse selection",
    category: "market_making",
    difficulty: "hard",
    prompt: "You're market making an instrument and you suspect some counterparties are better informed than others. How do you size and price your quotes?",
    interviewer_notes: "How do you distinguish informed flow from noise in real time?\nWhat's the tradeoff between quoting wide and small versus tight and large?\nHow would you adjust your quote size after being adversely selected on your last three fills?"
  }
].freeze

interview_problems.each do |attrs|
  problem = InterviewProblem.find_or_initialize_by(title: attrs[:title])
  problem.assign_attributes(attrs)
  problem.save!
end
```

- [ ] **Step 2: Seed the development database and verify**

Run: `bin/rails db:seed`
Run: `bin/rails runner 'puts InterviewProblem.count; puts InterviewProblem.distinct.count(:category)'`
Expected: first line prints `6`; second line prints `5` (all categories represented).

- [ ] **Step 3: Commit**

```bash
git add db/seeds.rb
git commit -m "Seed interview problem bank"
```

---

## Task 16: End-to-end system test

**Files:**
- Create: `test/application_system_test_case.rb`
- Create: `test/system/wiki_and_interview_flows_test.rb`

**Interfaces:**
- Consumes: every model/controller/view from Tasks 3–15.
- Produces: one browser-driven regression test per subsystem's primary
  flow, per the spec's testing approach. Voice I/O (mic capture, TTS
  playback) is not exercised here — it's verified manually in-browser; the
  text-input fallback path is what this test exercises for the interview
  flow, since it doesn't require `SpeechRecognition`.

- [ ] **Step 1: Create the system test base class**

```ruby
# test/application_system_test_case.rb
require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::IntegrationTest
  driven_by :selenium, using: :headless_chrome, screen_size: [1400, 1400]
end
```

- [ ] **Step 2: Write the system test**

```ruby
# test/system/wiki_and_interview_flows_test.rb
require "application_system_test_case"

class WikiAndInterviewFlowsTest < ApplicationSystemTestCase
  test "visiting a wiki article shows its content and a link to another article" do
    WikiArticle.create!(title: "Options", summary: "s", body: "See [[Volatility]].", category: "Derivatives")
    WikiArticle.create!(title: "Volatility", summary: "s", body: "b", category: "Risk")

    visit wiki_article_path("options")

    assert_text "Options"
    assert_selector "a.wiki-link", text: "Volatility"
  end

  test "browsing and starting a mock interview creates a session with a transcript" do
    InterviewProblem.create!(
      title: "Coin flips", category: "probability", difficulty: "easy",
      prompt: "p", interviewer_notes: "What assumptions are you making?"
    )

    visit interview_problems_path
    click_on "Start"

    assert_text "Coin flips"
    assert_selector ".interview-message--interviewer"
  end
end
```

- [ ] **Step 3: Run the system test**

Run: `bin/rails test test/system/wiki_and_interview_flows_test.rb`
Expected: PASS. If headless Chrome/chromedriver isn't available in this
environment, this is expected to fail to *launch* (not a test assertion
failure) — note that in the final report rather than silently skipping it.

- [ ] **Step 4: Run the full test suite**

Run: `bin/rails test`
Expected: all tests from Tasks 1–16 PASS.

- [ ] **Step 5: Commit**

```bash
git add test/application_system_test_case.rb test/system
git commit -m "Add end-to-end system test for wiki and interview flows"
```
