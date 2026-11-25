import { randomUUID } from 'node:crypto';
import os from 'node:os';
import express from 'express';
import multer from 'multer';

const ID_RE =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

function requireAuth(apiKey) {
  return (req, res, next) => {
    // Boş anahtar: herkese açık (uygulama kullanıcılarından gizli anahtar istemez).
    if (!apiKey) {
      next();
      return;
    }
    const header = req.get('authorization') || '';
    const token = header.startsWith('Bearer ') ? header.slice('Bearer '.length) : '';
    if (token !== apiKey) {
      res.status(401).json({ error: 'Yetkisiz.' });
      return;
    }
    next();
  };
}

export function createApp({ jobs, apiKey }) {
  const app = express();
  const upload = multer({
    storage: multer.diskStorage({
      destination: (req, file, cb) => cb(null, os.tmpdir()),
      filename: (req, file, cb) => cb(null, `${randomUUID()}.pdf`),
    }),
    limits: { fileSize: 150 * 1024 * 1024 },
    fileFilter: (req, file, cb) => {
      const name = (file.originalname || '').toLowerCase();
      if (name.endsWith('.pdf') || file.mimetype === 'application/pdf') {
        cb(null, true);
        return;
      }
      cb(new Error('Yalnızca PDF kabul edilir.'));
    },
  });

  app.get('/health', (req, res) => {
    res.json({ ok: true });
  });

  app.use('/v1', requireAuth(apiKey));

  app.post('/v1/conversions', (req, res) => {
    upload.single('file')(req, res, async (err) => {
      if (err) {
        const tooLarge = err.code === 'LIMIT_FILE_SIZE';
        res.status(400).json({
          error: tooLarge ? 'PDF 150 MB sınırını aşıyor.' : err.message,
        });
        return;
      }
      if (!req.file) {
        res.status(400).json({ error: 'PDF dosyası gerekli.' });
        return;
      }
      try {
        const status = await jobs.create(req.file.path);
        res.status(202).json({ id: status.id, status: status.status });
      } catch {
        res.status(500).json({ error: 'İş oluşturulamadı.' });
      }
    });
  });

  app.get('/v1/conversions/:id', async (req, res) => {
    if (!ID_RE.test(req.params.id)) {
      res.status(404).json({ error: 'İş bulunamadı.' });
      return;
    }
    try {
      const status = await jobs.readStatus(req.params.id);
      res.json({
        id: status.id,
        status: status.status,
        error: status.error,
      });
    } catch {
      res.status(404).json({ error: 'İş bulunamadı.' });
    }
  });

  app.get('/v1/conversions/:id/epub', async (req, res) => {
    if (!ID_RE.test(req.params.id)) {
      res.status(404).json({ error: 'İş bulunamadı.' });
      return;
    }
    try {
      const status = await jobs.readStatus(req.params.id);
      if (status.status !== 'ready') {
        res.status(409).json({ error: 'EPUB henüz hazır değil.' });
        return;
      }
      res.download(jobs.epubPath(req.params.id), `${status.id}.epub`);
    } catch {
      res.status(404).json({ error: 'İş bulunamadı.' });
    }
  });

  return app;
}
