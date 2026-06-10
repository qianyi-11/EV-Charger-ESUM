import { Router } from 'express';
import multer from 'multer';
import path from 'path';
import fs from 'fs';
import { fileURLToPath } from 'url';
import {
  authMiddleware,
  requireAdmin,
} from '../services/auth_service.js';
import {
  createTicket,
  listTickets,
  getTicketById,
  updateTicket,
  listTicketMessages,
  createAdminTicketMessage,
  ISSUE_TYPES,
  ENGINEERS,
} from '../services/ticket_db.js';
import {
  sendAdminMessageEmail,
  sendTicketReceivedEmail,
} from '../services/email_service.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const uploadsDir = path.join(__dirname, '..', 'data', 'uploads', 'tickets');
if (!fs.existsSync(uploadsDir)) {
  fs.mkdirSync(uploadsDir, { recursive: true });
}

function isAllowedImageUpload(file) {
  if (file.mimetype?.startsWith('image/')) return true;
  if (file.mimetype === 'application/octet-stream') return true;
  const ext = path.extname(file.originalname || '').toLowerCase();
  return ['.jpg', '.jpeg', '.png', '.webp', '.heic', '.heif'].includes(ext);
}

const upload = multer({
  storage: multer.diskStorage({
    destination: uploadsDir,
    filename: (req, file, cb) => {
      const ext = path.extname(file.originalname) || '.jpg';
      const prefix =
        file.fieldname === 'isolatorPhoto'
          ? 'isolator'
          : file.fieldname === 'evdbPhoto'
            ? 'evdb'
            : 'ebox';
      cb(null, `${prefix}_${Date.now()}_${Math.round(Math.random() * 1e9)}${ext}`);
    },
  }),
  limits: { fileSize: 8 * 1024 * 1024 },
  fileFilter: (req, file, cb) => {
    if (isAllowedImageUpload(file)) {
      cb(null, true);
    } else {
      cb(new Error('Only image files are allowed.'));
    }
  },
});

const ticketUpload = upload.fields([
  { name: 'eboxScreenshot', maxCount: 1 },
  { name: 'isolatorPhoto', maxCount: 1 },
  { name: 'evdbPhoto', maxCount: 1 },
]);

function ticketOwnsUploadFilename(tickets, filename) {
  return tickets.some(
    (ticket) =>
      ticket.eboxScreenshotUrl?.endsWith(filename) ||
      ticket.isolatorPhotoUrl?.endsWith(filename) ||
      ticket.evdbPhotoUrl?.endsWith(filename),
  );
}

function parseTicketBody(req) {
  const raw = req.body ?? {};
  if (typeof raw.data === 'string' && raw.data.trim()) {
    return JSON.parse(raw.data);
  }
  return raw;
}

const router = Router();

router.use(authMiddleware);

router.get('/meta', requireAdmin, (req, res) => {
  res.json({ issueTypes: ISSUE_TYPES, engineers: ENGINEERS, statuses: ['open', 'in_progress', 'complete'] });
});

router.post('/diagnosis-photos', (req, res, next) => {
  const kind = req.query.kind === 'evdb' ? 'evdb' : 'isolator';
  multer({
    storage: multer.diskStorage({
      destination: uploadsDir,
      filename: (req, file, cb) => {
        const ext = path.extname(file.originalname) || '.jpg';
        cb(null, `${kind}_${Date.now()}_${Math.round(Math.random() * 1e9)}${ext}`);
      },
    }),
    limits: { fileSize: 8 * 1024 * 1024 },
    fileFilter: (req, file, cb) => {
      if (isAllowedImageUpload(file)) cb(null, true);
      else cb(new Error('Only image files are allowed.'));
    },
  }).single('photo')(req, res, (err) => {
    if (err) return res.status(400).json({ error: err.message });
    next();
  });
}, async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ error: 'No photo uploaded.' });
    }
    res.json({ filename: req.file.filename });
  } catch (error) {
    res.status(500).json({ error: error.message || 'Failed to store diagnosis photo.' });
  }
});

