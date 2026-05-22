import { pool } from '../db.js';

const SLOT_CONFIG = [
  { startTime: '08:00', endTime: '10:00', maxBookings: 3 },
  { startTime: '10:00', endTime: '12:00', maxBookings: 3 },
  { startTime: '12:00', endTime: '14:00', maxBookings: 3 },
  { startTime: '14:00', endTime: '16:00', maxBookings: 3 },
  { startTime: '16:00', endTime: '18:00', maxBookings: 3 },
];

export default async function (app) {
  app.get('/:date', async (req) => {
    const date = req.params.date; // e.g. "2024-01-15"

    // Count real bookings per slot for this date (exclude cancelled)
    const { rows } = await pool.query(
      `SELECT time_slot, COUNT(*)::int AS count
       FROM bookings
       WHERE scheduled_at::date = $1
         AND status != 'cancelled'
       GROUP BY time_slot`,
      [date]
    );

    const booked = {};
    for (const row of rows) booked[row.time_slot] = row.count;

    return SLOT_CONFIG.map((s) => {
      const current = booked[s.startTime] ?? 0;
      return {
        startTime: s.startTime,
        endTime: s.endTime,
        available: current < s.maxBookings,
        maxBookings: s.maxBookings,
        currentBookings: current,
      };
    });
  });
}
