import jwt from 'jsonwebtoken';
import fs from 'fs';
import config from '../config';

const key = fs.readFileSync(`./AuthKey_${config.keyId}.p8`, 'utf8');

export function signJWT(payload, opts = {}) {
    return jwt.sign(payload, key, { algorithm: 'ES256', issuer: config.teamId, header: { kid: config.keyId }, ...opts });
}