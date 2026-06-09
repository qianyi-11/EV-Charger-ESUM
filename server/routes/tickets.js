import { Router } from 'express';
import {
  authMiddleware,
  requireAdmin,
} from '../services/auth_service.js';
import {
  createTicket,
  listTickets,
  getTicketById,
  updateTicket,
  ISSUE_TYPES,
  ENGINEERS,
} from '../services/ticket_db.js';

const router = Router();

router.use(authMiddleware);

router.get('/meta', requireAdmin, (req, res) => {
  res.json({ issueTypes: ISSUE_TYPES, engineers: ENGINEERS, statuses: ['open', 'in_progress', 'complete'] });
});

router.post('/', (req, res) => {
  try {
    if (req.user.role !== 'user' && req.user.role !== 'admin') {
      return res.status(403).json({ error: 'Only customers can create tickets.' });
    }

    const body = req.body ?? {};
    if (!body.fullName?.trim()) {
      return res.status(400).json({ error: 'Full name is required.' });
    }
    if (!body.faultyComponent?.trim()) {
      return res.status(400).json({ error: 'Faulty component is required.' });
    }

    const ticket = createTicket(req.user, body);
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
