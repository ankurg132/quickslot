const { pool } = require('../config/db');
const { formatDbTime } = require('../utils/time.util');

class VenueService {
  /**
   * Get all venues ordered by id
   */
  async getAllVenues() {
    const result = await pool.query('SELECT * FROM venues ORDER BY id ASC');
    return result.rows;
  }

  /**
   * Get venue slots for a specific date
   * @param {string} venueId
   * @param {string} dateStr - Format YYYY-MM-DD
   */
  async getVenueSlots(venueId, dateStr) {
    // Check if venue exists
    const venueCheck = await pool.query('SELECT id FROM venues WHERE id = $1', [venueId]);
    if (venueCheck.rows.length === 0) {
      throw { status: 404, message: 'Venue not found' };
    }

    // Fetch existing bookings for this venue and date
    const bookingsResult = await pool.query(
      'SELECT start_time, user_id FROM bookings WHERE venue_id = $1 AND booking_date = $2',
      [venueId, dateStr]
    );

    // Create a map of booked times for O(1) lookup
    const bookedTimes = {};
    bookingsResult.rows.forEach(row => {
      const formattedTime = formatDbTime(row.start_time);
      bookedTimes[formattedTime] = row.user_id;
    });

    // Generate fixed hourly slots from 6 AM (06:00) to 10 PM (22:00)
    // The last slot starts at 21:00 and ends at 22:00.
    const slots = [];
    for (let hour = 6; hour <= 21; hour++) {
      const startHourStr = hour.toString().padStart(2, '0') + ':00';
      const endHourStr = (hour + 1).toString().padStart(2, '0') + ':00';
      
      const bookedBy = bookedTimes[startHourStr] || null;
      slots.push({
        start_time: startHourStr,
        end_time: endHourStr,
        status: bookedBy ? 'booked' : 'available',
        booked_by: bookedBy,
      });
    }

    return slots;
  }
}

module.exports = new VenueService();
