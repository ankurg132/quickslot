const pg = require('pg');
const { Pool } = pg;
require('dotenv').config();

// Parse DATE column (OID 1082) as string to prevent timezone offset shifts
pg.types.setTypeParser(1082, (val) => val);

// Create PostgreSQL connection pool
const isProduction = process.env.NODE_ENV === 'production' || process.env.DATABASE_URL;

const pool = process.env.DATABASE_URL
  ? new Pool({
      connectionString: process.env.DATABASE_URL,
      ssl: {
        rejectUnauthorized: false, // Required for secure connections to Neon from Render
      },
      max: 20,
      idleTimeoutMillis: 30000,
      connectionTimeoutMillis: 10000, // Increased for serverless DB cold starts
    })
  : new Pool({
      host: process.env.DB_HOST || 'localhost',
      port: parseInt(process.env.DB_PORT || '5432', 10),
      database: process.env.DB_DATABASE || 'quickslot',
      user: process.env.DB_USER || 'ankurgupta',
      password: process.env.DB_PASSWORD || '',
      max: 20, // max connection pool size
      idleTimeoutMillis: 30000,
      connectionTimeoutMillis: 10000, // Increased for local connection margin
    });



const CREATE_TABLES_QUERY = `
  CREATE TABLE IF NOT EXISTS venues (
    id VARCHAR(50) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    sport VARCHAR(100) NOT NULL,
    location VARCHAR(255) NOT NULL,
    image_url TEXT
  );

  CREATE TABLE IF NOT EXISTS bookings (
    id SERIAL PRIMARY KEY,
    venue_id VARCHAR(50) NOT NULL REFERENCES venues(id) ON DELETE CASCADE,
    booking_date DATE NOT NULL,
    start_time TIME NOT NULL,
    user_id VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_venue_slot UNIQUE (venue_id, booking_date, start_time)
  );
`;

const SEED_VENUES = [
  {
    id: 'smash-arena',
    name: 'Smash Arena Badminton',
    sport: 'Badminton',
    location: 'Downtown Sports Center, Hall B',
    image_url: 'https://images.unsplash.com/photo-1626224583764-f87db24ac4ea?auto=format&fit=crop&q=80&w=600',
  },
  {
    id: 'camp-nou-turf',
    name: 'Camp Nou Turf',
    sport: 'Football',
    location: 'Westside Sports Park, Ground 1',
    image_url: 'https://images.unsplash.com/photo-1529900748604-07564a03e7a6?auto=format&fit=crop&q=80&w=600',
  },
  {
    id: 'pinnacle-tennis',
    name: 'Pinnacle Tennis Club',
    sport: 'Tennis',
    location: 'East Tennis Plaza, Court 3',
    image_url: 'https://images.unsplash.com/photo-1595435934249-5df7ed86e1c0?auto=format&fit=crop&q=80&w=600',
  },
  {
    id: 'vanguard-basketball',
    name: 'Vanguard Basketball Court',
    sport: 'Basketball',
    location: 'Vanguard Sports Complex, Indoor Court',
    image_url: 'https://images.unsplash.com/photo-1546519638-68e109498ffc?auto=format&fit=crop&q=80&w=600',
  },
];

async function initDb() {
  const client = await pool.connect();
  try {
    console.log('Initializing PostgreSQL database schema...');
    await client.query(CREATE_TABLES_QUERY);
    console.log('Tables verified/created successfully.');

    // Seed Venues
    console.log('Seeding venues...');
    for (const venue of SEED_VENUES) {
      await client.query(
        `INSERT INTO venues (id, name, sport, location, image_url)
         VALUES ($1, $2, $3, $4, $5)
         ON CONFLICT (id) DO UPDATE 
         SET name = EXCLUDED.name, sport = EXCLUDED.sport, location = EXCLUDED.location, image_url = EXCLUDED.image_url`,
        [venue.id, venue.name, venue.sport, venue.location, venue.image_url]
      );
    }
    console.log('Venues seeded successfully.');
  } catch (err) {
    console.error('Error during database initialization:', err);
    throw err;
  } finally {
    client.release();
  }
}

module.exports = {
  pool,
  initDb,
};
