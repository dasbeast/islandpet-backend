import mysql from 'mysql2/promise';
import config from '../config/index.js';

console.log('[db] initializing database connection, URL:', config.databaseUrl);

// Create a connection pool
export const pool = mysql.createPool(config.databaseUrl);

pool.getConnection()
    .then(conn => {
        console.log('[db] connected to database');
        conn.release();
    })
    .catch(err => {
        console.error('[db] database connection error:', err);
    });

// MySQL-compatible table creation queries
const createTablesQueries = `
    CREATE TABLE IF NOT EXISTS pet_states (
      pet_id       VARCHAR(255) PRIMARY KEY,
      species_id   VARCHAR(255) NOT NULL,
      hunger       INT NOT NULL DEFAULT 0,
      happiness    INT NOT NULL DEFAULT 100,
      last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
    );
    CREATE TABLE IF NOT EXISTS pet_sessions (
      activity_id VARCHAR(255) PRIMARY KEY,
      pet_id      VARCHAR(255) NOT NULL,
      species_id  VARCHAR(255) NOT NULL,
      token       TEXT,
      created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      UNIQUE(pet_id),
      FOREIGN KEY (pet_id) REFERENCES pet_states(pet_id) ON DELETE CASCADE
    );
`;

// Execute table creation
pool.query(createTablesQueries)
    .then(() => console.log('[db] tables ensured'))
    .catch(err => console.error('[db] table creation error:', err.message));