const venueService = require('../services/venue.service');

class VenueController {
  async getAllVenues(req, res, next) {
    try {
      const venues = await venueService.getAllVenues();
      res.json(venues);
    } catch (err) {
      next(err);
    }
  }

  async getVenueSlots(req, res, next) {
    const venueId = req.params.id;
    const dateStr = req.query.date;

    if (!dateStr) {
      return res.status(400).json({ error: 'Bad Request', message: 'date query parameter is required' });
    }

    // Basic validation of YYYY-MM-DD format
    const dateRegex = /^\d{4}-\d{2}-\d{2}$/;
    if (!dateRegex.test(dateStr) || isNaN(Date.parse(dateStr))) {
      return res.status(400).json({ error: 'Bad Request', message: 'Invalid date format. Use YYYY-MM-DD' });
    }

    try {
      const slots = await venueService.getVenueSlots(venueId, dateStr);
      res.json(slots);
    } catch (err) {
      if (err.status) {
        return res.status(err.status).json({ error: 'Not Found', message: err.message });
      }
      next(err);
    }
  }
}

module.exports = new VenueController();