router.post('/', (req, res, next) => {
  ticketUpload(req, res, (err) => {
    if (err) return res.status(400).json({ error: err.message });
    next();
  });
}, async (req, res) => {
  try {
    if (req.user.role !== 'user' && req.user.role !== 'admin') {
      return res.status(403).json({ error: 'Only customers can create tickets.' });
    }

    const body = parseTicketBody(req);
    if (!body.fullName?.trim()) {
      return res.status(400).json({ error: 'Full name is required.' });
    }
    if (!body.faultyComponent?.trim()) {
      return res.status(400).json({ error: 'Faulty component is required.' });
    }

    const files = req.files ?? {};
    const ticket = createTicket(req.user, {
      ...body,
      eboxScreenshotFilename: files.eboxScreenshot?.[0]?.filename ?? null,
      isolatorPhotoFilename:
        files.isolatorPhoto?.[0]?.filename ?? body.isolatorPhotoFilename ?? null,
      evdbPhotoFilename:
        files.evdbPhoto?.[0]?.filename ?? body.evdbPhotoFilename ?? null,
    });

    try {
      await sendTicketReceivedEmail(ticket);
    } catch (emailErr) {
      console.error('[Tickets] Ticket received email failed:', emailErr.message);
    }

    res.status(201).json({ ticket });
  } catch (error) {
    res.status(500).json({ error: error.message || 'Failed to create ticket.' });
  }
});

router.get('/', (req, res) => {
  try {
    const { status, issueType, search } = req.query;
    const isAdmin = req.user.role === 'admin';

    const tickets = listTickets({
      userId: isAdmin ? null : req.user.id,
      status: status || null,
      issueType: issueType || null,
      search: search || null,
    });

    res.json({ tickets });
  } catch (error) {
    res.status(500).json({ error: error.message || 'Failed to list tickets.' });
  }
});

router.get('/uploads/:filename', (req, res) => {
  try {
    const filename = path.basename(req.params.filename);
    const filePath = path.join(uploadsDir, filename);
    if (!fs.existsSync(filePath)) {
      return res.status(404).json({ error: 'Screenshot not found.' });
    }

    if (req.user.role !== 'admin') {
      const ownsFile = ticketOwnsUploadFilename(listTickets({ userId: req.user.id }), filename);
      if (!ownsFile) {
        return res.status(403).json({ error: 'Access denied.' });
      }
    }

    res.sendFile(filePath);
  } catch (error) {
    res.status(500).json({ error: error.message || 'Failed to load screenshot.' });
  }
});

router.get('/:id/messages', (req, res) => {
  try {
    const ticketId = Number(req.params.id);
    const ticket = getTicketById(ticketId);
    if (!ticket) {
      return res.status(404).json({ error: 'Ticket not found.' });
    }
    if (req.user.role !== 'admin' && ticket.userId !== req.user.id) {
      return res.status(403).json({ error: 'Access denied.' });
    }
    res.json({ messages: listTicketMessages(ticketId) });
  } catch (error) {
    res.status(500).json({ error: error.message || 'Failed to load messages.' });
  }
});

router.post('/:id/messages', requireAdmin, async (req, res) => {
  try {
    const ticketId = Number(req.params.id);
    const ticket = getTicketById(ticketId);
    if (!ticket) {
      return res.status(404).json({ error: 'Ticket not found.' });
    }

    const body = (req.body?.body ?? req.body?.message ?? '').trim();
    if (!body) {
      return res.status(400).json({ error: 'Message body is required.' });
    }

    const senderName = (req.body?.senderName ?? 'EVision Support').trim();

    let emailResult = { devMode: true };
    try {
      emailResult = await sendAdminMessageEmail(ticket, body, senderName);
    } catch (emailErr) {
      return res.status(502).json({ error: `Could not send email: ${emailErr.message}` });
    }

    const message = createAdminTicketMessage(ticketId, {
      body,
      senderName,
      emailSent: true,
    });

    res.json({ message, email: emailResult });
  } catch (error) {
    res.status(500).json({ error: error.message || 'Failed to send message.' });
  }
});

router.get('/:id', (req, res) => {
  try {
    const ticket = getTicketById(Number(req.params.id));
    if (!ticket) {
      return res.status(404).json({ error: 'Ticket not found.' });
    }
    if (req.user.role !== 'admin' && ticket.userId !== req.user.id) {
      return res.status(403).json({ error: 'Access denied.' });
    }
    res.json({ ticket });
  } catch (error) {
    res.status(500).json({ error: error.message || 'Failed to get ticket.' });
  }
});

router.patch('/:id', requireAdmin, (req, res) => {
  try {
    const id = Number(req.params.id);
    const existing = getTicketById(id);
    if (!existing) {
      return res.status(404).json({ error: 'Ticket not found.' });
    }

    const { status, assignedEngineer } = req.body ?? {};
    const allowedStatuses = ['open', 'in_progress', 'complete'];
    if (status && !allowedStatuses.includes(status)) {
      return res.status(400).json({ error: 'Invalid status.' });
    }

    const ticket = updateTicket(id, {
      status,
      assignedEngineer: assignedEngineer === 'Unassigned' ? null : assignedEngineer,
    });
    res.json({ ticket });
  } catch (error) {
    res.status(500).json({ error: error.message || 'Failed to update ticket.' });
  }
});

export default router;
