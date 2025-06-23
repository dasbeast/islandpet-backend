import { pool } from '../db/index.js';

export async function upsertSession(activityID, petID, speciesID, token) {
    const { rows } = await pool.query(`
    INSERT INTO pet_sessions(activity_id, pet_id, species_id, token)
      VALUES($1,$2,$3,$4)
    ON CONFLICT(pet_id) DO UPDATE
      SET activity_id = EXCLUDED.activity_id,
          species_id  = EXCLUDED.species_id,
          token       = EXCLUDED.token,
          created_at  = NOW()
    RETURNING *`,
        [activityID, petID, speciesID, token]
    );
    return rows[0];
}

export async function updateSessionToken(activityID, token) {
    const { rowCount } = await pool.query(`
    UPDATE pet_sessions
       SET token = $1
     WHERE activity_id = $2`,
        [token, activityID]
    );
    return rowCount;
}

export async function deleteSession(activityID) {
    await pool.query(
        `DELETE FROM pet_sessions WHERE activity_id = $1`,
        [activityID]
    );
}

export async function getActiveSessions() {
    const { rows } = await pool.query(`
    SELECT ps.activity_id, ps.pet_id, ps.token, s.hunger, s.happiness
      FROM pet_sessions ps
      JOIN pet_states s ON s.pet_id = ps.pet_id
  `);
    return rows;
}