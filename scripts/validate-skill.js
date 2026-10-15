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
