import { pool } from '../db.js';

export default async function (app) {
  const auth = { preHandler: [app.authenticate] };

  // GET customers with booking count — admin customer list
  app.get('/customers', auth, async () => {
    const { rows } = await pool.query(`
      SELECT u.id, u.name, u.email, u.phone, u.created_at,
             COUNT(b.id)::int AS booking_count
        FROM users u
        LEFT JOIN bookings b ON b.user_id = u.id
       WHERE u.role = 'customer'
       GROUP BY u.id
       ORDER BY u.created_at DESC
    `);
    return rows.map(c => ({
      id: c.id,
      name: c.name,
      email: c.email,
      phone: c.phone ?? '',
      bookingCount: c.booking_count,
      createdAt: c.created_at,
    }));
  });

  // GET workers (users with role='worker') — used by admin assign dropdown
  app.get('/workers', auth, async () => {
    const { rows } = await pool.query(
      "SELECT id, name, phone, email FROM users WHERE role = 'worker' ORDER BY name"
    );
    return rows;
  });

  // POST create worker account
  app.post('/workers', auth, async (req, reply) => {
    const { name, phone = '', email, password } = req.body;
    if (!name || !email || !password) {
      return reply.status(400).send({ error: 'name, email and password are required' });
    }
    const bcrypt = await import('bcryptjs');
    const hash = await bcrypt.default.hash(password, 10);
    try {
      const { rows } = await pool.query(
        "INSERT INTO users (email, password_hash, name, phone, role) VALUES ($1,$2,$3,$4,'worker') RETURNING id, email, name, phone, role",
        [email.toLowerCase().trim(), hash, name.trim(), phone.trim()]
      );
      return reply.status(201).send(rows[0]);
    } catch (e) {
      if (e.code === '23505') return reply.status(409).send({ error: 'Email already registered' });
      throw e;
    }
  });

  // DELETE worker account
  app.delete('/workers/:id', auth, async (req, reply) => {
    await pool.query("DELETE FROM users WHERE id = $1 AND role = 'worker'", [req.params.id]);
    return reply.status(204).send();
  });

  app.get('/', auth, async () => {
    const { rows } = await pool.query('SELECT * FROM team_members ORDER BY name');
    return rows.map(toMember);
  });

  app.post('/', auth, async (req, reply) => {
    const { name, phone = '' } = req.body;
    if (!name) return reply.status(400).send({ error: 'name is required' });
    const { rows } = await pool.query(
      'INSERT INTO team_members (name, phone) VALUES ($1,$2) RETURNING *',
      [name.trim(), phone.trim()]
    );
    return reply.status(201).send(toMember(rows[0]));
  });

  app.patch('/:id', auth, async (req, reply) => {
    const { name, phone, isAvailable } = req.body;
    const { rows } = await pool.query(
      `UPDATE team_members SET
        name = COALESCE($1, name),
        phone = COALESCE($2, phone),
        is_available = COALESCE($3, is_available)
       WHERE id = $4 RETURNING *`,
      [name ?? null, phone ?? null, isAvailable ?? null, req.params.id]
    );
    if (!rows.length) return reply.status(404).send({ error: 'Not found' });
    return toMember(rows[0]);
  });

  app.delete('/:id', auth, async (req, reply) => {
    await pool.query('DELETE FROM team_members WHERE id = $1', [req.params.id]);
    return reply.status(204).send();
  });
}

function toMember(r) {
  return { id: r.id, name: r.name, phone: r.phone, isAvailable: r.is_available, createdAt: r.created_at };
}
