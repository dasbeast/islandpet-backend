import express from 'express';
import fs      from 'fs';
import http2   from 'http2';
import jwt     from 'jsonwebtoken';
import { Pool } from 'pg';


// Shared decay logic for both cron and manual endpoint
async function performDecay() {
  console.log(`⚙️ performDecay triggered at ${new Date().toISOString()}`);
  // Expire sessions older than 12 hours
  const expired = await pool.query(
    `DELETE FROM pet_sessions
      WHERE created_at < NOW() - INTERVAL '12 hours'
      RETURNING activity_id`
  );
  expired.rows.forEach(r => console.log(`🗑️ Removed expired session ${r.activity_id}`));

  // Decay persistent pet state
  const { rows: decayedPets } = await pool.query(
    `UPDATE pet_states
       SET hunger       = LEAST(100, hunger + 1),
           happiness    = GREATEST(0, happiness - 1),
           last_updated = NOW()
     WHERE NOW() - last_updated >= INTERVAL '15 seconds'
     RETURNING pet_id, hunger, happiness`
  );
  decayedPets.forEach(petState => {
    console.log(`🗓️ Global decay petID ${petState.pet_id}: new hunger ${petState.hunger}, new happiness ${petState.happiness}`);
  });

  // Get active sessions and current state for pushes
  const { rows } = await pool.query(`
    SELECT ps.activity_id, ps.pet_id, ps.token, s.hunger, s.happiness
      FROM pet_sessions ps
      JOIN pet_states s ON s.pet_id = ps.pet_id
  `);
  for (let pet of rows) {
    console.log(`🔎 Session ${pet.activity_id} for petID ${pet.pet_id}, token: "${pet.token}"`);
    if (!pet.token) {
      console.log(`⚠️ Skipping push for session ${pet.activity_id}, petID ${pet.pet_id}, token: "${pet.token}"`);
      continue;
    }
    //const newHunger    = Math.min(100, pet.hunger + 1);
    //const newHappiness = Math.max(0, pet.happiness - 1);
    //console.log(`🗓️ Decaying petID ${pet.pet_id} (activity ${pet.activity_id}): hunger ${pet.hunger} → ${newHunger}, happiness ${pet.happiness} → ${newHappiness}`);
    //await pool.query(
    //  `UPDATE pet_states
     //    SET hunger = $1,
        //     happiness = $2,
       //      last_updated = NOW()
      // WHERE pet_id = (
      //   SELECT pet_id FROM pet_sessions WHERE activity_id = $3
      // )`,
     // [newHunger, newHappiness, pet.activity_id]
    //);
    console.log(`🐾 Pushing for session ${pet.activity_id}, petID ${pet.pet_id}, token: "${pet.token}"`);
    try {
        await pushAPNs(pet.token, { hunger: pet.hunger, happiness: pet.happiness });
        console.log(`🐾 Updated ${pet.activity_id}: hunger=${pet.hunger}, happiness=${pet.happiness}`);
    } catch (err) {
      const msg = err.message || '';
      if (msg.includes('BadDeviceToken') || msg.includes('ExpiredToken') || msg.includes('Unregistered')) {
        console.log(`🚮 Removing expired or invalid token for ${pet.activity_id}`);
        await pool.query(
          'DELETE FROM pet_sessions WHERE activity_id = $1',
          [pet.activity_id]
        );
      } else {
        console.error(`Error pushing to ${pet.activity_id}:`, err);
      }
    }
  }
}

// Initialize Postgres pool
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false }
});

// Create persistent pet state table
pool.query(`
  CREATE TABLE IF NOT EXISTS pet_states (
    pet_id       TEXT PRIMARY KEY,
    species_id   TEXT NOT NULL,
    hunger       INTEGER NOT NULL DEFAULT 0,
    happiness    INTEGER NOT NULL DEFAULT 100,
    last_updated TIMESTAMPTZ NOT NULL DEFAULT NOW()
  )
`).catch(err => console.error('Error creating pet_states table', err));

// Create ephemeral pet session table
pool.query(`
  CREATE TABLE IF NOT EXISTS pet_sessions (
    activity_id TEXT PRIMARY KEY,
    pet_id      TEXT NOT NULL REFERENCES pet_states(pet_id),
    species_id  TEXT NOT NULL,
    token       TEXT,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(pet_id)
  )
`).catch(err => console.error('Error creating pet_sessions table', err));

