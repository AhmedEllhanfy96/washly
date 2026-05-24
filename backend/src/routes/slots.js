import { pool } from '../db.js';

const DEFAULT = {
  windowDuration: 2,
  capacityPerWindow: 3,
  dayStart: '08:00',
  dayEnd: '18:00',
  isClosed: false,
};

export default async function (app) {
  const requireAdmin = async (req, reply) => {
    if (req.user.role !== 'admin') return reply.status(403).send({ error: 'Forbidden' });
  };
  const adminAuth = { preHandler: [app.authenticate, requireAdmin] };

  // ── Admin: get config for a date ─────────────────────────────────────────
  app.get('/config/:date', adminAuth, async (req) => {
    const cfg = await getConfigForDate(req.params.date);
    return { date: req.params.date, ...cfg };
  });

  // ── Admin: set config for a date ─────────────────────────────────────────
  app.put('/config/:date', adminAuth, async (req, reply) => {
    const { windowDuration, capacityPerWindow, dayStart, dayEnd, isClosed } = req.body;
    await pool.query(
      `INSERT INTO schedule_config (config_date, window_duration, capacity_per_window, day_start, day_end, is_closed)
       VALUES ($1,$2,$3,$4,$5,$6)
       ON CONFLICT (config_date) DO UPDATE SET
         window_duration      = EXCLUDED.window_duration,
         capacity_per_window  = EXCLUDED.capacity_per_window,
         day_start            = EXCLUDED.day_start,
         day_end              = EXCLUDED.day_end,
         is_closed            = EXCLUDED.is_closed,
         updated_at           = NOW()`,
      [
        req.params.date,
        windowDuration ?? DEFAULT.windowDuration,
        capacityPerWindow ?? DEFAULT.capacityPerWindow,
        dayStart ?? DEFAULT.dayStart,
        dayEnd ?? DEFAULT.dayEnd,
        isClosed ?? DEFAULT.isClosed,
      ]
    );
    return reply.status(200).send({ success: true });
  });

  // ── Admin: reset config for a date (back to defaults) ────────────────────
  app.delete('/config/:date', adminAuth, async (req, reply) => {
    await pool.query('DELETE FROM schedule_config WHERE config_date = $1', [req.params.date]);
    return reply.status(204).send();
  });

  // ── Public: get available slots for a date ────────────────────────────────
  app.get('/:date', async (req) => {
    const date = req.params.date;
    const cfg = await getConfigForDate(date);

    if (cfg.isClosed) return [];

    const slotDefs = generateSlots(cfg.dayStart, cfg.dayEnd, cfg.windowDuration, cfg.capacityPerWindow);

    const { rows } = await pool.query(
      `SELECT time_slot, COUNT(*)::int AS count
       FROM bookings
       WHERE scheduled_at::date = $1 AND status != 'cancelled'
       GROUP BY time_slot`,
      [date]
    );
    const booked = {};
    for (const r of rows) booked[r.time_slot] = r.count;

    return slotDefs.map((s) => ({
      startTime: s.startTime,
      endTime: s.endTime,
      available: (booked[s.startTime] ?? 0) < s.maxBookings,
      maxBookings: s.maxBookings,
      currentBookings: booked[s.startTime] ?? 0,
    }));
  });
}

async function getConfigForDate(date) {
  const { rows } = await pool.query(
    'SELECT * FROM schedule_config WHERE config_date = $1',
    [date]
  );
  if (!rows.length) return { ...DEFAULT };
  const r = rows[0];
  return {
    windowDuration: r.window_duration,
    capacityPerWindow: r.capacity_per_window,
    dayStart: r.day_start.slice(0, 5),
    dayEnd: r.day_end.slice(0, 5),
    isClosed: r.is_closed,
  };
}

function generateSlots(dayStart, dayEnd, windowDurationHours, capacityPerWindow) {
  const [sh, sm] = dayStart.split(':').map(Number);
  const [eh, em] = dayEnd.split(':').map(Number);
  const startMin = sh * 60 + sm;
  const endMin = eh * 60 + em;
  const slots = [];
  for (let t = startMin; t + windowDurationHours * 60 <= endMin; t += windowDurationHours * 60) {
    const pad = (n) => String(n).padStart(2, '0');
    slots.push({
      startTime: `${pad(Math.floor(t / 60))}:${pad(t % 60)}`,
      endTime: `${pad(Math.floor((t + windowDurationHours * 60) / 60))}:${pad((t + windowDurationHours * 60) % 60)}`,
      maxBookings: capacityPerWindow,
    });
  }
  return slots;
}
