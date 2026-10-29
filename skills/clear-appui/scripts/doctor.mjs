#!/usr/bin/env node
import { readFile, access } from 'node:fs/promises';
import { resolve, join } from 'node:path';
import { pathToFileURL, fileURLToPath } from 'node:url';
import { createHash } from 'node:crypto';

async function exists(path) {
  try { await access(path); return true; } catch { return false; }
}

async function main() {
  let project = resolve(process.argv[2] ?? process.cwd());
  if (!(await exists(join(project, 'pubspec.yaml'))) &&
      await exists(join(project, 'Flutter/pubspec.yaml'))) {
    project = join(project, 'Flutter');
  }
  const configPath = join(project, '.dart_tool/package_config.json');
  if (!(await exists(configPath))) {
    throw new Error(`Run flutter pub get in ${project} before using the skill.`);
  }
  const config = JSON.parse(await readFile(configPath, 'utf8'));
  const entry = config.packages.find((item) => item.name === 'fossui');
  if (!entry) throw new Error('Install the Clear AppUI Git dependency (fossui) first.');
  const packageRoot = fileURLToPath(new URL(entry.rootUri, pathToFileURL(configPath)));
  const contractPath = join(packageRoot, 'doc/app_ui/agent-contract.json');
  if (!(await exists(contractPath))) {
    throw new Error('This fossui dependency has no Clear AppUI contract. Check its Git source and revision.');
  }
  const contract = JSON.parse(await readFile(contractPath, 'utf8'));
  const expected = JSON.parse(await readFile(new URL('../references/api-contract.json', import.meta.url), 'utf8'));
  if (contract.contractVersion !== expected.contractVersion || contract.package !== expected.package) {
    throw new Error(`API contract mismatch. Read ${join(packageRoot, contract.bundledSkill)} and use its bundled doctor.`);
  }
  const productApi = join(packageRoot, contract.productEntrypoint);
  const legacyApi = join(packageRoot, contract.legacyEntrypoint);
  const bundledSkill = join(packageRoot, contract.bundledSkill);
  for (const path of [productApi, legacyApi, bundledSkill]) {
    if (!(await exists(path))) throw new Error(`Installed package is incomplete: ${path}`);
  }
  const digest = (value) => createHash('sha256').update(value).digest('hex');
  const currentSkill = await readFile(new URL('../SKILL.md', import.meta.url));
  const installedSkill = await readFile(bundledSkill);
  const lockPath = join(project, 'pubspec.lock');
  const lock = await exists(lockPath) ? await readFile(lockPath, 'utf8') : '';
  const block = lock.match(/^  fossui:\n([\s\S]*?)(?=^  \w+:|^sdks:|$(?![\s\S]))/m)?.[1] ?? '';
  const gitResolvedRef = block.match(/resolved-ref:\s*["']?([a-f0-9]{40})/)?.[1] ?? null;
  process.stdout.write(JSON.stringify({
    projectRoot: project,
    packageRoot,
    contractVersion: contract.contractVersion,
    gitResolvedRef,
    productApi,
    legacyApi,
    bundledSkill,
    skillMatchesPackage: digest(currentSkill) === digest(installedSkill),
    implementationDirectory: join(packageRoot, 'lib/src/app_ui'),
    higNotes: join(packageRoot, 'doc/app_ui/APPLE_HIG_NOTES.md'),
    designGuide: join(packageRoot, 'doc/app_ui/DESIGN_STYLE.md'),
  }, null, 2) + '\n');
}

main().catch((error) => {
  process.stderr.write(`Clear AppUI: ${error.message}\n`);
  process.exitCode = 1;
});
