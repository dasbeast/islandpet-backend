import { pool } from '../db/index.js';

export async function upsertSession(activityID, petID, speciesID, token) {
    const sql = `
        INSERT INTO pet_sessions(activity_id, pet_id, species_id, token, created_at)
          VALUES(?, ?, ?, ?, NOW())
        ON DUPLICATE KEY UPDATE
          activity_id = VALUES(activity_id),
          species_id  = VALUES(species_id),
          token       = VALUES(token),
          created_at  = NOW()`;
    await pool.query(sql, [activityID, petID, speciesID, token]);

    // Fetch and return the session data since RETURNING is not available
    const [rows] = await pool.query('SELECT * FROM pet_sessions WHERE pet_id = ?', [petID]);
    return rows[0];
}

// Other functions with updated parameter markers
export async function updateSessionToken(activityID, token) {
    const [result] = await pool.query(
        `UPDATE pet_sessions SET token = ? WHERE activity_id = ?`,
        [token, activityID]
    );
    return result.affectedRows;
}

export async function deleteSession(activityID) {
    await pool.query(
        `DELETE FROM pet_sessions WHERE activity_id = ?`,
        [activityID]
    );
}

export async function getActiveSessions() {
    const [rows] = await pool.query(`
        SELECT ps.activity_id, ps.pet_id, ps.token, s.hunger, s.happiness
        FROM pet_sessions ps
                 JOIN pet_states s ON s.pet_id = ps.pet_id
    `);
    return rows;
}