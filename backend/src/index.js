import Fastify from 'fastify';
import cors from '@fastify/cors';
import jwt from '@fastify/jwt';
import websocket from '@fastify/websocket';
import authRoutes from './routes/auth.js';
import bookingRoutes from './routes/bookings.js';
import teamRoutes from './routes/team.js';
import slotsRoutes from './routes/slots.js';
import profileRoutes from './routes/profile.js';
import settingsRoutes from './routes/settings.js';
import walletRoutes from './routes/wallet.js';
import servicesRoutes from './routes/services.js';
import promosRoutes from './routes/promos.js';
import slidesRoutes from './routes/slides.js';
import { registerWsRoutes } from './ws.js';
import { pool } from './db.js';

const app = Fastify({ logger: true });

await app.register(cors, { origin: '*' });
await app.register(jwt, { secret: process.env.JWT_SECRET || 'washly-dev-secret-change-in-prod' });
await app.register(websocket);

app.decorate('authenticate', async (request, reply) => {
  try {
    await request.jwtVerify();
  } catch {
    reply.status(401).send({ error: 'Unauthorized' });
  }
});

app.get('/health', async () => ({ status: 'ok' }));

// Sync services table prices from app_settings on startup (one-time backfill for existing deployments)
try {
  await pool.query(`
    UPDATE services s
    SET price = (a.value #>> '{}')::int
    FROM app_settings a
    WHERE (a.key = 'price_exterior_only' AND s.key = 'exterior_only')
       OR (a.key = 'price_interior_only' AND s.key = 'interior_only')
       OR (a.key = 'price_full_service'  AND s.key = 'full_service')
  `);
} catch (_) { /* services table may not exist yet on very first boot */ }

await app.register(authRoutes, { prefix: '/auth' });
await app.register(bookingRoutes, { prefix: '/bookings' });
await app.register(teamRoutes, { prefix: '/team' });
await app.register(slotsRoutes, { prefix: '/slots' });
await app.register(profileRoutes, { prefix: '/profile' });
await app.register(settingsRoutes, { prefix: '/settings' });
await app.register(walletRoutes, { prefix: '/wallet' });
await app.register(servicesRoutes, { prefix: '/services' });
await app.register(promosRoutes, { prefix: '/promos' });
await app.register(slidesRoutes, { prefix: '/slides' });

registerWsRoutes(app);

const port = parseInt(process.env.PORT || '3000');
await app.listen({ port, host: '0.0.0.0' });
console.log(`Washly backend on :${port}`);
