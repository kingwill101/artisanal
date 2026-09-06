// Syncs the Examples docs section from the registry in examples.json.
//
// For each registry entry this script:
//   1. reads the real example source (like dart_tui's readExampleSource),
//      so published code samples never drift from code that runs;
//   2. copies the VHS-recorded GIF into website/static/gifs/;
//   3. writes docs/examples/<category>/<slug>.md with Preview/Code tabs
//      (Docusaurus <Tabs>) plus a "Run it" block.
//
// Generated output (docs/examples/, website/static/gifs/) is gitignored and
// rebuilt by `npm run sync:examples`, which also runs automatically before
// `npm run build` and `npm start` via prebuild/prestart hooks.
// To add an example: record its GIF (see pkgs/*/example/.vhs/README.md),
// then append one entry to examples.json.
import {
  copyFileSync,
  existsSync,
  mkdirSync,
  readFileSync,
  rmSync,
  writeFileSync,
} from 'node:fs';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';

const websiteDir = join(fileURLToPath(import.meta.url), '..', '..');
const repoRoot = join(websiteDir, '..');
const docsExamplesDir = join(repoRoot, 'docs', 'examples');
const gifsDir = join(websiteDir, 'static', 'gifs');

const registry = JSON.parse(
  readFileSync(join(websiteDir, 'scripts', 'examples.json'), 'utf8'),
);

// Fence the injected source with one more backtick than its longest run,
// so Dart doc comments containing ```dart blocks can't break the page.
function fenceFor(source) {
  const runs = source.match(/`+/g) ?? [];
  const longest = runs.reduce((max, run) => Math.max(max, run.length), 0);
  return '`'.repeat(Math.max(3, longest + 1));
}

function frontmatterValue(text) {
  return JSON.stringify(text);
}

function pageFor(entry, gifFile, fence, source) {
  return `---
title: ${frontmatterValue(entry.title)}
description: ${frontmatterValue(entry.tagline)}
sidebar_position: ${entry.order ?? 999}
---
import Tabs from '@theme/Tabs';
import TabItem from '@theme/TabItem';

${entry.tagline}

<Tabs>
<TabItem value="preview" label="Preview" default>

![${entry.title} demo](/gifs/${gifFile})

</TabItem>
<TabItem value="code" label="Code">

${fence}dart title="${entry.source}"
${source}
${fence}

</TabItem>
</Tabs>

## Run it

${fence}bash
${entry.run}
${fence}
`;
}

rmSync(docsExamplesDir, { recursive: true, force: true });
mkdirSync(docsExamplesDir, { recursive: true });
mkdirSync(gifsDir, { recursive: true });

// Category landing pages (generated so sidebar order matches the registry).
const categorySlugs = Object.keys(registry.categories);
for (const [index, slug] of categorySlugs.entries()) {
  const category = registry.categories[slug];
  const dir = join(docsExamplesDir, slug);
  mkdirSync(dir, { recursive: true });
  writeFileSync(
    join(dir, '_category_.json'),
    JSON.stringify(
      { label: category.label, position: index + 1, description: category.description },
      null,
      2,
    ) + '\n',
  );
}

let failures = 0;
for (const entry of registry.entries) {
  const sourcePath = join(repoRoot, entry.source);
  const gifPath = join(repoRoot, entry.gif);
  if (!existsSync(sourcePath)) {
    console.error(`missing source for ${entry.slug}: ${entry.source}`);
    failures += 1;
    continue;
  }
  if (!existsSync(gifPath)) {
    console.error(`missing GIF for ${entry.slug}: ${entry.gif}`);
    failures += 1;
    continue;
  }
  const gifFile = `${entry.category}_${entry.slug}.gif`;
  copyFileSync(gifPath, join(gifsDir, gifFile));
  const source = readFileSync(sourcePath, 'utf8').trimEnd();
  const fence = fenceFor(source);
  writeFileSync(
    join(docsExamplesDir, entry.category, `${entry.slug}.md`),
    pageFor(entry, gifFile, fence, source),
  );
  console.log(`synced examples/${entry.category}/${entry.slug}.md`);
}

if (failures > 0) {
  console.error(`${failures} example(s) missing source or GIF`);
  process.exit(1);
}
