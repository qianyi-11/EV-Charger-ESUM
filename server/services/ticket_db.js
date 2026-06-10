import path from 'path';
import { fileURLToPath } from 'url';
import fs from 'fs';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const dataDir = path.join(__dirname, '..', 'data');
if (!fs.existsSync(dataDir)) fs.mkdirSync(dataDir, { recursive: true });

const storePath = path.join(dataDir, 'store.json');

function defaultStore() {
  return {
    users: [],
    tickets: [],
    ticketMessages: [],
    resetCodes: [],
    counters: { userId: 0, ticketId: 0, ticketNumber: 1000, resetCodeId: 0, messageId: 0 },
  };
}

function ensureStoreShape(store) {
  if (!Array.isArray(store.ticketMessages)) store.ticketMessages = [];
  store.counters ??= {};
  if (store.counters.messageId == null) store.counters.messageId = 0;
  return store;
}

function loadStore() {
  if (!fs.existsSync(storePath)) {
    const store = defaultStore();
    saveStore(store);
    return store;
  }
  try {
    return ensureStoreShape(JSON.parse(fs.readFileSync(storePath, 'utf8')));
  } catch {
    const store = defaultStore();
    saveStore(store);
    return store;
  }
}

function saveStore(store) {
  fs.writeFileSync(storePath, JSON.stringify(store, null, 2), 'utf8');
}

function withStore(mutator) {
  const store = loadStore();
  const result = mutator(store);
  saveStore(store);
  return result;
}

/** Normalize issue type for filtering / display */
export function resolveIssueType(faultyComponent, describeIssue, details) {
  if (describeIssue && describeIssue.trim()) return describeIssue.trim();
  if (faultyComponent === 'Isolator') return 'Isolator OFF';
  if (faultyComponent === 'EVDB' && details) return details.split('.')[0].trim();
  if (faultyComponent === 'Other') return 'Other';
  return faultyComponent || 'Other';
}

function rowToMessage(row) {
  if (!row) return null;
  return {
    id: String(row.id),
    ticketId: String(row.ticket_id),
    direction: row.direction,
    body: row.body,
    senderName: row.sender_name,
    senderEmail: row.sender_email,
    attachmentUrl: row.attachment_filename
      ? `/api/tickets/uploads/${row.attachment_filename}`
      : null,
    attachmentType: row.attachment_type || null,
    viaEmail: Boolean(row.via_email),
    emailSent: Boolean(row.email_sent),
    createdAt: row.created_at,
  };
}

