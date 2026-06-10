const bookingService = require('../services/booking.service');

class BookingController {
  async createBooking(req, res, next) {
    const { venue_id, date, start_time } = req.body;
    const userId = req.userId; // Provided by auth middleware

    // Validation
    if (!venue_id || !date || !start_time) {
      return res.status(400).json({ error: 'Bad Request', message: 'venue_id, date, and start_time are required' });
    }

    // Validate date format YYYY-MM-DD
    const dateRegex = /^\d{4}-\d{2}-\d{2}$/;
    if (!dateRegex.test(date) || isNaN(Date.parse(date))) {
      return res.status(400).json({ error: 'Bad Request', message: 'Invalid date format. Use YYYY-MM-DD' });
    }

    // Validate start_time format HH:00
    const timeRegex = /^(0[6-9]|1[0-9]|2[0-1]):00$/;
    if (!timeRegex.test(start_time)) {
      return res.status(400).json({ 
        error: 'Bad Request', 
        message: 'Invalid start_time. Must be an hourly slot between 06:00 and 21:00 (e.g., 07:00, 14:00)' 
      });
    }

    try {
      const booking = await bookingService.createBooking({ venue_id, date, start_time, userId });
      return res.status(201).json({
        message: 'Booking successful',
        booking,
      });
    } catch (err) {
      if (err.status) {
        return res.status(err.status).json({ error: 'Bad Request', message: err.message });
      }
      // Passed to global error handler for PG unique constraint violations
      next(err);
    }
  }

  async getUserBookings(req, res, next) {
    const userId = req.params.id;
    try {
      const bookings = await bookingService.getUserBookings(userId);
      res.json(bookings);
    } catch (err) {
      next(err);
    }
  }

  async cancelBooking(req, res, next) {
    const bookingId = req.params.id;
    const userId = req.userId; // Provided by auth middleware

    try {
      await bookingService.cancelBooking(bookingId, userId);
      res.json({ message: 'Booking cancelled successfully' });
    } catch (err) {
      if (err.status) {
        return res.status(err.status).json({ error: err.status === 404 ? 'Not Found' : 'Forbidden', message: err.message });
      }
      next(err);
    }
  }
}

module.exports = new BookingController();
