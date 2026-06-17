const mongoose = require('mongoose');
const { readDbPassword } = require('../utils/dbCredentials');

mongoose.set('strictQuery', false);

// W10 Lab 2.1: if MONGO_URI contains the literal placeholder
// "__DB_PASSWORD__", substitute the value currently on disk (synced from AWS
// Secrets Manager by ESO). The fallback (no placeholder) keeps local dev
// working with the plain MONGO_URI from W9.
function resolveMongoUri() {
    const base = process.env.MONGO_URI || '';
    if (!base.includes('__DB_PASSWORD__')) return base;
    const pw = readDbPassword();
    return base.replace('__DB_PASSWORD__', encodeURIComponent(pw));
}

const connectDatabase = () => {
    const uri = resolveMongoUri();
    mongoose.connect(uri, { useNewUrlParser: true, useUnifiedTopology: true })
        .then(() => {
            console.log('Mongoose Connected');
        });
};

module.exports = connectDatabase;
