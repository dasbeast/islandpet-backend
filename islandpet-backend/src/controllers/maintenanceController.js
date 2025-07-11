import { performDecay } from '../services/petService.js';
import * as petSession  from '../models/petSession.js';
import { pool } from '../db/index.js'; // Import the pool

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
        // This function now calls the updated model method, no changes needed here
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
        // MySQL does not support truncating multiple tables in one statement this way.
        // Also, RESTART IDENTITY is not a MySQL command.
        await pool.query('TRUNCATE TABLE pet_sessions;');
        await pool.query('TRUNCATE TABLE pet_states;');
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
        // The foreign key in the new schema now has ON DELETE CASCADE,
        // so deleting from pet_states will automatically delete from pet_sessions.
        await pool.query('DELETE FROM pet_states WHERE pet_id = ?', [petID]);
        console.log('[deletePet] deleted data for petID:', petID);
        res.sendStatus(200);
    } catch (err) {
        console.error('[deletePet] error:', err);
        next(err);
    }
}