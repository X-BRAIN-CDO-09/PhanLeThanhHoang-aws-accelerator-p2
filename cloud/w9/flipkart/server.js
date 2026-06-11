const path = require('path');
const express = require('express');
const fs = require('fs');
const cloudinary = require('cloudinary');
const app = require('./backend/app');
const connectDatabase = require('./backend/config/database');
const PORT = process.env.PORT || 4000;

// UncaughtException Error
process.on('uncaughtException', (err) => {
    console.log(`Error: ${err.message}`);
    process.exit(1);
});

connectDatabase();

cloudinary.config({
    cloud_name: process.env.CLOUDINARY_NAME,
    api_key: process.env.CLOUDINARY_API_KEY,
    api_secret: process.env.CLOUDINARY_API_SECRET,
});

// deployment
const rootDir = path.resolve();
const frontendBuildDir = path.join(rootDir, 'frontend', 'build');
const frontendIndexFile = path.join(frontendBuildDir, 'index.html');

if (process.env.NODE_ENV === 'production' && fs.existsSync(frontendIndexFile)) {
    app.use(express.static(frontendBuildDir));

    app.get('*', (req, res) => {
        res.sendFile(frontendIndexFile)
    });
} else {
    app.get('/', (req, res) => {
        res.send('Server is Running! 🚀');
    });
}

const server = app.listen(PORT, () => {
    console.log(`Server running on http://localhost:${PORT}`)
});

// Unhandled Promise Rejection
process.on('unhandledRejection', (err) => {
    console.log(`Error: ${err.message}`);
    server.close(() => {
        process.exit(1);
    });
});