// decide which APNs host to use
// Use sandbox only when APNS_ENV is explicitly 'sandbox'; treat TestFlight and production builds as production.
const APNS_HOST = process.env.APNS_ENV === 'sandbox'
  ? 'https://api.sandbox.push.apple.com'
  : 'https://api.push.apple.com';
const { TEAM_ID, KEY_ID, BUNDLE_ID } = process.env;
console.log('ENV VARS:', {
  APNS_ENV: process.env.APNS_ENV,
  APNS_HOST,
  TEAM_ID,
  KEY_ID,
  BUNDLE_ID
});
const key = fs.readFileSync(`./AuthKey_${KEY_ID}.p8`, 'utf8');
const app = express();
app.use(express.json());


app.post('/register', async (req, res) => {
  console.log('→ /register body:', req.body);
  const { activityID, token, petID, speciesID } = req.body;
  try {
    // Ensure persistent pet state exists
    await pool.query(
      `INSERT INTO pet_states(pet_id, species_id, hunger, happiness)
       VALUES($1, $2, 0, 100)
       ON CONFLICT(pet_id) DO NOTHING`,
      [petID, speciesID]
    );
    // Upsert session
    const result = await pool.query(`
      INSERT INTO pet_sessions(activity_id, pet_id, species_id, token)
      VALUES($1, $2, $3, $4)
      ON CONFLICT(pet_id) DO UPDATE
        SET activity_id = EXCLUDED.activity_id,
            species_id  = EXCLUDED.species_id,
            token       = EXCLUDED.token,
            created_at  = NOW()
      RETURNING *
    `, [activityID, petID, speciesID, token]);
    console.log('  INSERT result:', result.rows[0]);
    res.sendStatus(200);
  } catch (err) {
    console.error('Error in /register', err);
    res.sendStatus(500);
  }
});

// Endpoint to update just the APNs token for an existing session
app.post('/register/token', async (req, res) => {
  console.log('→ /register/token body:', req.body);
  const { activityID, token } = req.body;

  try {
    // Update only the token for the given activity
    const result = await pool.query(
      `UPDATE pet_sessions
         SET token = $1
       WHERE activity_id = $2
       RETURNING pet_id`,
      [token, activityID]
    );

    if (!result.rowCount) {
      console.log(`⚠️ No session found for activity ${activityID}`);
      return res.sendStatus(404);
    }

    console.log(`✅ Updated token for session ${activityID}`);
    res.sendStatus(200);
  } catch (err) {
    console.error('Error in /register/token', err);
    res.sendStatus(500);
  }
});

// Endpoint to rename an existing session's activity_id
app.patch('/register/rename-session', async (req, res) => {
  const { oldActivityID, newActivityID } = req.body;
  try {
    const result = await pool.query(
      `UPDATE pet_sessions
         SET activity_id = $1
       WHERE activity_id = $2`,
      [newActivityID, oldActivityID]
    );
    if (!result.rowCount) {
      console.log(`⚠️ No session found to rename from ${oldActivityID} to ${newActivityID}`);
      return res.sendStatus(404);
    }
    console.log(`🔄 Renamed session ${oldActivityID} → ${newActivityID}`);
    res.sendStatus(200);
  } catch (err) {
    console.error('Error in /register/rename-session', err);
    res.sendStatus(500);
  }
});

app.post('/update', async (req, res) => {
  const { petID, state } = req.body;
  try {
    // 1. Persist new state in the database for this pet
    await pool.query(
      `UPDATE pet_states
         SET hunger       = $1,
             happiness    = $2,
             last_updated = NOW()
       WHERE pet_id = $3`,
      [state.hunger, state.happiness, petID]
    );

    // 2. Fetch all active Live-Activity sessions for this pet
    const { rows: sessions } = await pool.query(
      `SELECT activity_id, token
         FROM pet_sessions
        WHERE pet_id = $1`,
      [petID]
    );

    // 3. Push updates to any Live Activity session that has a token
    for (let sess of sessions) {
      if (!sess.token) {
        console.log(`⚠️ Skipping push for session ${sess.activity_id}: no token`);
        continue;
      }
      console.log(`🐾 Pushing update for session ${sess.activity_id}`);
      try {
        await pushAPNs(sess.token, state);
        console.log(`🐾 Pushed state to ${sess.activity_id}`);
      } catch (err) {
        console.error(`Error pushing to ${sess.activity_id}:`, err);
      }
    }

    // 4. Respond OK
    res.sendStatus(200);
  } catch (err) {
    console.error('Error in /update', err);
    res.sendStatus(500);
  }
});

