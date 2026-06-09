import jwt from 'jsonwebtoken';
import bcrypt from 'bcryptjs';
import {
  findUserByEmail,
  findUserById,
  createUser,
  createResetCode,
  consumeResetCode,
  updateUserPassword,
  upsertAdminUser,
} from './ticket_db.js';

const JWT_SECRET = process.env.JWT_SECRET || 'rexharge-dev-jwt-secret-change-in-production';
const JWT_EXPIRES = process.env.JWT_EXPIRES || '7d';

export const DEFAULT_ADMIN_EMAIL = 'admin@gmail.com';
export const DEFAULT_ADMIN_PASSWORD = 'Law.1234';

export function signToken(user) {
  return jwt.sign(
    {
      sub: user.id,
      email: user.email,
      role: user.role,
      firstName: user.first_name,
      lastName: user.last_name,
    },
    JWT_SECRET,
    { expiresIn: JWT_EXPIRES },
  );
}

export function verifyToken(token) {
  return jwt.verify(token, JWT_SECRET);
}

export async function registerUser({
  email,
  password,
  firstName,
  lastName,
  phone,
  role = 'user',
}) {
  if (!email || !password) {
    throw new Error('Email and password are required.');
  }
  if (findUserByEmail(email)) {
    throw new Error('This email is already registered.');
  }
  if (email.trim().toLowerCase() === DEFAULT_ADMIN_EMAIL.toLowerCase()) {
    throw new Error('This email is reserved for admin use.');
  }
  if (role !== 'user' && role !== 'admin') {
    throw new Error('Invalid role.');
  }
  // Only customer accounts can register via the app.
  if (role !== 'user') {
    throw new Error('Admin accounts cannot be created through sign up.');
  }

  const passwordHash = await bcrypt.hash(password, 10);
  const user = createUser({
    email,
    passwordHash,
    firstName: firstName ?? '',
    lastName: lastName ?? '',
    phone: phone ?? '',
    role: 'user',
  });

  return { user, token: signToken(user) };
}

export async function loginUser(email, password) {
  const user = findUserByEmail(email);
  if (!user) {
    throw new Error('Incorrect email or password.');
  }
  const ok = await bcrypt.compare(password, user.password_hash);
  if (!ok) {
    throw new Error('Incorrect email or password.');
  }
  return { user, token: signToken(user) };
}

export async function requestPasswordReset(email) {
  const user = findUserByEmail(email);
  if (!user) {
    throw new Error('No account found for this email.');
  }
  const code = String(Math.floor(100000 + Math.random() * 900000));
  const { expiresAt } = createResetCode(email, code);
  console.log(`[Auth] Password reset code for ${email}: ${code} (expires ${expiresAt})`);
  return { code, expiresAt, devMode: true };
}

export async function resetPasswordWithCode(email, code, newPassword) {
  if (!email || !code || !newPassword) {
    throw new Error('Email, verification code, and new password are required.');
  }
  if (newPassword.length < 8 || newPassword.length > 16) {
    throw new Error('Password must be 8–16 characters.');
  }
  const user = findUserByEmail(email);
  if (!user) {
    throw new Error('No account found for this email.');
  }
  const valid = consumeResetCode(email, code);
  if (!valid) {
    throw new Error('Invalid or expired verification code.');
  }
  const passwordHash = await bcrypt.hash(newPassword, 10);
  updateUserPassword(email, passwordHash);
  return findUserByEmail(email);
}

export function userPublicProfile(user) {
  return {
    id: user.id,
    email: user.email,
    firstName: user.first_name,
    lastName: user.last_name,
    phone: user.phone,
    role: user.role,
    displayName: `${user.first_name} ${user.last_name}`.trim() || user.email,
  };
}

export function authMiddleware(req, res, next) {
  const header = req.headers.authorization || '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : null;
  if (!token) {
    return res.status(401).json({ error: 'Authentication required.' });
  }
  try {
    const payload = verifyToken(token);
    const user = findUserById(payload.sub);
    if (!user) {
      return res.status(401).json({ error: 'User not found.' });
    }
    req.user = user;
    req.auth = payload;
    next();
  } catch {
    return res.status(401).json({ error: 'Invalid or expired token.' });
  }
}

export function requireAdmin(req, res, next) {
  if (req.user?.role !== 'admin') {
    return res.status(403).json({ error: 'Admin access required.' });
  }
  next();
}

export function requireUser(req, res, next) {
  if (req.user?.role !== 'user' && req.user?.role !== 'admin') {
    return res.status(403).json({ error: 'Access denied.' });
  }
  next();
}

/** Fixed admin account for the web dashboard (created/reset on server start). */
export async function ensureDefaultAdmin() {
  const passwordHash = await bcrypt.hash(DEFAULT_ADMIN_PASSWORD, 10);
  upsertAdminUser({
    email: DEFAULT_ADMIN_EMAIL,
    passwordHash,
    firstName: 'Admin',
    lastName: 'EVision',
    phone: '',
  });
  console.log(`[Auth] Default admin ready: ${DEFAULT_ADMIN_EMAIL}`);
}
