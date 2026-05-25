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
    for (const [key, value] of Object.entries(updates)) {
      await pool.query(
        `INSERT INTO app_settings (key, value, updated_at)
         VALUES ($1, to_jsonb($2::text), NOW())
         ON CONFLICT (key) DO UPDATE SET value = to_jsonb($2::text), updated_at = NOW()`,
        [key, String(value)],
      );
    }
    const { rows: updated } = await pool.query('SELECT key, value FROM app_settings ORDER BY key');
    return Object.fromEntries(updated.map((r) => [r.key, r.value]));
  });
}
