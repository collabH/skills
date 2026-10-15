#!/usr/bin/env bash
set -e

# 初始化脚本：在已克隆的 collabH/skills 仓库根目录运行
# 用法：
#   chmod +x init_skills.sh
#   ./init_skills.sh

# 创建目录
mkdir -p skills scripts docs/skills .github/workflows packages/api packages/web packages/cli packages/sdk-js

# skills/example-skill.yml
cat > skills/example-skill.yml <<'YML'
id: example-skill
name: Weather Forecast
version: 1.0.0
description: "Fetch weather forecast for a city using OpenWeatherMap"
tags:
  - info
  - external-api
platforms:
  - web
  - cli
inputs:
  - name: city
    type: string
    required: true
outputs:
  - name: forecast
    type: object
commands:
  - name: getForecast
    description: "Get forecast for a specified city"
    entrypoint: ./scripts/getForecast.js
examples:
  - title: CLI example
    command: "skills-cli run example-skill --city 'Shanghai'"
metadata:
  author: collabH
  license: MIT
  repository: https://github.com/collabH/skills
created_at: 2026-10-15T00:00:00Z
updated_at: 2026-10-15T00:00:00Z
YML

# scripts/gen-docs.js
cat > scripts/gen-docs.js <<'JS'
#!/usr/bin/env node
const fs = require('fs');
const path = require('path');
const yaml = require('js-yaml');

const skillsDir = path.join(__dirname, '..', 'skills');
const outDir = path.join(__dirname, '..', 'docs', 'skills');
if (!fs.existsSync(outDir)) fs.mkdirSync(outDir, { recursive: true });

function toMarkdown(skill) {
  const lines = [];
  lines.push(`# ${skill.name} (${skill.id})`);
  if (skill.description) lines.push(`\n${skill.description}\n`);
  lines.push('## Metadata');
  lines.push(`- Version: ${skill.version || 'N/A'}`);
  lines.push(`- Author: ${skill.metadata?.author || 'N/A'}`);
  lines.push(`- License: ${skill.metadata?.license || 'N/A'}`);
  lines.push(`- Platforms: ${ (skill.platforms || []).join(', ') || 'N/A' }`);
  lines.push(`- Tags: ${ (skill.tags || []).join(', ') || 'N/A' }`);
  if (skill.inputs) {
    lines.push('\n## Inputs');
    skill.inputs.forEach(i => {
      lines.push(`- **${i.name}** (${i.type}) ${i.required ? '(required)' : ''} ${i.description || ''}`);
    });
  }
  if (skill.commands) {
    lines.push('\n## Commands');
    skill.commands.forEach(c => {
      lines.push(`- **${c.name}**: ${c.description || ''}`);
    });
  }
  if (skill.examples) {
    lines.push('\n## Examples');
    skill.examples.forEach(e => {
      lines.push(`### ${e.title}\n`);
      if (e.command) lines.push('```bash\n' + e.command + '\n```');
      if (e.description) lines.push(e.description);
    });
  }
  return lines.join('\n');
}

fs.readdirSync(skillsDir).forEach(file => {
  if (!file.endsWith('.yml') && !file.endsWith('.yaml') && !file.endsWith('.json')) return;
  const full = path.join(skillsDir, file);
  const content = fs.readFileSync(full, 'utf8');
  let skill;
  try {
    skill = yaml.load(content);
  } catch (err) {
    console.error(`Failed to parse ${file}:`, err.message);
    return;
  }
  if (!skill || !skill.id) {
    console.warn(`Skipping ${file}: missing id`);
    return;
  }
  const md = toMarkdown(skill);
  const outPath = path.join(outDir, `${skill.id}.md`);
  fs.writeFileSync(outPath, md, 'utf8');
  console.log(`Generated ${outPath}`);
});
JS
chmod +x scripts/gen-docs.js

# scripts/validate-skill.js
cat > scripts/validate-skill.js <<'JS'
#!/usr/bin/env node
const fs = require('fs');
const path = require('path');
const yaml = require('js-yaml');
const Ajv = require('ajv');

const schema = {
  type: 'object',
  required: ['id','name','version','description'],
  properties: {
    id: { type: 'string' },
    name: { type: 'string' },
    version: { type: 'string' },
    description: { type: 'string' },
    platforms: { type: 'array' },
    tags: { type: 'array' }
  }
};
const ajv = new Ajv();
const validate = ajv.compile(schema);

const skillsDir = path.join(__dirname, '..', 'skills');
let ok = true;
fs.readdirSync(skillsDir).forEach(file => {
  if (!file.endsWith('.yml') && !file.endsWith('.yaml') && !file.endsWith('.json')) return;
  const full = path.join(skillsDir, file);
  const content = fs.readFileSync(full, 'utf8');
  let skill;
  try {
    skill = yaml.load(content);
  } catch (err) {
    console.error(`Parse error in ${file}: ${err.message}`);
    ok = false;
    return;
  }
  const valid = validate(skill);
  if (!valid) {
    console.error(`Validation failed for ${file}:`, validate.errors);
    ok = false;
  } else {
    console.log(`Validated ${file}`);
  }
});
if (!ok) process.exit(1);
JS
chmod +x scripts/validate-skill.js

# .github/workflows/ci.yml
cat > .github/workflows/ci.yml <<'YML'
name: CI
on:
  push:
    branches: [ main ]
    paths:
      - 'skills/**'
      - 'scripts/**'
      - 'packages/**'
      - '.github/workflows/**'
jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Setup Node
        uses: actions/setup-node@v4
        with:
          node-version: '18'
      - name: Install deps
        run: |
          npm ci || true
          npm i js-yaml ajv --no-save
      - name: Validate skills
        run: node scripts/validate-skill.js
YML

# .github/workflows/docs-deploy.yml
cat > .github/workflows/docs-deploy.yml <<'YML'
name: Generate Docs & Deploy to GitHub Pages
on:
  push:
    branches: [ main ]
    paths:
      - 'skills/**'
      - 'scripts/**'
jobs:
  gen-and-deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Setup Node
        uses: actions/setup-node@v4
        with:
          node-version: '18'
      - name: Install deps
        run: npm i js-yaml --no-save
      - name: Generate docs
        run: node scripts/gen-docs.js
      - name: Commit docs
        run: |
          git config user.name "github-actions[bot]"
          git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
          git add docs || true
          git commit -m "chore(docs): regenerate docs" || echo "no changes"
          git push
      - name: Deploy to GitHub Pages
        uses: peaceiris/actions-gh-pages@v3
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: ./docs
YML

# README.md (overwrite)
cat > README.md <<'MD'
# skills

A cross-platform skills repository to manage reusable "skills" (YAML/JSON files), generate documentation, and provide SDK/CLI/demo integrations.

Getting started

1. Add a new skill: create a YAML file under `skills/` (see `skills/example-skill.yml`).
2. Validate skills: `node scripts/validate-skill.js` (requires Node.js 18+)
3. Generate docs: `node scripts/gen-docs.js` -> `docs/skills/*.md`
4. CI will validate and generate docs on push to `main`. Docs are deployed to GitHub Pages.

Contributing

- Create a branch, add or update `skills/*.yml`, open a PR.
MD

# Commit & push
git add .
git commit -m "chore: init skills repo template (skills, scripts, workflows, docs)" || true
git push origin main
echo "Done."
