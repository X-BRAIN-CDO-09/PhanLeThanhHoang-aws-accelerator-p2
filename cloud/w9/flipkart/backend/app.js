const express = require('express');
const bodyParser = require('body-parser');
const cookieParser = require('cookie-parser');
const fileUpload = require('express-fileupload');
const errorMiddleware = require('./middlewares/error');

const app = express();

// config
if (process.env.NODE_ENV !== 'production') {
    require('dotenv').config({ path: 'backend/config/config.env' });
}

// Prometheus metrics
const promBundle = require("express-prom-bundle");
const metricsMiddleware = promBundle({
    includeMethod: true,
    includePath: true,
    includeStatusCode: true,
    includeUp: true,
    promClient: {
        collectDefaultMetrics: {}
    }
});
app.use(metricsMiddleware);

// Error Injection for Canary Testing
const ERROR_RATE = parseFloat(process.env.ERROR_RATE || "0");
app.use((req, res, next) => {
    if (Math.random() < ERROR_RATE) {
        return res.status(500).json({ error: "Injected error for testing", version: process.env.VERSION || "v1" });
    }
    next();
});

app.use(express.json());
app.use(cookieParser());
app.use(bodyParser.urlencoded({ extended: true }));
app.use(fileUpload());

const user = require('./routes/userRoute');
const product = require('./routes/productRoute');
const order = require('./routes/orderRoute');
const payment = require('./routes/paymentRoute');

app.use('/api/v1', user);
app.use('/api/v1', product);
app.use('/api/v1', order);
app.use('/api/v1', payment);

// error middleware
app.use(errorMiddleware);

module.exports = app;