function rowToTicket(row) {
  if (!row) return null;
  return {
    id: String(row.id),
    ticketNumber: row.ticket_number,
    ticketId: `#${row.ticket_number}`,
    userId: row.user_id,
    userEmail: row.user_email,
    salutation: row.salutation,
    fullName: row.full_name,
    contactNumber: row.contact_number,
    address: row.address,
    carBrand: row.car_brand,
    carBrandOther: row.car_brand_other,
    installedWithRexharge: row.installed_with_rexharge,
    chargerBrand: row.charger_brand,
    chargerBrandOther: row.charger_brand_other,
    chargerSerialNumber: row.charger_serial_number,
    installationDate: row.installation_date,
    faultyComponent: row.faulty_component,
    describeIssue: row.describe_issue,
    issueType: row.issue_type,
    details: row.details,
    sourceErrorCode: row.source_error_code,
    eboxScreenshotUrl: row.ebox_screenshot
      ? `/api/tickets/uploads/${row.ebox_screenshot}`
      : null,
    isolatorPhotoUrl: row.isolator_photo
      ? `/api/tickets/uploads/${row.isolator_photo}`
      : null,
    evdbPhotoUrl: row.evdb_photo
      ? `/api/tickets/uploads/${row.evdb_photo}`
      : null,
    status: row.status,
    assignedEngineer: row.assigned_engineer,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
}

export function findUserByEmail(email) {
  const store = loadStore();
  const normalized = email.trim().toLowerCase();
  return store.users.find((u) => u.email.toLowerCase() === normalized) ?? null;
}

export function findUserById(id) {
  const store = loadStore();
  return store.users.find((u) => u.id === id) ?? null;
}

export function createUser({ email, passwordHash, firstName, lastName, phone, role }) {
  return withStore((store) => {
    store.counters.userId += 1;
    const user = {
      id: store.counters.userId,
      email: email.trim(),
      password_hash: passwordHash,
      first_name: firstName,
      last_name: lastName,
      phone,
      role,
      created_at: new Date().toISOString(),
    };
    store.users.push(user);
    return user;
  });
}

export function getNextTicketNumber(store) {
  store.counters.ticketNumber += 1;
  return store.counters.ticketNumber;
}

function appendEboxToDetails(details, hasScreenshot) {
  let text = (details ?? '').trim();
  if (!hasScreenshot) return text;
  const note = '[e.Box app screenshot attached — see Details below]';
  if (text.includes(note)) return text;
  return text ? `${text}\n\n${note}` : note;
}

export function addTicketMessage(store, {
  ticketId,
  direction,
  body,
  senderName,
  senderEmail,
  attachmentFilename = null,
  attachmentType = null,
  viaEmail = false,
  emailSent = false,
}) {
  ensureStoreShape(store);
  store.counters.messageId += 1;
  const now = new Date().toISOString();
  const row = {
    id: store.counters.messageId,
    ticket_id: Number(ticketId),
    direction,
    body: (body ?? '').trim(),
    sender_name: senderName ?? '',
    sender_email: senderEmail ?? '',
    attachment_filename: attachmentFilename,
    attachment_type: attachmentType,
    via_email: viaEmail ? 1 : 0,
    email_sent: emailSent ? 1 : 0,
    created_at: now,
  };
  store.ticketMessages.push(row);

  const ticket = store.tickets.find((t) => t.id === Number(ticketId));
  if (ticket) ticket.updated_at = now;

  return rowToMessage(row);
}

export function listTicketMessages(ticketId) {
  const store = ensureStoreShape(loadStore());
  return store.ticketMessages
    .filter((m) => m.ticket_id === Number(ticketId))
    .sort((a, b) => new Date(a.created_at) - new Date(b.created_at))
    .map(rowToMessage);
}

export function createAdminTicketMessage(ticketId, { body, senderName, emailSent = true }) {
  return withStore((store) => {
    const ticketRow = store.tickets.find((t) => t.id === Number(ticketId));
    if (!ticketRow) return null;
    return addTicketMessage(store, {
      ticketId,
      direction: 'admin',
      body,
      senderName: senderName || 'EVision Support',
      emailSent,
    });
  });
}

export function findTicketByNumber(ticketNumber) {
  const store = loadStore();
  const row = store.tickets.find((t) => t.ticket_number === Number(ticketNumber));
  return rowToTicket(row);
}

export function recordInboundCustomerEmail({
  ticketInternalId,
  ticketNumber,
  fromEmail,
  body,
  senderName,
}) {
  return withStore((store) => {
    let ticketRow = null;
    if (ticketInternalId) {
      ticketRow = store.tickets.find((t) => t.id === Number(ticketInternalId));
    } else if (ticketNumber) {
      ticketRow = store.tickets.find((t) => t.ticket_number === Number(ticketNumber));
    }
    if (!ticketRow) return null;

    if (fromEmail && ticketRow.user_email.toLowerCase() !== fromEmail.trim().toLowerCase()) {
      const err = new Error('Sender email does not match the ticket owner.');
      err.code = 'EMAIL_MISMATCH';
      throw err;
    }

    return addTicketMessage(store, {
      ticketId: ticketRow.id,
      direction: 'customer',
      body,
      senderName: senderName || ticketRow.full_name,
      senderEmail: fromEmail || ticketRow.user_email,
      viaEmail: true,
    });
  });
}

export function createTicket(user, payload) {
  return withStore((store) => {
    const ticketNumber = getNextTicketNumber(store);
    store.counters.ticketId += 1;
    const now = new Date().toISOString();
    const hasScreenshot = Boolean(payload.eboxScreenshotFilename);
    const mergedDetails = appendEboxToDetails(payload.details, hasScreenshot);
    const issueType = resolveIssueType(
      payload.faultyComponent,
      payload.describeIssue,
      mergedDetails,
    );

    const row = {
      id: store.counters.ticketId,
      ticket_number: ticketNumber,
      user_id: user.id,
      user_email: user.email,
      salutation: payload.salutation ?? '',
      full_name: payload.fullName,
      contact_number: payload.contactNumber ?? '',
      address: payload.address ?? '',
      car_brand: payload.carBrand ?? '',
      car_brand_other: payload.carBrandOther ?? null,
      installed_with_rexharge: payload.installedWithRexharge ?? '',
      charger_brand: payload.chargerBrand ?? '',
      charger_brand_other: payload.chargerBrandOther ?? null,
      charger_serial_number: payload.chargerSerialNumber ?? '',
      installation_date: payload.installationDate ?? null,
      faulty_component: payload.faultyComponent ?? '',
      describe_issue: payload.describeIssue ?? null,
      issue_type: issueType,
      details: mergedDetails,
      source_error_code: payload.sourceErrorCode ?? null,
      ebox_screenshot: payload.eboxScreenshotFilename ?? null,
      isolator_photo: payload.isolatorPhotoFilename || null,
      evdb_photo: payload.evdbPhotoFilename || null,
      status: 'open',
      assigned_engineer: null,
      created_at: now,
      updated_at: now,
    };

    store.tickets.push(row);

    return rowToTicket(row);
  });
}

export function getTicketById(id) {
  const store = loadStore();
  const row = store.tickets.find((t) => t.id === Number(id));
  return rowToTicket(row);
}

export function listTickets({ userId = null, status = null, issueType = null, search = null } = {}) {
  const store = loadStore();
  let rows = [...store.tickets];

  if (userId != null) {
    rows = rows.filter((t) => t.user_id === userId);
  }
  if (status && status !== 'all') {
    rows = rows.filter((t) => t.status === status);
  }
  if (issueType && issueType !== 'all') {
    rows = rows.filter((t) => t.issue_type === issueType);
  }
  if (search && search.trim()) {
    const q = search.trim().toLowerCase();
    rows = rows.filter((t) =>
      String(t.ticket_number).includes(q) ||
      (t.full_name || '').toLowerCase().includes(q) ||
      (t.charger_brand || '').toLowerCase().includes(q) ||
      (t.issue_type || '').toLowerCase().includes(q) ||
      (t.user_email || '').toLowerCase().includes(q),
    );
  }

  rows.sort((a, b) => new Date(b.created_at) - new Date(a.created_at));
  return rows.map(rowToTicket);
}

export function updateTicket(id, { status, assignedEngineer }) {
  return withStore((store) => {
    const row = store.tickets.find((t) => t.id === Number(id));
    if (!row) return null;

    if (status) row.status = status;
    if (assignedEngineer !== undefined) {
      row.assigned_engineer = assignedEngineer || null;
    }
    row.updated_at = new Date().toISOString();
    return rowToTicket(row);
  });
}

export const ENGINEERS = ['Unassigned', 'Razif', 'Ahmad', 'Siti', 'Kumar'];

export function createResetCode(email, code, expiresMinutes = 30) {
  return withStore((store) => {
    const normalized = email.trim().toLowerCase();
    store.resetCodes.forEach((r) => {
      if (r.email.toLowerCase() === normalized && !r.used) r.used = 1;
    });

    const expiresAt = new Date(Date.now() + expiresMinutes * 60 * 1000).toISOString();
    store.counters.resetCodeId += 1;
    store.resetCodes.push({
      id: store.counters.resetCodeId,
      email: email.trim(),
      code,
      expires_at: expiresAt,
      used: 0,
      created_at: new Date().toISOString(),
    });
    return { code, expiresAt };
  });
}

export function consumeResetCode(email, code) {
  return withStore((store) => {
    const normalized = email.trim().toLowerCase();
    const matches = store.resetCodes
      .filter((r) =>
        r.email.toLowerCase() === normalized &&
        r.code === code.trim() &&
        !r.used,
      )
      .sort((a, b) => b.id - a.id);

    const row = matches[0];
    if (!row) return false;
    if (new Date(row.expires_at).getTime() < Date.now()) return false;
    row.used = 1;
    return true;
  });
}

export function updateUserPassword(email, passwordHash) {
  return withStore((store) => {
    const normalized = email.trim().toLowerCase();
    const user = store.users.find((u) => u.email.toLowerCase() === normalized);
    if (!user) return;
    user.password_hash = passwordHash;
  });
}

export function upsertAdminUser({ email, passwordHash, firstName, lastName, phone }) {
  return withStore((store) => {
    const normalized = email.trim().toLowerCase();
    let user = store.users.find((u) => u.email.toLowerCase() === normalized);
    if (!user) {
      store.counters.userId += 1;
      user = {
        id: store.counters.userId,
        email: email.trim(),
        password_hash: passwordHash,
        first_name: firstName,
        last_name: lastName,
        phone,
        role: 'admin',
        created_at: new Date().toISOString(),
      };
      store.users.push(user);
    } else {
      user.password_hash = passwordHash;
      user.role = 'admin';
      user.first_name = firstName;
      user.last_name = lastName;
    }
    return user;
  });
}

export const ISSUE_TYPES = [
  'No light',
  'Solid red light',
  'Red light flashes 6 times',
  'Red light flashes 7 times',
  'Red light flashes 8 times',
  'Red light flashes 9 times',
  'Isolator OFF',
  'Missing MCB',
  'Missing RCCB',
  'Wrong Component / Specs',
  'Other',
];
