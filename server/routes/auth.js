import { Router } from 'express';
import {
  registerUser,
  loginUser,
  userPublicProfile,
  authMiddleware,
  requestPasswordReset,
  resetPasswordWithCode,
} from '../services/auth_service.js';

const router = Router();

router.post('/register', async (req, res) => {
  try {
    const { email, password, firstName, lastName, phone, role } = req.body ?? {};
    const { user, token } = await registerUser({
      email,
      password,
      firstName,
      lastName,
      phone,
      role: 'user',
    });
    res.status(201).json({ token, user: userPublicProfile(user) });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body ?? {};
    const { user, token } = await loginUser(email, password);
    res.json({ token, user: userPublicProfile(user) });
  } catch (error) {
    res.status(401).json({ error: error.message });
  }
});

router.get('/me', authMiddleware, (req, res) => {
  res.json({ user: userPublicProfile(req.user) });
});

router.post('/forgot-password', async (req, res) => {
  try {
    const { email } = req.body ?? {};
    const result = await requestPasswordReset(email);
    res.json({
      message: 'Verification code sent. Check your email.',
      devCode: process.env.NODE_ENV !== 'production' ? result.code : undefined,
    });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

router.post('/reset-password', async (req, res) => {
  try {
    const { email, code, newPassword } = req.body ?? {};
    await resetPasswordWithCode(email, code, newPassword);
    res.json({ message: 'Password updated successfully.' });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

export default router;
