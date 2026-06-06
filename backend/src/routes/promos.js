import { pool } from '../db.js';

export default async function promosRoutes(app) {
  const auth = { preHandler: [app.authenticate] };

  async function assertAdmin(req, reply) {
    const { rows } = await pool.query('SELECT role FROM users WHERE id = $1', [req.user.uid]);
    if (!rows[0] || rows[0].role !== 'admin') {
      reply.status(403).send({ error: 'Admin only' });
      return false;
    }
    return true;
  }

  // POST /promos/validate — customer: check if promo code is valid, returns discount info
  app.post('/validate', auth, async (req, reply) => {
    const { code } = req.body;
    if (!code) return reply.status(400).send({ error: 'code is required' });

    const { rows } = await pool.query(
      `SELECT * FROM promos
       WHERE UPPER(code) = UPPER($1)
         AND is_active = true
         AND valid_from <= NOW()
         AND valid_until >= NOW()
         AND (max_uses IS NULL OR used_count < max_uses)`,
      [code],
    );
    if (!rows.length) return reply.status(404).send({ error: 'Invalid or expired promo code' });
    const promo = rows[0];
    return { code: promo.code, discountPercent: promo.discount_percent };
  });

  // GET /promos — admin: list all promos
  app.get('/', auth, async (req, reply) => {
    if (!await assertAdmin(req, reply)) return;
    const { rows } = await pool.query('SELECT * FROM promos ORDER BY created_at DESC');
    return rows.map(toPromo);
  });

  // POST /promos — admin: create promo
  app.post('/', auth, async (req, reply) => {
    if (!await assertAdmin(req, reply)) return;
    const { code, discountPercent, validFrom, validUntil, maxUses = null } = req.body;
    if (!code || !discountPercent || !validUntil) {
      return reply.status(400).send({ error: 'code, discountPercent, and validUntil are required' });
    }
    const { rows } = await pool.query(
      `INSERT INTO promos (code, discount_percent, valid_from, valid_until, max_uses)
       VALUES (UPPER($1), $2, $3, $4, $5) RETURNING *`,
      [code, discountPercent, validFrom || new Date().toISOString(), validUntil, maxUses],
    );
    return reply.status(201).send(toPromo(rows[0]));
  });

  // PATCH /promos/:id — admin: update promo (isActive, validUntil, maxUses)
  app.patch('/:id', auth, async (req, reply) => {
    if (!await assertAdmin(req, reply)) return;
    const { isActive, validUntil, maxUses } = req.body;
    const sets = [];
    const vals = [];
    if (isActive !== undefined) { vals.push(isActive); sets.push(`is_active = $${vals.length}`); }
    if (validUntil !== undefined) { vals.push(validUntil); sets.push(`valid_until = $${vals.length}`); }
    if (maxUses !== undefined) { vals.push(maxUses); sets.push(`max_uses = $${vals.length}`); }
    if (!sets.length) return reply.status(400).send({ error: 'Nothing to update' });
    vals.push(req.params.id);
    const { rows } = await pool.query(
      `UPDATE promos SET ${sets.join(', ')} WHERE id = $${vals.length} RETURNING *`, vals,
    );
    if (!rows.length) return reply.status(404).send({ error: 'Not found' });
    return toPromo(rows[0]);
  });

  // DELETE /promos/:id — admin: delete promo
  app.delete('/:id', auth, async (req, reply) => {
    if (!await assertAdmin(req, reply)) return;
    await pool.query('DELETE FROM promos WHERE id = $1', [req.params.id]);
    return reply.status(204).send();
  });
}

function toPromo(r) {
  return {
    id: r.id,
    code: r.code,
    discountPercent: r.discount_percent,
    validFrom: r.valid_from,
    validUntil: r.valid_until,
    isActive: r.is_active,
    maxUses: r.max_uses,
    usedCount: r.used_count,
    createdAt: r.created_at,
  };
}
