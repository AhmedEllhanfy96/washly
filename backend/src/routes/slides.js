import { pool } from '../db.js';

export default async function slidesRoutes(app) {
  const auth = { preHandler: [app.authenticate] };

  // Idempotent migration
  try {
    await pool.query(`
      CREATE TABLE IF NOT EXISTS slides (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        image_url TEXT NOT NULL,
        title TEXT NOT NULL DEFAULT '',
        caption TEXT NOT NULL DEFAULT '',
        sort_order INTEGER DEFAULT 0,
        is_active BOOLEAN DEFAULT true,
        created_at TIMESTAMPTZ DEFAULT NOW()
      )
    `);
  } catch (_) {}

  async function assertAdmin(req, reply) {
    const { rows } = await pool.query('SELECT role FROM users WHERE id = $1', [req.user.uid]);
    if (!rows[0] || rows[0].role !== 'admin') {
      reply.status(403).send({ error: 'Admin only' });
      return false;
    }
    return true;
  }

  // GET /slides — public, returns active slides ordered by sort_order
  app.get('/', async () => {
    const { rows } = await pool.query(
      'SELECT * FROM slides WHERE is_active = true ORDER BY sort_order, created_at',
    );
    return rows.map(toSlide);
  });

  // GET /slides/all — admin: all slides including inactive
  app.get('/all', auth, async (req, reply) => {
    if (!await assertAdmin(req, reply)) return;
    const { rows } = await pool.query('SELECT * FROM slides ORDER BY sort_order, created_at');
    return rows.map(toSlide);
  });

  // POST /slides — admin: create slide
  app.post('/', auth, async (req, reply) => {
    if (!await assertAdmin(req, reply)) return;
    const { imageUrl, title = '', caption = '', sortOrder = 0 } = req.body;
    if (!imageUrl) return reply.status(400).send({ error: 'imageUrl is required' });
    const { rows } = await pool.query(
      `INSERT INTO slides (image_url, title, caption, sort_order)
       VALUES ($1, $2, $3, $4) RETURNING *`,
      [imageUrl, title, caption, sortOrder],
    );
    return reply.status(201).send(toSlide(rows[0]));
  });

  // PATCH /slides/:id — admin: update slide
  app.patch('/:id', auth, async (req, reply) => {
    if (!await assertAdmin(req, reply)) return;
    const fieldMap = {
      imageUrl: 'image_url', title: 'title', caption: 'caption',
      sortOrder: 'sort_order', isActive: 'is_active',
    };
    const sets = [];
    const vals = [];
    for (const [camel, col] of Object.entries(fieldMap)) {
      if (req.body[camel] !== undefined) {
        vals.push(req.body[camel]);
        sets.push(`${col} = $${vals.length}`);
      }
    }
    if (!sets.length) return reply.status(400).send({ error: 'Nothing to update' });
    vals.push(req.params.id);
    const { rows } = await pool.query(
      `UPDATE slides SET ${sets.join(', ')} WHERE id = $${vals.length} RETURNING *`, vals,
    );
    if (!rows.length) return reply.status(404).send({ error: 'Not found' });
    return toSlide(rows[0]);
  });

  // DELETE /slides/:id — admin
  app.delete('/:id', auth, async (req, reply) => {
    if (!await assertAdmin(req, reply)) return;
    await pool.query('DELETE FROM slides WHERE id = $1', [req.params.id]);
    return reply.status(204).send();
  });
}

function toSlide(r) {
  return {
    id: r.id,
    imageUrl: r.image_url,
    title: r.title,
    caption: r.caption,
    sortOrder: r.sort_order,
    isActive: r.is_active,
    createdAt: r.created_at,
  };
}
