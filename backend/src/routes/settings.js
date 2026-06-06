import { pool } from '../db.js';

export default async function settingsRoutes(app) {
  // Public: read all settings (customer/worker apps need prices without auth)
  app.get('/', async () => {
    const { rows } = await pool.query('SELECT key, value FROM app_settings ORDER BY key');
    return Object.fromEntries(rows.map((r) => [r.key, r.value]));
  });

  // Admin: update one or more settings
  app.put('/', { preHandler: [app.authenticate] }, async (req, reply) => {
    const { rows } = await pool.query('SELECT role FROM users WHERE id = $1', [req.user.uid]);
    if (!rows[0] || rows[0].role !== 'admin') {
      return reply.status(403).send({ error: 'Admin only' });
    }
    const updates = req.body;

    // Price keys map to service keys in the services table
    const priceKeyToServiceKey = {
      price_exterior_only: 'exterior_only',
      price_interior_only: 'interior_only',
      price_full_service:  'full_service',
    };

    for (const [key, value] of Object.entries(updates)) {
      await pool.query(
        `INSERT INTO app_settings (key, value, updated_at)
         VALUES ($1, to_jsonb($2::text), NOW())
         ON CONFLICT (key) DO UPDATE SET value = to_jsonb($2::text), updated_at = NOW()`,
        [key, String(value)],
      );
      // Keep services table in sync for the 3 core services
      if (priceKeyToServiceKey[key]) {
        await pool.query(
          `UPDATE services SET price = $1 WHERE key = $2`,
          [parseInt(value) || 0, priceKeyToServiceKey[key]],
        );
      }
    }
    const { rows: updated } = await pool.query('SELECT key, value FROM app_settings ORDER BY key');
    return Object.fromEntries(updated.map((r) => [r.key, r.value]));
  });
}
