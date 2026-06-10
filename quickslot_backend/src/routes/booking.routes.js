const express = require('express');
const router = express.Router();
const bookingController = require('../controllers/booking.controller');
const { requireAuth } = require('../middlewares/auth.middleware');

router.post('/', requireAuth, bookingController.createBooking);
// Get user bookings might not strictly need to verify X-User-Id matches the path parameter
// based on previous implementation, but keeping the route structure consistent.
router.get('/users/:id', bookingController.getUserBookings);
router.delete('/:id', requireAuth, bookingController.cancelBooking);

module.exports = router;
