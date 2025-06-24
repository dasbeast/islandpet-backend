import * as petState   from '../models/petState.js';
import * as petSession from '../models/petSession.js';
import { pushToAPNs }  from './apnsService.js';

export async function performDecay() {
    console.log('[petService] performDecay: starting');
    // 1) decay hunger/happiness in pet_states
    const decayed = await petState.decayStates();
    console.log('[petService] performDecay: decayed states count =', decayed.length, decayed);

    // 2) fetch all live sessions + their state
    const sessions = await petSession.getActiveSessions();
    console.log('[petService] performDecay: fetched sessions count =', sessions.length, sessions);

    // 3) push each session, delete if token invalid
    for (let sess of sessions) {
        console.log('[petService] processing session:', sess.activity_id, 'token:', sess.token);
        if (!sess.token) continue;
        try {
            console.log('[petService] pushing to APNs for session:', sess.activity_id, 'state:', { hunger: sess.hunger, happiness: sess.happiness });
            await pushToAPNs(sess.token, {
                hunger:    sess.hunger,
                happiness: sess.happiness
            });
        } catch (err) {
            console.error('[petService] push error for session:', sess.activity_id, err);
            const msg = err.message || '';
            if (
                msg.includes('BadDeviceToken') ||
                msg.includes('ExpiredToken')   ||
                msg.includes('Unregistered')
            ) {
                await petSession.deleteSession(sess.activity_id);
            } else {
                throw err;
            }
        }
    }
}