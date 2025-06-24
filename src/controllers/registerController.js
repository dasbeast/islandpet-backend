import * as petState   from '../models/petState.js';
import * as petSession from '../models/petSession.js';
import {pool} from "../db/index.js";

export async function register(req, res, next) {
    try {
        console.log('[register] payload:', req.body);
        const { activityID, token, petID, speciesID } = req.body;
        await petState.upsertPetState(petID, speciesID);
        const session = await petSession.upsertSession(activityID, petID, speciesID, token);
        console.log('[register] upserted session:', session);
        res.json(session);
    } catch (err) {
        console.error('[register] error:', err);
        next(err);
    }
}

export async function refreshToken(req, res, next) {
    try {
        console.log('[refreshToken] payload:', req.body);
        const { activityID, token } = req.body;
        const updated = await petSession.updateSessionToken(activityID, token);
        console.log('[refreshToken] rows updated:', updated);
        if (!updated) return res.sendStatus(404);
        res.sendStatus(200);
    } catch (err) {
        console.error('[refreshToken] error:', err);
        next(err);
    }
}

// at the bottom of registerController.js
export async function renameSession(req, res, next) {
    try {
        console.log('[renameSession] payload:', req.body);
        const { oldActivityID, newActivityID } = req.body;
        const result = await pool.query(
            `UPDATE pet_sessions
         SET activity_id = $1
       WHERE activity_id = $2`,
            [newActivityID, oldActivityID]
        );
        if (!result.rowCount) return res.sendStatus(404);
        console.log('[renameSession] rows updated:', result.rowCount);
        res.sendStatus(200);
    } catch (err) {
        console.error('[renameSession] error:', err);
        next(err);
    }
}