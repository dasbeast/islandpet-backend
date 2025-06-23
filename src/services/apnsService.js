import http2 from 'http2';
import jwt   from 'jsonwebtoken';
import fs    from 'fs';
import config from '../config/index.js';

const key = fs.readFileSync(`./AuthKey_${config.keyId}.p8`, 'utf8');

function makeJWT() {
    return jwt.sign({}, key, {
        algorithm: 'ES256',
        issuer:    config.teamId,
        header:    { alg: 'ES256', kid: config.keyId },
        expiresIn: '20m'
    });
}

export async function pushToAPNs(token, state) {
    const jwtToken = makeJWT();
    const client = http2.connect(
        config.apnsEnv === 'sandbox'
            ? 'https://api.sandbox.push.apple.com'
            : 'https://api.push.apple.com'
    );
    const req = client.request({
        ':method':       'POST',
        ':path':         `/3/device/${token}`,
        'apns-topic':    `${config.bundleId}.push-type.liveactivity`,
        'apns-push-type':'liveactivity',
        authorization:   `Bearer ${jwtToken}`
    });

    req.end(JSON.stringify({
        aps: {
            timestamp: Math.floor(Date.now()/1000),
            event:     'update',
            'content-state': state
        }
    }));

    return new Promise((resolve, reject) => {
        let body = '';
        req.on('response', headers => {
            req.setEncoding('utf8');
            req.on('data', chunk => body += chunk);
            req.on('end', () => {
                client.close();
                headers[':status'] === 200
                    ? resolve()
                    : reject(new Error(`APNs ${headers[':status']} ${body}`));
            });
        });
    });
}