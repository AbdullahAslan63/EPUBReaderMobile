import { spawn } from 'node:child_process';

function run(command, args) {
  return new Promise((resolve, reject) => {
    const child = spawn(command, args, { stdio: ['ignore', 'pipe', 'pipe'] });
    let stderr = '';
    child.stderr.on('data', (chunk) => {
      stderr += chunk.toString();
      if (stderr.length > 4000) stderr = stderr.slice(-4000);
    });
    child.on('error', (err) => {
      reject(new Error(`${command} başlatılamadı: ${err.message}`));
    });
    child.on('close', (code) => {
      if (code === 0) {
        resolve();
        return;
      }
      const detail = stderr.trim();
      const message = detail
        ? `${command} çıkış kodu ${code}. ${detail}`
        : `${command} çıkış kodu ${code}.`;
      reject(new Error(message.slice(0, 500)));
    });
  });
}

export function createPipeline({
  langs = 'tur+eng',
  ocrmypdf = 'ocrmypdf',
  ebookConvert = 'ebook-convert',
} = {}) {
  return async function pipeline(paths, hooks) {
    await hooks.onStatus('ocr');
    await run(ocrmypdf, [
      '--skip-text',
      '-l',
      langs,
      '--output-type',
      'pdf',
      paths.input,
      paths.ocr,
    ]);
    await hooks.onStatus('converting');
    await run(ebookConvert, [paths.ocr, paths.epub]);
  };
}
