import { pool } from '../db.js';
import { broadcast } from '../ws.js';

// In-memory worker location store: workerId → { lat, lng, name, workerId, updatedAt }
const workerLocations = new Map();

export { workerLocations };

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

  // POST /team/workers/me/location — worker reports current GPS position
  app.post('/workers/me/location', auth, async (req, reply) => {
    const { uid, role } = req.user;
    if (role !== 'worker') return reply.status(403).send({ error: 'Workers only' });
    const { lat, lng } = req.body;
    if (lat == null || lng == null) return reply.status(400).send({ error: 'lat and lng required' });

    // Fetch worker name once and cache in the location entry
    let name = workerLocations.get(uid)?.name;
    if (!name) {
      const { rows } = await pool.query('SELECT name FROM users WHERE id = $1', [uid]);
      name = rows[0]?.name ?? 'Worker';
    }

    const entry = { workerId: uid, name, lat: parseFloat(lat), lng: parseFloat(lng), updatedAt: new Date().toISOString() };
    workerLocations.set(uid, entry);

    // Broadcast to admins watching the map
    broadcast({ type: 'worker_location', ...entry });
    return reply.status(204).send();
  });

  // GET /team/workers/locations — admin: get all known worker locations
  app.get('/workers/locations', auth, async (req, reply) => {
    if (req.user.role !== 'admin') return reply.status(403).send({ error: 'Admin only' });
    return Array.from(workerLocations.values());
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
