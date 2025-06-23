import { Pool } from 'pg';
import config from '../config/index.js';

export const pool = new Pool({
    connectionString: config.databaseUrl,
    ssl: { rejectUnauthorized: false }
});

// create tables on startup
pool.query(`
  CREATE TABLE IF NOT EXISTS pet_states (
    pet_id       TEXT PRIMARY KEY,
    species_id   TEXT NOT NULL,
    hunger       INTEGER NOT NULL DEFAULT 0,
    happiness    INTEGER NOT NULL DEFAULT 100,
    last_updated TIMESTAMPTZ NOT NULL DEFAULT NOW()
  );
  CREATE TABLE IF NOT EXISTS pet_sessions (
    activity_id TEXT PRIMARY KEY,
    pet_id      TEXT NOT NULL REFERENCES pet_states(pet_id),
    species_id  TEXT NOT NULL,
    token       TEXT,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(pet_id)
  );
`).catch(err => console.error('Error creating tables', err));