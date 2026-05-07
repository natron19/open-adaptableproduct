# Phase 9 — Pre-Publish Security Check

**Goal:** Verify the app is safe to publish publicly on GitHub. Fix any issues found before pushing.

**Prerequisites:** Phase 8 complete. Full RSpec suite green. All manual tests passing.

---

## Instructions

Run the security review prompt from `docs/prompts/pre-publish-security-check.md`.

Open that file and follow its prompt exactly — it covers:

1. Hardcoded secrets scan
2. `.gitignore` coverage
3. `.env.example` placeholder check
4. `config/database.yml` env var usage
5. `db/seeds.rb` credential check
6. `config/environments/production.rb` secrets check
7. `Gemfile` source verification
8. README for internal infrastructure leaks
9. `log/` and `tmp/` tracked file check
10. Git history for any "add API key" type commits

---

## AdaptableProduct-Specific Items to Verify

Beyond the standard checklist, confirm:

```
[ ] GEMINI_API_KEY is not in any committed file (check .env, any config file, seeds.rb)
[ ] The seeded demo password ("password123") is documented in README as intentional
[ ] No real user email addresses in seeds.rb beyond "demo@example.com"
[ ] APP_NAME / APP_TAGLINE / APP_DESCRIPTION in .env.example are placeholder-appropriate (they are strings, not secrets, but confirm they are the public-facing values, not internal notes)
[ ] The FieldNote seed strategy text is fictional and does not contain real confidential strategy
[ ] No internal URLs (staging URLs, internal tools) appear in views, README, or seeds
[ ] config/master.key is NOT committed (check git status and git log -- config/master.key)
[ ] .kamal/ directory does not contain production credentials (check .kamal/secrets if it exists)
```

---

## Git History Check

Run manually before publishing:

```bash
git log --oneline
git log --all --full-history -- .env
git log --all --full-history -- config/master.key
```

If any commit ever touched `.env` or `config/master.key` with real values, those commits must be removed before publishing (requires a force-push history rewrite — flag this for the user to handle manually, do not attempt automatically).

---

## Final Gate

```
[ ] All items in docs/prompts/pre-publish-security-check.md: PASS
[ ] All AdaptableProduct-specific items above: PASS
[ ] Git history shows no secrets
[ ] bundle exec rspec — still green after any fixes made in this phase
```

When all items are checked and passing, the app is ready to publish.
