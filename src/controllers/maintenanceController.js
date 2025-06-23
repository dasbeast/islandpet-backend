import { performDecay } from '../services/petService.js';
import * as petSession  from '../models/petSession.js';

export async function decay(req, res, next) {
    try {
        await performDecay();
        res.sendStatus(200);
    } catch (err) {
        next(err);
    }
}

export async function endSession(req, res, next) {
    try {
        const { activityID } = req.body;
        await petSession.deleteSession(activityID);
        res.sendStatus(200);
    } catch (err) {
        next(err);
    }
}

export async function clearAll(req, res, next) {
    try {
        await pool.query('TRUNCATE pet_sessions, pet_states RESTART IDENTITY CASCADE');
        res.sendStatus(200);
    } catch (err) {
        next(err);
    }
}

export async function deletePet(req, res, next) {
    try {
        const { petID } = req.params;
        await pool.query('DELETE FROM pet_sessions WHERE pet_id = $1', [petID]);
        await pool.query('DELETE FROM pet_states   WHERE pet_id = $1', [petID]);
        res.sendStatus(200);
    } catch (err) {
        next(err);
    }
}