import nodemailer from 'nodemailer';

const SMTP_HOST = process.env.SMTP_HOST || '';
const SMTP_PORT = Number(process.env.SMTP_PORT || 587);
const SMTP_USER = process.env.SMTP_USER || '';
const SMTP_PASS = process.env.SMTP_PASS || '';
const SMTP_SECURE = process.env.SMTP_SECURE === 'true';
const MAIL_FROM = process.env.MAIL_FROM || SMTP_USER || 'evision-support@localhost';
const REPLY_DOMAIN = process.env.REPLY_DOMAIN || 'evision.local';
const APP_NAME = process.env.APP_NAME || 'EVision Support';

let _transporter = null;

function getTransporter() {
  if (_transporter) return _transporter;
  if (!SMTP_HOST || !SMTP_USER || !SMTP_PASS) {
    return null;
  }
  _transporter = nodemailer.createTransport({
    host: SMTP_HOST,
    port: SMTP_PORT,
    secure: SMTP_SECURE,
    auth: { user: SMTP_USER, pass: SMTP_PASS },
  });
  return _transporter;
}

export function isEmailConfigured() {
  return Boolean(SMTP_HOST && SMTP_USER && SMTP_PASS);
}

export function buildReplyToAddress(ticketInternalId) {
  return `ticket+${ticketInternalId}@${REPLY_DOMAIN}`;
}

export function buildTicketSubject(ticketNumber, isReply = false) {
  const prefix = isReply ? 'Re: ' : '';
  return `${prefix}${APP_NAME} — Ticket #${ticketNumber}`;
}

export function parseTicketReference({ subject, to } = {}) {
  const toText = Array.isArray(to) ? to.join(' ') : String(to || '');
  const routeMatch = toText.match(/ticket\+(\d+)@/i);
  if (routeMatch) {
    return { internalId: Number(routeMatch[1]) };
  }

  const subjectText = String(subject || '');
  const numberMatch = subjectText.match(/ticket\s*#?\s*(\d{3,})/i);
  if (numberMatch) {
    return { ticketNumber: Number(numberMatch[1]) };
  }

  return null;
}

function logDevEmail({ to, subject, replyTo, text }) {
  console.log('[Email] DEV MODE — SMTP not configured. Email not sent.');
  console.log(`  To: ${to}`);
  console.log(`  Subject: ${subject}`);
  console.log(`  Reply-To: ${replyTo}`);
  console.log(`  Body:\n${text}`);
}

async function sendMail({ to, subject, text, html, replyTo }) {
  const payload = {
    from: MAIL_FROM,
    to,
    subject,
    text,
    html: html || text.replace(/\n/g, '<br>'),
    replyTo,
  };

  const transporter = getTransporter();
  if (!transporter) {
    logDevEmail({ to, subject, replyTo, text });
    return { devMode: true, messageId: `dev-${Date.now()}` };
  }

  const info = await transporter.sendMail(payload);
  return { devMode: false, messageId: info.messageId };
}

export async function sendTicketReceivedEmail(ticket) {
  const replyTo = buildReplyToAddress(ticket.id);
  const subject = buildTicketSubject(ticket.ticketNumber, false);
  const text =
    `Hi ${ticket.fullName},\n\n` +
    `We received your support ticket ${ticket.ticketId} (${ticket.issueType}).\n` +
    `Our team will review it and reply by email.\n\n` +
    `You can reply directly to this email to continue the conversation.\n\n` +
    `— ${APP_NAME}`;

  return sendMail({
    to: ticket.userEmail,
    subject,
    text,
    replyTo,
  });
}

export async function sendAdminMessageEmail(ticket, messageBody, senderName) {
  const replyTo = buildReplyToAddress(ticket.id);
  const subject = buildTicketSubject(ticket.ticketNumber, true);
  const text =
    `Hi ${ticket.fullName},\n\n` +
    `${messageBody}\n\n` +
    `— ${senderName || 'EVision Technician'}\n` +
    `Ticket ${ticket.ticketId}\n\n` +
    `Reply to this email to respond.`;

  return sendMail({
    to: ticket.userEmail,
    subject,
    text,
    replyTo,
  });
}
