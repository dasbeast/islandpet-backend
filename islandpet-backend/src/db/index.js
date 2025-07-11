import mysql from 'mysql2/promise';
import config from '../config/index.js';

console.log('[db] initializing database connection with URL:', config.databaseUrl);

// Create a connection pool. No special flags are needed.
export const pool = mysql.createPool(config.databaseUrl);

// Define the two table creation queries separately
const createPetStatesTable = `
    CREATE TABLE IF NOT EXISTS pet_states (
      pet_id       VARCHAR(255) PRIMARY KEY,
      species_id   VARCHAR(255) NOT NULL,
      hunger       INT NOT NULL DEFAULT 0,
      happiness    INT NOT NULL DEFAULT 100,
      last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
    );`;

const createPetSessionsTable = `
    CREATE TABLE IF NOT EXISTS pet_sessions (
      activity_id VARCHAR(255) PRIMARY KEY,
      pet_id      VARCHAR(255) NOT NULL,
      species_id  VARCHAR(255) NOT NULL,
      token       TEXT,
      created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      UNIQUE(pet_id),
      FOREIGN KEY (pet_id) REFERENCES pet_states(pet_id) ON DELETE CASCADE
    );`;

// Function to verify connection and ensure tables exist
async function setupDatabase() {
    let connection;
    try {
        connection = await pool.getConnection();
        console.log('[db] successfully connected to database');

        // Execute each query separately
        await connection.query(createPetStatesTable);
        console.log('[db] pet_states table ensured.');

        await connection.query(createPetSessionsTable);
        console.log('[db] pet_sessions table ensured.');

    } catch (err) {
        console.error('[db] database setup error:', err.message);
    } finally {
        if (connection) {
            connection.release();
            console.log('[db] connection released.');
        }
    }
}

// Run the setup
setupDatabase();