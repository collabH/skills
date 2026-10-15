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
