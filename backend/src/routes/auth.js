import crypto from 'crypto';
import bcrypt from 'bcryptjs';
import { pool } from '../db.js';
import { sendPasswordResetEmail } from '../email.js';

export default async function (app) {
  app.post('/register', async (req, reply) => {
    const { email, password, name, phone = '' } = req.body;
    if (!email || !password || !name) {
      return reply.status(400).send({ error: 'email, password, name are required' });
    }
    const hash = await bcrypt.hash(password, 10);
    try {
      const { rows } = await pool.query(
        'INSERT INTO users (email, password_hash, name, phone) VALUES ($1,$2,$3,$4) RETURNING id, email, name, phone, role',
        [email.toLowerCase().trim(), hash, name.trim(), phone.trim()]
      );
      const user = rows[0];
      const token = app.jwt.sign({ uid: user.id, email: user.email, role: user.role });
      return { token, user };
    } catch (e) {
      if (e.code === '23505') return reply.status(409).send({ error: 'Email already registered' });
      throw e;
    }
  });

  app.post('/login', async (req, reply) => {
    const { email, password } = req.body;
    const { rows } = await pool.query('SELECT * FROM users WHERE email = $1', [email?.toLowerCase().trim()]);
    if (!rows.length) return reply.status(401).send({ error: 'Invalid email or password' });
    const user = rows[0];
    const valid = await bcrypt.compare(password, user.password_hash);
    if (!valid) return reply.status(401).send({ error: 'Invalid email or password' });
    const token = app.jwt.sign({ uid: user.id, email: user.email, role: user.role });
    return {
      token,
      user: { id: user.id, email: user.email, name: user.name, phone: user.phone, role: user.role },
    };
  });

  app.get('/me', { preHandler: [app.authenticate] }, async (req) => {
    const { rows } = await pool.query(
      'SELECT id, email, name, phone, role FROM users WHERE id = $1',
      [req.user.uid]
    );
    return rows[0] ?? null;
  });

  app.patch('/profile', { preHandler: [app.authenticate] }, async (req, reply) => {
    const { name, phone, currentPassword, newPassword } = req.body;
    const updates = [];
    const values = [];
    let idx = 1;

    if (name !== undefined && name.trim()) {
      updates.push(`name = $${idx++}`);
      values.push(name.trim());
    }
    if (phone !== undefined) {
      updates.push(`phone = $${idx++}`);
      values.push(phone.trim());
    }
    if (newPassword) {
      if (!currentPassword) {
        return reply.status(400).send({ error: 'currentPassword required to change password' });
      }
      const { rows: ur } = await pool.query('SELECT password_hash FROM users WHERE id = $1', [req.user.uid]);
      const valid = await bcrypt.compare(currentPassword, ur[0].password_hash);
      if (!valid) return reply.status(400).send({ error: 'Current password is incorrect' });
      updates.push(`password_hash = $${idx++}`);
      values.push(await bcrypt.hash(newPassword, 10));
    }
    if (!updates.length) return reply.status(400).send({ error: 'Nothing to update' });

    values.push(req.user.uid);
    const { rows } = await pool.query(
      `UPDATE users SET ${updates.join(', ')} WHERE id = $${idx} RETURNING id, email, name, phone, role`,
      values
    );
    return rows[0];
  });

  app.post('/forgot-password', async (req, reply) => {
    const { email } = req.body ?? {};
    if (!email) return reply.status(400).send({ error: 'email is required' });

    const { rows } = await pool.query(
      'SELECT id FROM users WHERE email = $1 AND role = $2',
      [email.toLowerCase().trim(), 'customer']
    );

    if (rows.length > 0) {
      const token = crypto.randomBytes(32).toString('hex');
      const expiresAt = new Date(Date.now() + 60 * 60 * 1000); // 1 hour

      await pool.query('DELETE FROM password_reset_tokens WHERE user_id = $1', [rows[0].id]);
      await pool.query(
        'INSERT INTO password_reset_tokens (user_id, token, expires_at) VALUES ($1, $2, $3)',
        [rows[0].id, token, expiresAt]
      );

      const appUrl = (process.env.CUSTOMER_APP_URL || 'http://localhost').replace(/\/$/, '');
      const resetUrl = `${appUrl}/reset-password?token=${token}`;

      try {
        await sendPasswordResetEmail(email.toLowerCase().trim(), resetUrl);
      } catch (e) {
        console.error('Failed to send reset email:', e.message);
      }
    }

    // Always return the same message so we don't reveal whether email exists
    return reply.send({ message: 'If that email is registered, a reset link was sent.' });
  });

  app.post('/reset-password', async (req, reply) => {
    const { token, newPassword } = req.body ?? {};
    if (!token || !newPassword) {
      return reply.status(400).send({ error: 'token and newPassword are required' });
    }
    if (newPassword.length < 6) {
      return reply.status(400).send({ error: 'Password must be at least 6 characters' });
    }

    const { rows } = await pool.query(
      'SELECT * FROM password_reset_tokens WHERE token = $1 AND used = FALSE AND expires_at > NOW()',
      [token]
    );

    if (rows.length === 0) {
      return reply.status(400).send({ error: 'Reset link is invalid or has expired.' });
    }

    const hash = await bcrypt.hash(newPassword, 10);
    await pool.query('UPDATE users SET password_hash = $1 WHERE id = $2', [hash, rows[0].user_id]);
    await pool.query('UPDATE password_reset_tokens SET used = TRUE WHERE id = $1', [rows[0].id]);

    return reply.send({ message: 'Password reset successfully.' });
  });
}
