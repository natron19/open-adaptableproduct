# AdaptableProduct Demo

> Describe your product strategy. See the assumptions you are betting on.

AdaptableProduct Demo is an open source, single-feature taste of the production AdaptableProduct app. Enter your product name, target customer, current strategy in one paragraph, and the most important goal the strategy is meant to advance. Click Surface Assumptions, and Gemini returns 8 to 12 ranked, falsifiable assumptions your strategy depends on, each with a risk rating, a category, and a suggested experiment ordered cheapest first. Re-rate your own confidence on each row inline; the gap between the AI's confidence and yours is the most interesting cell.

## Quick Start

1. Clone this repo
2. Sign up for a free Gemini API key at https://aistudio.google.com/app/apikey
3. Copy `.env.example` to `.env` and set your `GEMINI_API_KEY`
4. Run `bin/setup`
5. `bin/rails server`
6. Visit http://localhost:3000 and sign in with `demo@example.com` / `password123`
7. Click the FieldNote product and hit **Surface Assumptions**

## Editable AI Prompt

The single AI template that drives this demo is `adaptableproduct_assumptions_v1`. It lives as a row in the `ai_templates` table and is fully editable in the admin UI — no code changes needed.

To iterate on the prompt:

1. Sign in as the seeded admin (`demo@example.com` / `password123`)
2. Click **Admin** in the user dropdown
3. Click **AI Templates**, then the template name
4. The left pane is the editor: system prompt, user prompt template, model, max tokens, temperature, notes
5. The right pane is a live test panel: variables auto-detected from `{{...}}` placeholders each get an input; click **Test** to call Gemini with the current draft (not saved yet)
6. When the output looks right, click **Save**
7. All future Surface Assumptions calls use the saved template

## Why I Built This

I built AdaptableProduct because most of the product strategy advice I have read assumes a stable strategic frame, and most of the strategies I have run did not have one. The 9-Step Adaptable Product Framework is the working version of the practice I wish I had had, and Step 3, Assumption Challenge, is the most productive single step a team can run. This demo is the smallest possible version of that step: enter the strategy, see the bets, disagree.

The full version is multi-tenant, supports team collaboration across all nine framework steps, longitudinal cycle comparison, decision logs with dissent preserved, and a Carryover Queue for between-cycle work. You can read about it at https://adaptableproduct.com (placeholder). This demo is MIT-licensed; the prompt that drives it is editable in the admin UI. That is the point of releasing it as data, not code.

## Privacy Note

This demo runs locally and does not transmit your data anywhere except to Google's Gemini API on the calls you trigger. Treat the strategy text you paste as you would treat any other Gemini prompt: do not include information you would not be willing to send to a third party. The seed StrategyProduct (FieldNote) is fictional and safe to use as a starting point.

## Environment Variables

| Variable | Default | Description |
|---|---|---|
| `APP_NAME` | `"AdaptableProduct Demo"` | Displayed in the navbar and title |
| `APP_TAGLINE` | — | Shown in the footer |
| `APP_DESCRIPTION` | — | Shown on the landing page |
| `GEMINI_API_KEY` | (required) | Your Google Gemini API key — get one free at https://aistudio.google.com/app/apikey |
| `AI_CALLS_PER_USER_PER_DAY` | `50` | Daily AI call budget per user |
| `AI_GLOBAL_TIMEOUT_SECONDS` | `15` | Gemini request timeout in seconds |

## Stack

| Layer | Choice |
|---|---|
| Framework | Rails 8.1 |
| Database | PostgreSQL with UUID primary keys |
| Auth | Rails native (`has_secure_password`, sessions) |
| CSS | Bootstrap 5 dark mode (CDN) |
| JavaScript | Stimulus + Turbo via importmap |
| AI | Google Gemini via `gemini-ai` gem |
| Queue / Cache / Cable | Solid Stack (no Redis) |
| Testing | RSpec |

## AI Safety Posture

**What this boilerplate enforces:**
- Per-user daily call cap (default: 50/day, set via `AI_CALLS_PER_USER_PER_DAY`)
- Pre-flight gatekeeper: input length limit, prompt injection patterns, profanity filter
- Hard output token cap per template
- Configurable request timeout (default: 15s)
- Full request log with status, tokens, duration, and cost estimate
- Fail-soft UI: errors render an inline alert, never crash the page
- AI disclaimer in the footer on every page

**Deliberately omitted (with rationale):**
- No PII scrubbing — demo apps have no production user data
- No content moderation API — Gemini's built-in safety filters are sufficient
- No automatic retries — avoids stacking costs on transient failures
- No RAG or vector DB — single-shot prompts only
- No streaming — synchronous calls keep the code simple

See `app/services/ai_gatekeeper.rb` and `app/services/ai_budget_checker.rb` to extend.

## Cost

All default templates use `gemini-2.5-flash`, which has a generous free tier. A user running the demo locally will not incur charges under typical use.

## License

MIT — see [LICENSE](LICENSE)
