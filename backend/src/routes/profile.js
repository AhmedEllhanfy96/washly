import { pool } from '../db.js';

export default async function (app) {
  const auth = { preHandler: [app.authenticate] };

  // ── Saved Cars ─────────────────────────────────────────────────────────────

  app.get('/cars', auth, async (req) => {
    const { rows } = await pool.query(
      'SELECT * FROM saved_cars WHERE user_id = $1 ORDER BY created_at DESC',
      [req.user.uid]
    );
    return rows.map(toCar);
  });

  app.post('/cars', auth, async (req, reply) => {
    const { make, model, color, plateNumber, year } = req.body;
    if (!make || !model || !color || !plateNumber) {
      return reply.status(400).send({ error: 'make, model, color, plateNumber are required' });
    }
    const { rows } = await pool.query(
      'INSERT INTO saved_cars (user_id, make, model, color, plate_number, year) VALUES ($1,$2,$3,$4,$5,$6) RETURNING *',
      [req.user.uid, make.trim(), model.trim(), color.trim(), plateNumber.trim().toUpperCase(), year ?? null]
    );
    return reply.status(201).send(toCar(rows[0]));
  });

  app.delete('/cars/:id', auth, async (req, reply) => {
    await pool.query('DELETE FROM saved_cars WHERE id = $1 AND user_id = $2', [req.params.id, req.user.uid]);
    return reply.status(204).send();
  });

  // ── Saved Locations ────────────────────────────────────────────────────────

  app.get('/locations', auth, async (req) => {
    const { rows } = await pool.query(
      'SELECT * FROM saved_locations WHERE user_id = $1 ORDER BY created_at DESC',
      [req.user.uid]
    );
    return rows.map(toLocation);
  });

  app.post('/locations', auth, async (req, reply) => {
    const { label, address, latitude, longitude } = req.body;
    if (!label || !address) {
      return reply.status(400).send({ error: 'label and address are required' });
    }
    const { rows } = await pool.query(
      'INSERT INTO saved_locations (user_id, label, address, latitude, longitude) VALUES ($1,$2,$3,$4,$5) RETURNING *',
      [req.user.uid, label.trim(), address.trim(), latitude ?? 0, longitude ?? 0]
    );
    return reply.status(201).send(toLocation(rows[0]));
  });

  app.delete('/locations/:id', auth, async (req, reply) => {
    await pool.query('DELETE FROM saved_locations WHERE id = $1 AND user_id = $2', [req.params.id, req.user.uid]);
    return reply.status(204).send();
  });
}

function toCar(r) {
  return {
    id: r.id,
    make: r.make,
    model: r.model,
    color: r.color,
    plateNumber: r.plate_number,
    year: r.year,
  };
}

function toLocation(r) {
  return {
    id: r.id,
    label: r.label,
    address: r.address,
    latitude: parseFloat(r.latitude) || 0,
    longitude: parseFloat(r.longitude) || 0,
  };
}
