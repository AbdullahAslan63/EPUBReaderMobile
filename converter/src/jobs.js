import { randomUUID } from 'node:crypto';
import fs from 'node:fs/promises';
import path from 'node:path';

const ACTIVE = new Set(['queued', 'ocr', 'converting']);
const ID_RE =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

async function moveFile(from, to) {
  try {
    await fs.rename(from, to);
  } catch (err) {
    if (err.code !== 'EXDEV') throw err;
    await fs.copyFile(from, to);
    await fs.unlink(from);
  }
}

export function createJobManager({
  root,
  pipeline,
  ttlMs = 24 * 60 * 60 * 1000,
  now = () => Date.now(),
}) {
  const queue = [];
  let pumping = false;

  function jobDir(id) {
    if (!ID_RE.test(id)) {
      throw new Error('Geçersiz iş numarası.');
    }
    const dir = path.resolve(root, id);
    const base = path.resolve(root);
    if (dir !== base && !dir.startsWith(`${base}${path.sep}`)) {
      throw new Error('Geçersiz iş numarası.');
    }
    return dir;
  }

  async function readStatus(id) {
    const raw = await fs.readFile(path.join(jobDir(id), 'status.json'), 'utf8');
    return JSON.parse(raw);
  }

  async function writeStatus(status) {
    const dir = jobDir(status.id);
    await fs.mkdir(dir, { recursive: true });
    const next = { ...status, updatedAt: now() };
    const file = path.join(dir, 'status.json');
    const tmp = `${file}.tmp`;
    await fs.writeFile(tmp, JSON.stringify(next));
    await fs.rename(tmp, file);
    return next;
  }

  function enqueue(id) {
    queue.push(id);
    void pump();
  }

  async function create(inputPdfPath) {
    const id = randomUUID();
    const dir = jobDir(id);
    await fs.mkdir(dir, { recursive: true });
    await moveFile(inputPdfPath, path.join(dir, 'input.pdf'));
    const status = await writeStatus({
      id,
      status: 'queued',
      error: null,
      createdAt: now(),
      updatedAt: now(),
    });
    enqueue(id);
    return status;
  }

  async function pump() {
    if (pumping) return;
    pumping = true;
    try {
      while (queue.length > 0) {
        const id = queue.shift();
        await runOne(id);
      }
    } finally {
      pumping = false;
      if (queue.length > 0) void pump();
    }
  }

  async function runOne(id) {
    const dir = jobDir(id);
    const paths = {
      input: path.join(dir, 'input.pdf'),
      ocr: path.join(dir, 'ocr.pdf'),
      epub: path.join(dir, 'out.epub'),
    };
    try {
      await pipeline(paths, {
        onStatus: async (status) => {
          const current = await readStatus(id);
          current.status = status;
          current.error = null;
          await writeStatus(current);
        },
      });
      const current = await readStatus(id);
      current.status = 'ready';
      current.error = null;
      await writeStatus(current);
    } catch (err) {
      try {
        const current = await readStatus(id);
        current.status = 'failed';
        current.error = String(err.message || err).slice(0, 500);
        await writeStatus(current);
      } catch {
        // İş klasörü silindiyse yeniden oluşturma.
      }
    }
  }

  async function recover() {
    await fs.mkdir(root, { recursive: true });
    const entries = await fs.readdir(root).catch(() => []);
    for (const name of entries) {
      if (!ID_RE.test(name)) continue;
      try {
        const status = await readStatus(name);
        if (ACTIVE.has(status.status)) {
          status.status = 'queued';
          status.error = null;
          await writeStatus(status);
          enqueue(name);
        }
      } catch {
        // Bozuk klasör atlanır.
      }
    }
  }

  async function cleanup() {
    const entries = await fs.readdir(root).catch(() => []);
    for (const name of entries) {
      if (!ID_RE.test(name)) continue;
      try {
        const status = await readStatus(name);
        if (!ACTIVE.has(status.status) && now() - status.updatedAt > ttlMs) {
          await fs.rm(jobDir(name), { recursive: true, force: true });
        }
      } catch {
        // Yok say.
      }
    }
  }

  function epubPath(id) {
    return path.join(jobDir(id), 'out.epub');
  }

  function idle() {
    return !pumping && queue.length === 0;
  }

  return {
    create,
    readStatus,
    recover,
    cleanup,
    epubPath,
    idle,
  };
}
