export default async function (app) {
  app.get('/:date', async () => defaultSlots());
}

function defaultSlots() {
  return [
    { startTime: '08:00', endTime: '10:00', available: true, maxBookings: 3, currentBookings: 0 },
    { startTime: '10:00', endTime: '12:00', available: true, maxBookings: 3, currentBookings: 0 },
    { startTime: '12:00', endTime: '14:00', available: true, maxBookings: 3, currentBookings: 0 },
    { startTime: '14:00', endTime: '16:00', available: true, maxBookings: 3, currentBookings: 0 },
    { startTime: '16:00', endTime: '18:00', available: true, maxBookings: 3, currentBookings: 0 },
  ];
}
