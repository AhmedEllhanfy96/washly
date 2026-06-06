import { pool } from '../db.js';

export default async function servicesRoutes(app) {
  const adminAuth = {
    preHandler: [app.authenticate],
    schema: {},
  };

  async function assertAdmin(req, reply) {
    const { rows } = await pool.query('SELECT role FROM users WHERE id = $1', [req.user.uid]);
    if (!rows[0] || rows[0].role !== 'admin') {
      reply.status(403).send({ error: 'Admin only' });
      return false;
    }
    return true;
  }

  // GET /services — public, returns active services ordered by sort_order
  app.get('/', async (req) => {
    const activeOnly = req.query.all !== 'true';
    const { rows } = await pool.query(
      `SELECT * FROM services ${activeOnly ? "WHERE is_active = true" : ""} ORDER BY sort_order, created_at`,
    );
    return rows.map(toService);
  });

  // POST /services — admin: create service
  app.post('/', adminAuth, async (req, reply) => {
    if (!await assertAdmin(req, reply)) return;
    const { key, name, description = '', price, sortOrder = 0, category = 'wash',
            imageUrl = '', features = [], badge = '' } = req.body;
    if (!key || !name || price == null) {
      return reply.status(400).send({ error: 'key, name and price are required' });
    }
    const { rows } = await pool.query(
      `INSERT INTO services (key, name, description, price, sort_order, category, image_url, features, badge)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9) RETURNING *`,
      [key, name, description, price, sortOrder, category, imageUrl,
       JSON.stringify(features), badge],
    );
    return reply.status(201).send(toService(rows[0]));
  });

  // PATCH /services/:id — admin: update service (name, description, price, features, badge, isActive, sortOrder)
  app.patch('/:id', adminAuth, async (req, reply) => {
    if (!await assertAdmin(req, reply)) return;
    const { id } = req.params;
    const allowed = ['name', 'description', 'price', 'is_active', 'sort_order',
                     'image_url', 'features', 'badge'];
    const fieldMap = {
      name: 'name', description: 'description', price: 'price',
      isActive: 'is_active', sortOrder: 'sort_order',
      imageUrl: 'image_url', features: 'features', badge: 'badge',
    };
    const sets = [];
    const vals = [];
    for (const [camel, col] of Object.entries(fieldMap)) {
      if (req.body[camel] !== undefined) {
        vals.push(camel === 'features' ? JSON.stringify(req.body[camel]) : req.body[camel]);
        sets.push(`${col} = $${vals.length}`);
      }
    }
    if (!sets.length) return reply.status(400).send({ error: 'Nothing to update' });
    vals.push(id);
    const { rows } = await pool.query(
      `UPDATE services SET ${sets.join(', ')} WHERE id = $${vals.length} RETURNING *`,
      vals,
    );
    if (!rows.length) return reply.status(404).send({ error: 'Not found' });
    return toService(rows[0]);
  });

  // DELETE /services/:id — admin: hard delete (only if never used in a booking)
  app.delete('/:id', adminAuth, async (req, reply) => {
    if (!await assertAdmin(req, reply)) return;
    const { id } = req.params;
    const { rows: svc } = await pool.query('SELECT key FROM services WHERE id = $1', [id]);
    if (!svc.length) return reply.status(404).send({ error: 'Not found' });
    const { rows: used } = await pool.query(
      'SELECT id FROM bookings WHERE service_type = $1 LIMIT 1', [svc[0].key],
    );
    if (used.length) {
      // Already used in bookings — soft delete instead
      await pool.query('UPDATE services SET is_active = false WHERE id = $1', [id]);
      return { deactivated: true };
    }
    await pool.query('DELETE FROM services WHERE id = $1', [id]);
    return reply.status(204).send();
  });
}

function toService(r) {
  return {
    id: r.id,
    key: r.key,
    name: r.name,
    description: r.description,
    price: parseInt(r.price) || 0,
    isActive: r.is_active,
    sortOrder: r.sort_order,
    category: r.category,
    imageUrl: r.image_url,
    features: Array.isArray(r.features) ? r.features : (r.features || []),
    badge: r.badge,
    createdAt: r.created_at,
    updatedAt: r.updated_at,
  };
}
