import { pool } from '../db.js';
import { broadcast } from '../ws.js';

export default async function (app) {
  const auth = { preHandler: [app.authenticate] };

  // GET all bookings — admin: all, worker: assigned to them, customer: own
  app.get('/', auth, async (req) => {
    const { uid, role } = req.user;
    let rows;
    if (role === 'admin') {
      ({ rows } = await pool.query('SELECT * FROM bookings ORDER BY scheduled_at DESC'));
    } else if (role === 'worker') {
      ({ rows } = await pool.query(
        "SELECT * FROM bookings WHERE assigned_to = $1 ORDER BY scheduled_at ASC",
        [uid]
      ));
    } else {
      ({ rows } = await pool.query(
        'SELECT * FROM bookings WHERE user_id = $1 ORDER BY created_at DESC', [uid]
      ));
    }
    return rows.map(toBooking);
  });

  // POST create booking (customers + admin manual entry)
  app.post('/', auth, async (req, reply) => {
    const { uid } = req.user;
    const { car, serviceType, address, latitude = 0, longitude = 0, scheduledAt, timeSlot, customerName = '', customerPhone = '', notes = '', source = 'app' } = req.body;
    const { rows } = await pool.query(
      `INSERT INTO bookings (user_id, customer_name, customer_phone, car, service_type, address, latitude, longitude, scheduled_at, time_slot, notes, source)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12) RETURNING *`,
      [uid, customerName, customerPhone, JSON.stringify(car), serviceType, address, latitude, longitude, scheduledAt, timeSlot, notes, source]
    );
    const booking = toBooking(rows[0]);
    broadcast({ type: 'booking_created', booking });
    return reply.status(201).send(booking);
  });

  // GET single
  app.get('/:id', auth, async (req, reply) => {
    const { rows } = await pool.query('SELECT * FROM bookings WHERE id = $1', [req.params.id]);
    if (!rows.length) return reply.status(404).send({ error: 'Not found' });
    return toBooking(rows[0]);
  });

  // PATCH status
  app.patch('/:id/status', auth, async (req, reply) => {
    const { status } = req.body;
    const { rows } = await pool.query(
      'UPDATE bookings SET status = $1 WHERE id = $2 RETURNING *',
      [status, req.params.id]
    );
    if (!rows.length) return reply.status(404).send({ error: 'Not found' });
    const booking = toBooking(rows[0]);
    broadcast({ type: 'booking_updated', booking });
    return booking;
  });

  // PATCH assign team member (also sets status → confirmed)
  app.patch('/:id/assign', auth, async (req, reply) => {
    const { memberId } = req.body;
    const { rows } = await pool.query(
      `UPDATE bookings SET assigned_to = $1, status = 'confirmed' WHERE id = $2 RETURNING *`,
      [memberId, req.params.id]
    );
    if (!rows.length) return reply.status(404).send({ error: 'Not found' });
    const booking = toBooking(rows[0]);
    broadcast({ type: 'booking_updated', booking });
    return booking;
  });

  // DELETE
  app.delete('/:id', auth, async (req, reply) => {
    await pool.query('DELETE FROM bookings WHERE id = $1', [req.params.id]);
    return reply.status(204).send();
  });
}

function toBooking(r) {
  return {
    id: r.id,
    userId: r.user_id,
    customerName: r.customer_name,
    customerPhone: r.customer_phone,
    car: r.car,
    serviceType: r.service_type,
    address: r.address,
    latitude: parseFloat(r.latitude) || 0,
    longitude: parseFloat(r.longitude) || 0,
    scheduledAt: r.scheduled_at,
    timeSlot: r.time_slot,
    status: r.status,
    assignedTo: r.assigned_to,
    notes: r.notes,
    source: r.source ?? 'app',
    createdAt: r.created_at,
    updatedAt: r.updated_at,
  };
}
