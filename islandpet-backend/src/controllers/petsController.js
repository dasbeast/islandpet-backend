import { pool } from '../db/index.js';

export async function getPet(req, res, next) {
    try {
        console.log('[getPet] incoming petID:', req.params.petID);
        const { petID } = req.params;
        const [rows] = await pool.query(
            `SELECT pet_id AS "petID",
                    species_id AS "speciesID",
                    hunger,
                    happiness,
                    last_updated
             FROM pet_states
             WHERE pet_id = ?`,
            [petID]
        );
        console.log('[getPet] query result rows:', rows);
        if (!rows.length) return res.sendStatus(404);
        res.json(rows[0]);
    } catch (err) {
        console.error('[getPet] error:', err);
        next(err);
    }
}