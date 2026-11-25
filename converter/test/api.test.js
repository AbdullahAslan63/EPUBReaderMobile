import assert from 'node:assert/strict';
import fs from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import test from 'node:test';
import { createApp } from '../src/app.js';
import { createJobManager } from '../src/jobs.js';

async function waitFor(check, attempts = 50) {
  for (let i = 0; i < attempts; i += 1) {
    if (await check()) return;
    await new Promise((resolve) => setTimeout(resolve, 20));
  }
  throw new Error('zaman aşımı');
}

function deferred() {
  let resolve;
  const promise = new Promise((done) => {
    resolve = done;
  });
  return { promise, resolve };
}

async function listen(app) {
  const server = app.listen(0, '127.0.0.1');
  await new Promise((resolve) => server.once('listening', resolve));
  const { port } = server.address();
  return { server, url: `http://127.0.0.1:${port}` };
}

test('anahtar doluyken yetkisiz 401, sağlık ucu açık', async () => {
  const root = await fs.mkdtemp(path.join(os.tmpdir(), 'conv-auth-'));
  const jobs = createJobManager({
    root,
    pipeline: async () => {},
  });
  const { server, url } = await listen(createApp({ jobs, apiKey: 'secret' }));
  try {
    const health = await fetch(`${url}/health`);
    assert.equal(health.status, 200);

    const denied = await fetch(`${url}/v1/conversions/00000000-0000-4000-8000-000000000001`);
    assert.equal(denied.status, 401);
    const body = await denied.json();
    assert.equal(body.error, 'Yetkisiz.');
  } finally {
    await new Promise((resolve) => server.close(resolve));
    await fs.rm(root, { recursive: true, force: true });
  }
});

test('anahtar boşken uçlar herkese açık', async () => {
  const root = await fs.mkdtemp(path.join(os.tmpdir(), 'conv-open-'));
  const jobs = createJobManager({
    root,
    pipeline: async (paths, hooks) => {
      await hooks.onStatus('ocr');
      await hooks.onStatus('converting');
      await fs.writeFile(paths.epub, 'OPEN');
    },
  });
  const { server, url } = await listen(createApp({ jobs, apiKey: '' }));
  try {
    const form = new FormData();
    form.append(
      'file',
      new Blob([Buffer.from('%PDF-1.4')], { type: 'application/pdf' }),
      'a.pdf',
    );
    const created = await fetch(`${url}/v1/conversions`, {
      method: 'POST',
      body: form,
    });
    assert.equal(created.status, 202);
    const { id } = await created.json();
    await waitFor(async () => {
      const response = await fetch(`${url}/v1/conversions/${id}`);
      const body = await response.json();
      return body.status === 'ready';
    });
    const epub = await fetch(`${url}/v1/conversions/${id}/epub`);
    assert.equal(epub.status, 200);
    assert.equal(await epub.text(), 'OPEN');
  } finally {
    await new Promise((resolve) => server.close(resolve));
    await fs.rm(root, { recursive: true, force: true });
  }
});

test('kuyruk tek tek çalışır, EPUB hazır olunca iner', async () => {
  const root = await fs.mkdtemp(path.join(os.tmpdir(), 'conv-queue-'));
  let active = 0;
  let maxActive = 0;
  const gate = deferred();
  let started = 0;
  const jobs = createJobManager({
    root,
    pipeline: async (paths, hooks) => {
      started += 1;
      active += 1;
      maxActive = Math.max(maxActive, active);
      await hooks.onStatus('ocr');
      if (started === 1) await gate.promise;
      await hooks.onStatus('converting');
      await fs.writeFile(paths.epub, 'EPUB-BYTES');
      active -= 1;
    },
  });
  const { server, url } = await listen(createApp({ jobs, apiKey: 'secret' }));
  try {
    async function upload(name) {
      const form = new FormData();
      form.append(
        'file',
        new Blob([Buffer.from('%PDF-1.4')], { type: 'application/pdf' }),
        name,
      );
      const response = await fetch(`${url}/v1/conversions`, {
        method: 'POST',
        headers: { Authorization: 'Bearer secret' },
        body: form,
      });
      assert.equal(response.status, 202);
      return response.json();
    }

    const first = await upload('a.pdf');
    const second = await upload('b.pdf');
    await waitFor(() => started === 1);
    assert.equal(started, 1);
    gate.resolve();
    await waitFor(async () => {
      const a = await fetch(`${url}/v1/conversions/${first.id}`, {
        headers: { Authorization: 'Bearer secret' },
      });
      const b = await fetch(`${url}/v1/conversions/${second.id}`, {
        headers: { Authorization: 'Bearer secret' },
      });
      const aBody = await a.json();
      const bBody = await b.json();
      return aBody.status === 'ready' && bBody.status === 'ready';
    });
    assert.equal(maxActive, 1);

    const early = await fetch(`${url}/v1/conversions/${first.id}/epub`, {
      headers: { Authorization: 'Bearer secret' },
    });
    assert.equal(early.status, 200);
    assert.equal(await early.text(), 'EPUB-BYTES');
  } finally {
    await new Promise((resolve) => server.close(resolve));
    await fs.rm(root, { recursive: true, force: true });
  }
});

