import { pool } from '../db/index.js';

export async function getPet(req, res, next) {
    try {
        const { petID } = req.params;
        const { rows } = await pool.query(
            `SELECT pet_id AS "petID",
                    species_id AS "speciesID",
                    hunger,
                    happiness,
                    last_updated
             FROM pet_states
             WHERE pet_id = $1`,
            [petID]
        );
        if (!rows.length) return res.sendStatus(404);
        res.json(rows[0]);
    } catch (err) {
        next(err);
    }
}