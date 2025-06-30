import { performDecay } from '../services/petService.js';
import * as petSession  from '../models/petSession.js';

export async function decay(req, res, next) {
    try {
        console.log('[decay] triggered');
        await performDecay();
        res.sendStatus(200);
    } catch (err) {
        console.error('[decay] error:', err);
        next(err);
    }
}

export async function endSession(req, res, next) {
    try {
        console.log('[endSession] payload:', req.body);
        const { activityID } = req.body;
        await petSession.deleteSession(activityID);
        console.log('[endSession] deleted session:', activityID);
        res.sendStatus(200);
    } catch (err) {
        console.error('[endSession] error:', err);
        next(err);
    }
}

export async function clearAll(req, res, next) {
    try {
        console.log('[clearAll] truncating all tables');
        await pool.query('TRUNCATE pet_sessions, pet_states RESTART IDENTITY CASCADE');
        res.sendStatus(200);
    } catch (err) {
        console.error('[clearAll] error:', err);
        next(err);
    }
}

export async function deletePet(req, res, next) {
    try {
        console.log('[deletePet] petID:', req.params.petID);
        const { petID } = req.params;
        await pool.query('DELETE FROM pet_sessions WHERE pet_id = $1', [petID]);
        await pool.query('DELETE FROM pet_states   WHERE pet_id = $1', [petID]);
        console.log('[deletePet] deleted data for petID:', petID);
        res.sendStatus(200);
    } catch (err) {
        console.error('[deletePet] error:', err);
        next(err);
    }
}