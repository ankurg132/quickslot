const express = require('express');
const router = express.Router();
const venueController = require('../controllers/venue.controller');

router.get('/', venueController.getAllVenues);
router.get('/:id/slots', venueController.getVenueSlots);

module.exports = router;
