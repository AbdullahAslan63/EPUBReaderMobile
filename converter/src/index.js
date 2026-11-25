import path from 'node:path';
import { createApp } from './app.js';
import { createJobManager } from './jobs.js';
import { createPipeline } from './pipeline.js';

const root = process.env.CONVERTER_DATA_DIR || path.join(process.cwd(), 'data');
const apiKey = process.env.CONVERTER_API_KEY || '';
const langs = process.env.OCR_LANGS || 'tur+eng';
const ttlHours = Number(process.env.CONVERTER_JOB_TTL_HOURS || 24);
const host = process.env.HOST || '0.0.0.0';
const port = Number(process.env.PORT || 8080);

const jobs = createJobManager({
  root,
  pipeline: createPipeline({ langs }),
  ttlMs: ttlHours * 60 * 60 * 1000,
});

await jobs.recover();
setInterval(() => {
  jobs.cleanup().catch(() => {});
}, 60 * 60 * 1000);

const app = createApp({ jobs, apiKey });
app.listen(port, host, () => {
  process.stdout.write(`converter listening on ${host}:${port}\n`);
});
