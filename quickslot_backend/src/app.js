const express = require('express');
const cors = require('cors');

const venueRoutes = require('./routes/venue.routes');
const bookingRoutes = require('./routes/booking.routes');
const { errorHandler } = require('./middlewares/errorHandler.middleware');

const app = express();

// Middlewares
app.use(cors());
app.use(express.json());

// Request Logging Middleware
app.use((req, res, next) => {
  console.log(`[${new Date().toISOString()}] ${req.method} ${req.url}`);
  next();
});

// Routes
app.use('/venues', venueRoutes);
app.use('/bookings', bookingRoutes);
// Moving /users/:id/bookings under /bookings router or keep it separate.
// To keep exactly same URL /users/:id/bookings as requested previously:
app.get('/users/:id/bookings', require('./controllers/booking.controller').getUserBookings);


// Global Error Handler
app.use(errorHandler);

module.exports = app;
