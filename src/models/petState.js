import { pool } from '../db/index.js';

export async function upsertPetState(petID, speciesID) {
    await pool.query(
        `INSERT INTO pet_states(pet_id, species_id, hunger, happiness)
         VALUES($1,$2,0,100)
             ON CONFLICT(pet_id) DO NOTHING`,
        [petID, speciesID]
    );
}

export async function updatePetState(petID, hunger, happiness) {
    await pool.query(
        `UPDATE pet_states
         SET hunger = $1,
             happiness = $2,
             last_updated = NOW()
         WHERE pet_id = $3`,
        [hunger, happiness, petID]
    );
}

export async function decayStates() {
    const { rows } = await pool.query(
        `UPDATE pet_states
         SET hunger       = LEAST(100, hunger + 1),
             happiness    = GREATEST(0, happiness - 1),
             last_updated = NOW()
         WHERE NOW() - last_updated >= INTERVAL '15 seconds'
             RETURNING pet_id, hunger, happiness`
    );
    return rows;  // array of { pet_id, hunger, happiness }
}