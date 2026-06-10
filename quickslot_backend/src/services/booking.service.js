const { pool } = require('../config/db');
const { formatDbTime } = require('../utils/time.util');

class BookingService {
  /**
   * Create a new booking
   * @param {Object} bookingData 
   * @returns {Object} created booking
   */
  async createBooking(bookingData) {
    const { venue_id, date, start_time, userId } = bookingData;

    // Verify booking date is not in the past (only date part)
    const todayStr = new Date().toISOString().split('T')[0];
    if (date < todayStr) {
      throw { status: 400, message: 'Cannot book slots in the past' };
    }

    // Attempt to insert the booking
    const result = await pool.query(
      `INSERT INTO bookings (venue_id, booking_date, start_time, user_id)
       VALUES ($1, $2, $3, $4)
       RETURNING id, venue_id, booking_date, start_time, user_id, created_at`,
      [venue_id, date, start_time, userId]
    );

    const booking = result.rows[0];
    booking.start_time = formatDbTime(booking.start_time);
    // Date object/string formatting handled by pg type parser
    booking.booking_date = booking.booking_date;

    return booking;
  }

  /**
   * Get bookings for a specific user
   * @param {string} userId 
   */
  async getUserBookings(userId) {
    const result = await pool.query(
      `SELECT b.id, b.venue_id, v.name as venue_name, v.sport, v.location, b.booking_date, b.start_time, b.created_at
       FROM bookings b
       JOIN venues v ON b.venue_id = v.id
       WHERE b.user_id = $1
       ORDER BY b.booking_date ASC, b.start_time ASC`,
      [userId]
    );

    return result.rows.map(row => ({
      id: row.id,
      venue_id: row.venue_id,
      venue_name: row.venue_name,
      sport: row.sport,
      location: row.location,
      date: row.booking_date,
      start_time: formatDbTime(row.start_time),
      created_at: row.created_at,
    }));
  }

  /**
   * Cancel a booking by id and verifying user ownership
   * @param {string} bookingId 
   * @param {string} userId 
   */
  async cancelBooking(bookingId, userId) {
    // Find the booking first
    const bookingCheck = await pool.query('SELECT user_id FROM bookings WHERE id = $1', [bookingId]);

    if (bookingCheck.rows.length === 0) {
      throw { status: 404, message: 'Booking not found' };
    }

    // Verify ownership
    if (bookingCheck.rows[0].user_id !== userId) {
      throw { status: 403, message: "You cannot cancel another user's booking" };
    }

    // Delete the booking
    await pool.query('DELETE FROM bookings WHERE id = $1', [bookingId]);
  }
}

module.exports = new BookingService();
