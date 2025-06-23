import * as petState   from '../models/petState.js';
import * as petSession from '../models/petSession.js';
import {pool} from "../db/index.js";

export async function register(req, res, next) {
    try {
        const { activityID, token, petID, speciesID } = req.body;
        await petState.upsertPetState(petID, speciesID);
        const session = await petSession.upsertSession(activityID, petID, speciesID, token);
        res.json(session);
    } catch (err) {
        next(err);
    }
}

export async function refreshToken(req, res, next) {
    try {
        const { activityID, token } = req.body;
        const updated = await petSession.updateSessionToken(activityID, token);
        if (!updated) return res.sendStatus(404);
        res.sendStatus(200);
    } catch (err) {
        next(err);
    }
}

// at the bottom of registerController.js
export async function renameSession(req, res, next) {
    try {
        const { oldActivityID, newActivityID } = req.body;
        const result = await pool.query(
            `UPDATE pet_sessions
         SET activity_id = $1
       WHERE activity_id = $2`,
            [newActivityID, oldActivityID]
        );
        if (!result.rowCount) return res.sendStatus(404);
        res.sendStatus(200);
    } catch (err) {
        next(err);
    }
}