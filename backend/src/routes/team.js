import { pool } from '../db.js';

export default async function (app) {
  const auth = { preHandler: [app.authenticate] };

  // GET workers (users with role='worker') — used by admin assign dropdown
  app.get('/workers', auth, async () => {
    const { rows } = await pool.query(
      "SELECT id, name, phone FROM users WHERE role = 'worker' ORDER BY name"
    );
    return rows;
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
