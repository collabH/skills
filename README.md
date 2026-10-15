# skills

A cross-platform skills repository to manage reusable "skills" (YAML/JSON files), generate documentation, and provide SDK/CLI/demo integrations.

Getting started

1. Add a new skill: create a YAML file under `skills/` (see `skills/example-skill.yml`).
2. Validate skills: `node scripts/validate-skill.js` (requires Node.js 18+)
3. Generate docs: `node scripts/gen-docs.js` -> `docs/skills/*.md`
4. CI will validate and generate docs on push to `main`. Docs are deployed to GitHub Pages.

Contributing

- Create a branch, add or update `skills/*.yml`, open a PR.
