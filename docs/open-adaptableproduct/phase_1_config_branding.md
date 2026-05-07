# Phase 1 — Config & Branding

**Goal:** Apply all AdaptableProduct customizations to the boilerplate shell. No domain models, no controllers, no views changed yet.

**Prerequisites:** The open-base boilerplate is installed and `bundle exec rails server` starts without errors.

**Spec reference:** `docs/open-adaptableproduct/AdaptableProduct_Demo_Spec_v1.md` §2, §11, §12

---

## Context

The boilerplate ships with generic `APP_NAME="Open Demo Starter"` and a blue accent (`--accent: #1d4ed8`). This phase swaps in AdaptableProduct values. Nothing touches models, controllers, routes, or views — pure configuration.

---

## Tasks

### 1. Environment Variables

Update `.env.example` — set AdaptableProduct values (placeholders only, no real keys):

```
APP_NAME="AdaptableProduct Demo"
APP_TAGLINE="Describe your product strategy. See the assumptions you are betting on."
APP_DESCRIPTION="An open source demo of the Assumption Matrix from AdaptableProduct, the quarterly companion for product leaders managing through structural change."
GEMINI_API_KEY=your_key_here
AI_CALLS_PER_USER_PER_DAY=50
AI_GLOBAL_TIMEOUT_SECONDS=15
```

Copy `.env.example` to `.env` (gitignored) and fill in your real `GEMINI_API_KEY`.

### 2. Accent Color

In `app/assets/stylesheets/application.css`, update the `:root` block:

```css
:root {
  --accent: #c026d3;
  --accent-hover: #a21caf;
}
```

Do not add SCSS compilation. This file is plain CSS with an `@import` for Bootstrap.

### 3. README — App-Specific Sections

Add the following sections to `README.md` (insert after the boilerplate's stack table, before Contributing):

- **Title:** `AdaptableProduct Demo`
- **Tagline:** `Describe your product strategy. See the assumptions you are betting on.`
- **Description paragraph** (one paragraph, see spec §11 for full text)
- **Why I built this** section (see spec §11)
- **Editable AI prompt** — explains the admin template UI, 7-step instructions (see spec §11)
- **Setup steps beyond `bin/setup`:** get Gemini API key, set `GEMINI_API_KEY` in `.env`, run `bin/setup`, run `bin/rails server`, sign in at `localhost:3000/sign_in` with `demo@example.com` / `password123`
- **Privacy note** (see spec §11 — warns users not to paste confidential strategy into a third-party API)

Keep the boilerplate's stack table, setup steps, license, and AI safety posture sections unchanged.

---

## Manual Checks

```
[ ] bin/setup runs without errors
[ ] bin/rails server starts (start it yourself in a separate terminal)
[ ] Home page loads — boilerplate content still shows (not yet replaced in this phase)
[ ] Accent color #c026d3 visible on primary buttons — inspect :root in DevTools
[ ] .env.example shows all three APP_* vars with AdaptableProduct values
[ ] .env is NOT tracked by git (run: git status — should not appear)
[ ] README contains all new AdaptableProduct sections
```

---

## RSpec

No new specs in this phase. Run the full boilerplate suite to confirm nothing regressed:

```bash
bundle exec rspec
```

All boilerplate specs must be green before moving to Phase 2.
