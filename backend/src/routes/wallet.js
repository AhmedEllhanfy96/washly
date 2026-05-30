import { pool } from '../db.js';

export default async function walletRoutes(app) {
  const auth = { preHandler: [app.authenticate] };

  // Idempotent migration — runs on every startup so VM deployments self-heal
  try {
    await pool.query(`
      CREATE TABLE IF NOT EXISTS company_wallet (
        id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        source      TEXT NOT NULL,
        booking_id  UUID REFERENCES bookings(id) ON DELETE SET NULL,
        worker_id   UUID REFERENCES users(id)    ON DELETE SET NULL,
        amount      INTEGER NOT NULL,
        note        TEXT NOT NULL DEFAULT '',
        reconciled_at TIMESTAMPTZ,
        created_at  TIMESTAMPTZ DEFAULT NOW()
      )
    `);
    await pool.query(`
      CREATE UNIQUE INDEX IF NOT EXISTS company_wallet_booking_source
        ON company_wallet (booking_id, source) WHERE booking_id IS NOT NULL
    `);
    await pool.query(`
      ALTER TABLE company_wallet ADD COLUMN IF NOT EXISTS reconciled_at TIMESTAMPTZ
    `);

    // Backfill: confirmed instapay bookings that were missed before company_wallet existed
    await pool.query(`
      INSERT INTO company_wallet (source, booking_id, worker_id, amount)
      SELECT
        'instapay',
        b.id,
        NULL,
        COALESCE(
          (SELECT (value #>> '{}')::int FROM app_settings WHERE key =
            CASE b.service_type
              WHEN 'exteriorOnly'  THEN 'price_exterior_only'
              WHEN 'exterior_only' THEN 'price_exterior_only'
              WHEN 'interiorOnly'  THEN 'price_interior_only'
              WHEN 'interior_only' THEN 'price_interior_only'
              WHEN 'fullService'   THEN 'price_full_service'
              WHEN 'full_service'  THEN 'price_full_service'
              ELSE 'price_exterior_only'
            END
          ), 0
        )
      FROM bookings b
      WHERE b.payment_method = 'instapay'
        AND b.payment_status = 'confirmed'
      ON CONFLICT (booking_id, source) WHERE booking_id IS NOT NULL DO NOTHING
    `);

    // Backfill: settled worker cash entries that were missed
    await pool.query(`
      INSERT INTO company_wallet (source, booking_id, worker_id, amount)
      SELECT 'cash_collected', ww.booking_id, ww.worker_id, ww.amount
      FROM worker_wallet ww
      WHERE ww.status = 'settled'
        AND ww.payment_method = 'cash'
        AND ww.booking_id IS NOT NULL
      ON CONFLICT (booking_id, source) WHERE booking_id IS NOT NULL DO NOTHING
    `);

    console.log('[wallet] company_wallet migration + backfill OK');
  } catch (err) {
    console.warn('[wallet] migration error:', err.message);
  }

  // GET /wallet/ — worker: own CASH entries only; admin: filtered by workerId
  app.get('/', auth, async (req) => {
    const { uid, role } = req.user;

    if (role === 'worker') {
      const { rows } = await pool.query(
        `SELECT ww.*, b.service_type, b.customer_name, b.scheduled_at, b.time_slot
         FROM worker_wallet ww
         LEFT JOIN bookings b ON ww.booking_id = b.id
         WHERE ww.worker_id = $1 AND ww.payment_method = 'cash'
         ORDER BY ww.created_at DESC`,
        [uid]
      );
      return rows.map(toEntry);
    }

    if (req.user.role !== 'admin') return [];
    const { workerId } = req.query;
    if (workerId) {
      const { rows } = await pool.query(
        `SELECT ww.*, u.name AS worker_name, u.phone AS worker_phone,
                b.service_type, b.customer_name, b.scheduled_at, b.time_slot
         FROM worker_wallet ww
         JOIN users u ON ww.worker_id = u.id
         LEFT JOIN bookings b ON ww.booking_id = b.id
         WHERE ww.worker_id = $1 AND ww.payment_method = 'cash'
         ORDER BY ww.created_at DESC`,
        [workerId]
      );
      return rows.map(toEntry);
    }

    const { rows } = await pool.query(
      `SELECT ww.*, u.name AS worker_name, u.phone AS worker_phone,
              b.service_type, b.customer_name, b.scheduled_at, b.time_slot
       FROM worker_wallet ww
       JOIN users u ON ww.worker_id = u.id
       LEFT JOIN bookings b ON ww.booking_id = b.id
       WHERE ww.payment_method = 'cash'
       ORDER BY ww.created_at DESC`
    );
    return rows.map(toEntry);
  });

  // GET /wallet/summary — admin: per-worker cash totals
  app.get('/summary', auth, async (req, reply) => {
    if (req.user.role !== 'admin') return reply.status(403).send({ error: 'Admin only' });
    const { rows } = await pool.query(`
      SELECT
        u.id          AS worker_id,
        u.name        AS worker_name,
        u.phone       AS worker_phone,
        COALESCE(SUM(CASE WHEN ww.status = 'pending' AND ww.payment_method = 'cash' THEN ww.amount ELSE 0 END), 0)::int AS total_pending,
        COALESCE(SUM(CASE WHEN ww.status = 'settled' AND ww.payment_method = 'cash' THEN ww.amount ELSE 0 END), 0)::int AS total_settled,
        COUNT(CASE WHEN ww.status = 'pending' AND ww.payment_method = 'cash' THEN 1 END)::int AS pending_count
      FROM users u
      LEFT JOIN worker_wallet ww ON u.id = ww.worker_id
      WHERE u.role = 'worker'
      GROUP BY u.id, u.name, u.phone
      ORDER BY total_pending DESC, u.name
    `);
    return rows.map(r => ({
      workerId:     r.worker_id,
      workerName:   r.worker_name,
      workerPhone:  r.worker_phone,
      totalPending: r.total_pending,
      totalSettled: r.total_settled,
      pendingCount: r.pending_count,
    }));
  });

  // GET /wallet/company — admin: company wallet totals + daily breakdown (last 30 days)
  app.get('/company', auth, async (req, reply) => {
    if (req.user.role !== 'admin') return reply.status(403).send({ error: 'Admin only' });
    try {
      const [totalsRes, dailyRes] = await Promise.all([
        pool.query(`
          SELECT
            COALESCE(SUM(CASE WHEN source = 'instapay'        THEN amount ELSE 0 END), 0)::int AS from_instapay,
            COALESCE(SUM(CASE WHEN source = 'cash_collected'  THEN amount ELSE 0 END), 0)::int AS from_cash,
            COALESCE(SUM(CASE WHEN source = 'credit_card'     THEN amount ELSE 0 END), 0)::int AS from_credit_card,
            COALESCE(SUM(amount), 0)::int AS grand_total,
            COUNT(*) AS entry_count,
            COALESCE(SUM(CASE WHEN DATE(created_at AT TIME ZONE 'Africa/Cairo') = (NOW() AT TIME ZONE 'Africa/Cairo')::date
                              THEN amount ELSE 0 END), 0)::int AS today_total,
            COALESCE(SUM(CASE WHEN source = 'instapay' AND DATE(created_at AT TIME ZONE 'Africa/Cairo') = (NOW() AT TIME ZONE 'Africa/Cairo')::date
                              THEN amount ELSE 0 END), 0)::int AS today_instapay,
            COALESCE(SUM(CASE WHEN source = 'cash_collected' AND DATE(created_at AT TIME ZONE 'Africa/Cairo') = (NOW() AT TIME ZONE 'Africa/Cairo')::date
                              THEN amount ELSE 0 END), 0)::int AS today_cash,
            COALESCE(SUM(CASE WHEN source = 'credit_card' AND DATE(created_at AT TIME ZONE 'Africa/Cairo') = (NOW() AT TIME ZONE 'Africa/Cairo')::date
                              THEN amount ELSE 0 END), 0)::int AS today_credit_card
          FROM company_wallet
        `),
        pool.query(`
          SELECT
            DATE(created_at AT TIME ZONE 'Africa/Cairo') AS date,
            SUM(CASE WHEN source = 'instapay'       THEN amount ELSE 0 END)::int AS from_instapay,
            SUM(CASE WHEN source = 'cash_collected' THEN amount ELSE 0 END)::int AS from_cash,
            SUM(CASE WHEN source = 'credit_card'    THEN amount ELSE 0 END)::int AS from_credit_card,
            SUM(amount)::int AS total,
            BOOL_AND(reconciled_at IS NOT NULL) AS reconciled
          FROM company_wallet
          GROUP BY DATE(created_at AT TIME ZONE 'Africa/Cairo')
          ORDER BY DATE(created_at AT TIME ZONE 'Africa/Cairo') DESC
          LIMIT 30
        `),
      ]);

      const t = totalsRes.rows[0];
      return {
        fromInstapay:       t.from_instapay,
        fromCash:           t.from_cash,
        fromCreditCard:     t.from_credit_card,
        grandTotal:         t.grand_total,
        entryCount:         parseInt(t.entry_count),
        todayTotal:         t.today_total,
        todayFromInstapay:  t.today_instapay,
        todayFromCash:      t.today_cash,
        todayFromCreditCard: t.today_credit_card,
        daily: dailyRes.rows.map(r => ({
          date:           r.date,
          fromInstapay:   r.from_instapay,
          fromCash:       r.from_cash,
          fromCreditCard: r.from_credit_card,
          total:          r.total,
          reconciled:     r.reconciled ?? false,
        })),
      };
    } catch (err) {
      console.warn('[wallet] company query failed (run migration):', err.message);
      return { fromInstapay: 0, fromCash: 0, fromCreditCard: 0, grandTotal: 0, entryCount: 0,
               todayTotal: 0, todayFromInstapay: 0, todayFromCash: 0, todayFromCreditCard: 0, daily: [] };
    }
  });

  // GET /wallet/company/day?date=yyyy-MM-dd — individual transactions for a day
  app.get('/company/day', auth, async (req, reply) => {
    if (req.user.role !== 'admin') return reply.status(403).send({ error: 'Admin only' });
    const { date } = req.query;
    if (!date) return reply.status(400).send({ error: 'date required (yyyy-MM-dd)' });
    const { rows } = await pool.query(`
      SELECT cw.id, cw.source, cw.booking_id, cw.worker_id, cw.amount, cw.created_at,
             b.customer_name, b.service_type, b.time_slot, b.scheduled_at,
             u.name AS worker_name
      FROM company_wallet cw
      LEFT JOIN bookings b ON cw.booking_id = b.id
      LEFT JOIN users u ON cw.worker_id = u.id
      WHERE DATE(cw.created_at AT TIME ZONE 'Africa/Cairo') = $1
      ORDER BY cw.created_at DESC
    `, [date]);
    return rows.map(r => ({
      id:           r.id,
      source:       r.source,
      bookingId:    r.booking_id,
      workerId:     r.worker_id,
      workerName:   r.worker_name ?? null,
      amount:       r.amount,
      customerName: r.customer_name ?? null,
      serviceType:  r.service_type ?? null,
      timeSlot:     r.time_slot ?? null,
      scheduledAt:  r.scheduled_at ?? null,
      createdAt:    r.created_at,
    }));
  });

  // POST /wallet/company/reconcile — mark a day's entries as reconciled
  app.post('/company/reconcile', auth, async (req, reply) => {
    if (req.user.role !== 'admin') return reply.status(403).send({ error: 'Admin only' });
    const { date } = req.body ?? {};
    const targetDate = date || new Date().toISOString().split('T')[0];
    await pool.query(
      `UPDATE company_wallet
       SET reconciled_at = NOW()
       WHERE DATE(created_at AT TIME ZONE 'Africa/Cairo') = $1 AND reconciled_at IS NULL`,
      [targetDate]
    );
    return { success: true, date: targetDate };
  });

  // POST /wallet/company/reset — clear all company wallet entries (admin only)
  app.post('/company/reset', auth, async (req, reply) => {
    if (req.user.role !== 'admin') return reply.status(403).send({ error: 'Admin only' });
    const { rows } = await pool.query(
      `DELETE FROM company_wallet RETURNING id`
    );
    return { success: true, deleted: rows.length };
  });

  // POST /wallet/settle/:id — settle single worker wallet entry → add to company wallet
  app.post('/settle/:id', auth, async (req, reply) => {
    if (req.user.role !== 'admin') return reply.status(403).send({ error: 'Admin only' });

    const { rows: entryRows } = await pool.query(
      `SELECT * FROM worker_wallet WHERE id = $1 AND status = 'pending'`,
      [req.params.id]
    );
    if (!entryRows.length) return reply.status(404).send({ error: 'Not found or already settled' });
    const entry = entryRows[0];

    await pool.query(
      `UPDATE worker_wallet
       SET status = 'settled', settled_at = NOW(), settled_by = $1
       WHERE id = $2`,
      [req.user.uid, req.params.id]
    );

    try {
      await pool.query(
        `INSERT INTO company_wallet (source, booking_id, worker_id, amount)
         VALUES ('cash_collected', $1, $2, $3)
         ON CONFLICT (booking_id, source) WHERE booking_id IS NOT NULL DO NOTHING`,
        [entry.booking_id, entry.worker_id, entry.amount]
      );
    } catch (err) {
      console.error('[wallet] company_wallet insert failed (run migration):', err.message);
    }

    return { success: true };
  });

  // POST /wallet/settle-all/:workerId — settle all pending cash entries for a worker
  app.post('/settle-all/:workerId', auth, async (req, reply) => {
    if (req.user.role !== 'admin') return reply.status(403).send({ error: 'Admin only' });

    const { rows: pendingEntries } = await pool.query(
      `SELECT * FROM worker_wallet WHERE worker_id = $1 AND status = 'pending' AND payment_method = 'cash'`,
      [req.params.workerId]
    );

    if (!pendingEntries.length) return { success: true, settled: 0 };

    await pool.query(
      `UPDATE worker_wallet
       SET status = 'settled', settled_at = NOW(), settled_by = $1
       WHERE worker_id = $2 AND status = 'pending'`,
      [req.user.uid, req.params.workerId]
    );

    for (const entry of pendingEntries) {
      try {
        await pool.query(
          `INSERT INTO company_wallet (source, booking_id, worker_id, amount)
           VALUES ('cash_collected', $1, $2, $3)
           ON CONFLICT (booking_id, source) WHERE booking_id IS NOT NULL DO NOTHING`,
          [entry.booking_id, entry.worker_id, entry.amount]
        );
      } catch (err) {
        console.error('[wallet] company_wallet insert failed (run migration):', err.message);
      }
    }

    return { success: true, settled: pendingEntries.length };
  });
}

function toEntry(r) {
  return {
    id:            r.id,
    workerId:      r.worker_id,
    workerName:    r.worker_name    ?? null,
    workerPhone:   r.worker_phone   ?? null,
    bookingId:     r.booking_id,
    amount:        r.amount,
    paymentMethod: r.payment_method,
    status:        r.status,
    note:          r.note ?? '',
    serviceType:   r.service_type   ?? null,
    customerName:  r.customer_name  ?? null,
    scheduledAt:   r.scheduled_at   ?? null,
    timeSlot:      r.time_slot      ?? null,
    settledAt:     r.settled_at     ?? null,
    createdAt:     r.created_at,
  };
}
