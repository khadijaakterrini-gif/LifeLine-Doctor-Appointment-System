const express = require('express');
const { authenticate, authorize } = require('../middleware/auth');
const {
  getProfile,
  updateProfile,
  getTimeSlots,
  setTimeSlots,
  getAppointments,
  updateAppointmentStatus,
  getStats,
} = require('../controllers/doctorController');

const router = express.Router();

router.use(authenticate, authorize('doctor'));

router.get('/profile', getProfile);
router.put('/profile', updateProfile);
router.get('/time-slots', getTimeSlots);
router.put('/time-slots', setTimeSlots);
router.get('/appointments', getAppointments);
router.put('/appointments/:id/status', updateAppointmentStatus);
router.get('/stats', getStats);

module.exports = router;
