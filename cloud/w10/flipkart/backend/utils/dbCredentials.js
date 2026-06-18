// [w10-pm NEW] Created for w10_afternoon_secrets_supply_chain lab — Lab 2.1 ESO
// W10 Lab 2.1 — read the DB password from the ESO-synced volume.
//
// The container env exposes DB_PASSWORD_FILE (see k8s/backend/rollout.yaml).
// We re-read the file on every call so a Secrets Manager rotation (synced by
// ESO every 60s) is picked up with zero pod restart.

const fs = require('fs');
const crypto = require('crypto');

const DEFAULT_FILE = '/etc/flipkart/db/password';

function getDbPasswordFile() {
    return process.env.DB_PASSWORD_FILE || DEFAULT_FILE;
}

function readDbPassword() {
    const filePath = getDbPasswordFile();
    try {
        return fs.readFileSync(filePath, 'utf8').trim();
    } catch (_) {
        // Fallback: legacy env var (so local dev still works without ESO).
        return process.env.DB_PASSWORD || '';
    }
}

function dbPasswordFingerprint() {
    const pw = readDbPassword();
    if (!pw) return null;
    return crypto.createHash('sha256').update(pw).digest('hex').slice(0, 12);
}

module.exports = { readDbPassword, dbPasswordFingerprint, getDbPasswordFile };
