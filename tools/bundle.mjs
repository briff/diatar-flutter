/* Bundles entry.js + @aretino-chant/core into a single IIFE, checked in as
 * assets/aretino/aretino.js in both apps. Diatar's build has no Node step, so
 * the built bundle is the real dependency; re-run `npm run bundle` after
 * bumping the pinned core version in package.json. */
import { build } from 'esbuild';
import { readFileSync, writeFileSync, mkdirSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const repo = join(here, '..');
const core = JSON.parse(readFileSync(join(here, 'node_modules/@aretino-chant/core/package.json'), 'utf8'));
const pinned = JSON.parse(readFileSync(join(here, 'package.json'), 'utf8')).dependencies['@aretino-chant/core'];

if (core.version !== pinned) {
    throw new Error('installed @aretino-chant/core ' + core.version + ' != pinned ' + pinned + '; run npm install');
}

const targets = [
    join(repo, 'Diatar/assets/aretino/aretino.js'),
    join(repo, 'DiaVetito/assets/aretino/aretino.js'),
];

const result = await build({
    entryPoints: [join(here, 'entry.js')],
    bundle: true,
    format: 'iife',
    globalName: 'Aretino',
    // QuickJS on the native side is ES2020-complete; targeting es2020 keeps the
    // output readable and avoids regenerator-style bloat.
    target: ['es2020'],
    legalComments: 'inline',
    write: false,
    banner: { js: '/* @aretino-chant/core ' + core.version + ' - bundled by tools/bundle.mjs, do not edit */' },
    footer: { js: 'Aretino.version = ' + JSON.stringify(core.version) + ';' },
});

const js = result.outputFiles[0].text;
for (const target of targets) {
    mkdirSync(dirname(target), { recursive: true });
    writeFileSync(target, js);
    console.log('wrote ' + target + ' (' + (js.length / 1024).toFixed(1) + ' KB)');
}
