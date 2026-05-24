import bcrypt from 'bcryptjs';
import { pool } from '../db.js';

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
}
