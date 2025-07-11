import { pool } from '../db/index.js';

export async function upsertPetState(petID, speciesID) {
    await pool.query(
        `INSERT IGNORE INTO pet_states(pet_id, species_id, hunger, happiness)
         VALUES(?, ?, 0, 100)`,
        [petID, speciesID]
    );
}

export async function updatePetState(petID, hunger, happiness) {
    await pool.query(
        `UPDATE pet_states
         SET hunger = ?,
             happiness = ?,
             last_updated = NOW()
         WHERE pet_id = ?`,
        [hunger, happiness, petID]
    );
}

export async function decayStates() {
    // MySQL does not support RETURNING, so this is a two-step process.
    // First, update the states.
    await pool.query(
        `UPDATE pet_states
         SET hunger       = LEAST(100, hunger + 1),
             happiness    = GREATEST(0, happiness - 1),
             last_updated = NOW()
         WHERE TIMESTAMPDIFF(SECOND, last_updated, NOW()) >= 15`
    );
    // Then, select the updated rows. This is an approximation.
    // For a more exact return, you'd need a more complex transaction.
    const [rows] = await pool.query(
        `SELECT pet_id, hunger, happiness FROM pet_states
         WHERE TIMESTAMPDIFF(SECOND, last_updated, NOW()) < 5` // Select recently updated
    );
    return rows;
}