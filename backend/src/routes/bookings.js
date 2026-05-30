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

  // POST create booking
  app.post('/', auth, async (req, reply) => {
    const { uid } = req.user;
    const {
      car, serviceType, address, latitude = 0, longitude = 0,
      scheduledAt, timeSlot, customerName = '', customerPhone = '',
      notes = '', source = 'app', paymentMethod = 'cash',
    } = req.body;

    const { rows } = await pool.query(
      `INSERT INTO bookings
         (user_id, customer_name, customer_phone, car, service_type, address,
          latitude, longitude, scheduled_at, time_slot, notes, source, payment_method)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13) RETURNING *`,
      [uid, customerName, customerPhone, JSON.stringify(car), serviceType,
       address, latitude, longitude, scheduledAt, timeSlot, notes, source, paymentMethod]
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

    // Cash-only wallet entry when job completed
    if (status === 'completed' && rows[0].assigned_to) {
      await _createCashWalletEntry(rows[0]);
    }

    const booking = toBooking(rows[0]);
    broadcast({ type: 'booking_updated', booking });
    return booking;
  });

  // PATCH confirm instapay payment received by company
  app.patch('/:id/confirm-payment', auth, async (req, reply) => {
    if (req.user.role !== 'admin') return reply.status(403).send({ error: 'Admin only' });
    const { rows } = await pool.query(
      `UPDATE bookings SET payment_status = 'confirmed' WHERE id = $1 RETURNING *`,
      [req.params.id]
    );
    if (!rows.length) return reply.status(404).send({ error: 'Not found' });

    // Record in company wallet — fire-and-forget; don't fail the confirm if table missing
    try {
      const pmSource = rows[0].payment_method === 'credit_card' ? 'credit_card' : 'instapay';
      await _addToCompanyWallet({
        source: pmSource,
        bookingId: rows[0].id,
        serviceType: rows[0].service_type,
      });
    } catch (err) {
      console.error('[wallet] company_wallet insert failed (run migration):', err.message);
    }

    const booking = toBooking(rows[0]);
    broadcast({ type: 'booking_updated', booking });
    return booking;
  });

  // PATCH change payment method (admin only — switch instapay ↔ cash before assign)
  app.patch('/:id/payment-method', auth, async (req, reply) => {
    if (req.user.role !== 'admin') return reply.status(403).send({ error: 'Admin only' });
    const { paymentMethod } = req.body;
    if (!['cash', 'instapay', 'credit_card'].includes(paymentMethod)) {
      return reply.status(400).send({ error: 'Invalid payment method' });
    }
    const { rows } = await pool.query(
      `UPDATE bookings SET payment_method = $1, payment_status = 'pending' WHERE id = $2 RETURNING *`,
      [paymentMethod, req.params.id]
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

// Only cash jobs: worker collected from customer → must hand over to company
async function _createCashWalletEntry(row) {
  if (!row.assigned_to || row.payment_method !== 'cash') return;

  const { rows: existing } = await pool.query(
    'SELECT id FROM worker_wallet WHERE booking_id = $1', [row.id]
  );
  if (existing.length) return;

  const amount = await _lookupPrice(row.service_type);

  await pool.query(
    `INSERT INTO worker_wallet (worker_id, booking_id, amount, payment_method)
     VALUES ($1, $2, $3, 'cash')`,
    [row.assigned_to, row.id, amount]
  );
}

async function _addToCompanyWallet({ source, bookingId, serviceType, workerId = null, amount = null }) {
  const resolvedAmount = amount ?? await _lookupPrice(serviceType);
  await pool.query(
    `INSERT INTO company_wallet (source, booking_id, worker_id, amount)
     VALUES ($1, $2, $3, $4)
     ON CONFLICT (booking_id, source) WHERE booking_id IS NOT NULL DO NOTHING`,
    [source, bookingId, workerId, resolvedAmount]
  );
}

async function _lookupPrice(serviceType) {
  // Handle both camelCase (from Flutter) and snake_case (DB default)
  const keyMap = {
    exteriorOnly:  'price_exterior_only',
    exterior_only: 'price_exterior_only',
    interiorOnly:  'price_interior_only',
    interior_only: 'price_interior_only',
    fullService:   'price_full_service',
    full_service:  'price_full_service',
  };
  const key = keyMap[serviceType] || 'price_exterior_only';
  const { rows } = await pool.query(
    `SELECT value #>> '{}' AS val FROM app_settings WHERE key = $1`, [key]
  );
  return rows.length ? (parseInt(rows[0].val) || 0) : 0;
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
    paymentMethod: r.payment_method ?? 'cash',
    paymentStatus: r.payment_status ?? 'pending',
    createdAt: r.created_at,
    updatedAt: r.updated_at,
  };
}