test('boru hattı hatası işi failed yapar', async () => {
  const root = await fs.mkdtemp(path.join(os.tmpdir(), 'conv-fail-'));
  const jobs = createJobManager({
    root,
    pipeline: async () => {
      throw new Error('ocr patladı');
    },
  });
  const { server, url } = await listen(createApp({ jobs, apiKey: 'secret' }));
  try {
    const form = new FormData();
    form.append(
      'file',
      new Blob([Buffer.from('%PDF-1.4')], { type: 'application/pdf' }),
      'a.pdf',
    );
    const created = await fetch(`${url}/v1/conversions`, {
      method: 'POST',
      headers: { Authorization: 'Bearer secret' },
      body: form,
    });
    const { id } = await created.json();
    await waitFor(async () => {
      const response = await fetch(`${url}/v1/conversions/${id}`, {
        headers: { Authorization: 'Bearer secret' },
      });
      const body = await response.json();
      return body.status === 'failed' && body.error.includes('ocr patladı');
    });
    const epub = await fetch(`${url}/v1/conversions/${id}/epub`, {
      headers: { Authorization: 'Bearer secret' },
    });
    assert.equal(epub.status, 409);
  } finally {
    await new Promise((resolve) => server.close(resolve));
    await fs.rm(root, { recursive: true, force: true });
  }
});

test('yarıda kalan iş açılışta kuyruğa döner ve süresi dolan silinir', async () => {
  const root = await fs.mkdtemp(path.join(os.tmpdir(), 'conv-recover-'));
  const id = '11111111-1111-4111-8111-111111111111';
  const dir = path.join(root, id);
  await fs.mkdir(dir, { recursive: true });
  await fs.writeFile(path.join(dir, 'input.pdf'), '%PDF');
  const past = Date.now() - 10_000;
  await fs.writeFile(
    path.join(dir, 'status.json'),
    JSON.stringify({
      id,
      status: 'ocr',
      error: null,
      createdAt: past,
      updatedAt: past,
    }),
  );

  let ran = false;
  const jobs = createJobManager({
    root,
    ttlMs: 1000,
    pipeline: async (paths, hooks) => {
      ran = true;
      await hooks.onStatus('converting');
      await fs.writeFile(paths.epub, 'ok');
    },
  });
  await jobs.recover();
  await waitFor(async () => {
    const status = await jobs.readStatus(id);
    return status.status === 'ready';
  });
  assert.equal(ran, true);

  const staleId = '22222222-2222-4222-8222-222222222222';
  const staleDir = path.join(root, staleId);
  await fs.mkdir(staleDir, { recursive: true });
  await fs.writeFile(
    path.join(staleDir, 'status.json'),
    JSON.stringify({
      id: staleId,
      status: 'ready',
      error: null,
      createdAt: past,
      updatedAt: past,
    }),
  );
  await jobs.cleanup();
  await assert.rejects(jobs.readStatus(staleId));
  const kept = await jobs.readStatus(id);
  assert.equal(kept.status, 'ready');
  await fs.rm(root, { recursive: true, force: true });
});
