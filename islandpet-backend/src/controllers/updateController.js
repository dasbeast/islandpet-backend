import * as petState   from '../models/petState.js';
import * as petSession from '../models/petSession.js';
import { pushToAPNs }  from '../services/apnsService.js';

export async function update(req, res, next) {
    try {
        console.log('[update] payload:', req.body);
        const { petID, state } = req.body;
        await petState.updatePetState(petID, state.hunger, state.happiness);
        console.log('[update] state persisted for petID:', petID);

        const sessions = await petSession.getActiveSessions()
            .then(rows => rows.filter(r => r.pet_id === petID && r.token));
        console.log('[update] active sessions to push:', sessions);

        for (let sess of sessions) {
            console.log('[update] pushing to session:', sess.activity_id, 'token:', sess.token);
            await pushToAPNs(sess.token, state);
        }
        res.sendStatus(200);
    } catch (err) {
        console.error('[update] error:', err);
        next(err);
    }
}