function pushAPNs(token, state) {
  console.log('pushAPNs called:', {
    host: APNS_HOST,
    deviceToken: token,
    topic: `${BUNDLE_ID}.push-type.liveactivity`
  });
  const jwtToken = makeJWT();
  const decoded = jwt.decode(jwtToken, { complete: true });
  console.log('Generated JWT token:', jwtToken);
  console.log('Decoded JWT header:', decoded.header);
  console.log('Decoded JWT payload:', decoded.payload);
  // verify JWT locally before sending
  try {
    const verified = jwt.verify(jwtToken, key, {
      algorithms: ['ES256'],
      issuer: TEAM_ID
    });
    console.log('✅ JWT locally verified:', verified);
  } catch (verificationError) {
    console.error('❌ JWT verification error:', verificationError);
  }
  return new Promise((resolve, reject) => {
    const client = http2.connect(APNS_HOST);
    const req = client.request({
      ':method': 'POST',
      ':path'  : `/3/device/${token}`,
      'apns-topic'    : `${BUNDLE_ID}.push-type.liveactivity`,
      'apns-push-type': 'liveactivity',
      authorization   : `Bearer ${jwtToken}`
    });

    const payload = {
      aps: {
        timestamp: Math.floor(Date.now() / 1000),
        event: 'update',
        'content-state': state
      }
    };

    req.end(JSON.stringify(payload));
    req.on('response', headers => {
      let body = '';
      req.setEncoding('utf8');
      req.on('data', chunk => { body += chunk; });
      req.on('end', () => {
        console.log('APNs status', headers[':status'], body);
        client.close();
        headers[':status'] === 200
          ? resolve()
          : reject(new Error(`APNs ${headers[':status']} ${body}`));
      });
    });
  });
}

function makeJWT() {
  return jwt.sign({}, key, {
    algorithm: 'ES256',
    issuer: TEAM_ID,
    header: { alg: 'ES256', kid: KEY_ID },
    expiresIn: '20m'
  });
}



// Debug endpoint to clear pet_sessions and pet_states tables
app.post('/debug/clear-tables', async (req, res) => {
  try {
    await pool.query('TRUNCATE TABLE pet_sessions, pet_states RESTART IDENTITY CASCADE');
    console.log('⚠️ Debug: cleared pet_sessions and pet_states tables');
    res.sendStatus(200);
  } catch (err) {
    console.error('Error clearing tables:', err);
    res.sendStatus(500);
  }
});

app.listen(8080, () => console.log('Backend running on :8080'))

// Manual decay endpoint for GitHub Actions or external cron
app.post('/decay', async (req, res) => {
  try {
    await performDecay();
    res.sendStatus(200);
  } catch (err) {
    console.error('Error in /decay:', err);
    res.sendStatus(500);
  }
});

// Endpoint to end (delete) a pet’s Live Activity record
app.post('/end', async (req, res) => {
  const { activityID } = req.body;
  try {
    await pool.query(
      'DELETE FROM pet_sessions WHERE activity_id = $1',
      [activityID]
    );
    console.log(`🗑️ Deleted pet record for activity ${activityID}`);
    res.sendStatus(200);
  } catch (err) {
    console.error('Error in /end:', err);
    res.sendStatus(500);
  }
});

// Endpoint to delete all data for a specific pet (session and state)
app.delete('/pets/:petID', async (req, res) => {
  const { petID } = req.params;
  try {
    // Remove the session for this pet
    await pool.query(
      'DELETE FROM pet_sessions WHERE pet_id = $1',
      [petID]
    );
    // Remove the persistent state for this pet
    await pool.query(
      'DELETE FROM pet_states WHERE pet_id = $1',
      [petID]
    );
    console.log(`🗑️ Completely removed pet data for petID ${petID}`);
    res.sendStatus(200);
  } catch (err) {
    console.error('Error in DELETE /pets/:petID', err);
    res.sendStatus(500);
  }
});

app.get('/pets/:petID', async (req, res) => {
  const { petID } = req.params;
  const { rows } = await pool.query(
    `SELECT pet_id AS "petID", species_id AS "speciesID", hunger, happiness, last_updated
       FROM pet_states
      WHERE pet_id = $1`,
    [petID]
  );
  if (!rows.length) return res.status(404).end();
  res.json(rows[0]);
});
