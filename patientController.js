const prisma = require('../utils/db');
const logger = require('../utils/logger');
const { createNotification } = require('../utils/notifications');

const getProfile = async (req, res) => {
  try {
    const patient = await prisma.patient.findUnique({
      where: { userId: req.user.userId },
      include: { user: { select: { email: true } } },
    });
    if (!patient) {
      return res.status(404).json({ error: 'Patient profile not found' });
    }
    res.json({ patient });
  } catch (err) {
    logger.error(`Get patient profile error: ${err.message}`);
    res.status(500).json({ error: 'Internal server error' });
  }
};

const updateProfile = async (req, res) => {
  const { name, dob, phone, gender, symptoms, address } = req.body;

  try {
    const data = {};
    if (name !== undefined) data.name = name;
    if (dob !== undefined) data.dob = dob;
    if (phone !== undefined) data.phone = phone;
    if (gender !== undefined) data.gender = gender;
    if (symptoms !== undefined) data.symptoms = symptoms;
    if (address !== undefined) data.address = address;

    const patient = await prisma.patient.update({
      where: { userId: req.user.userId },
      data,
      include: { user: { select: { email: true } } },
    });
    res.json({ message: 'Profile updated', patient });
  } catch (err) {
    logger.error(`Update patient profile error: ${err.message}`);
    res.status(500).json({ error: 'Internal server error' });
  }
};

const searchDoctors = async (req, res) => {
  const { q, specialty, location, area } = req.query;

  try {
    const where = {};
    if (q && q.trim()) {
      const trimmedQ = q.trim();
      const cleanQ = trimmedQ.replace(/^dr\.?\s*/i, '').trim();

      const searchTerms = Array.from(new Set([
        trimmedQ,
        cleanQ,
        `Dr. ${cleanQ}`,
        `Dr.${cleanQ}`,
        `Dr ${cleanQ}`
      ])).filter(t => t.length > 0);

      where.OR = searchTerms.flatMap(term => [
        { name: { contains: term, mode: 'insensitive' } },
        { specialty: { contains: term, mode: 'insensitive' } },
        { hospital: { contains: term, mode: 'insensitive' } },
        { area: { contains: term, mode: 'insensitive' } },
        { location: { contains: term, mode: 'insensitive' } },
      ]);
    }
    if (specialty) {
      where.specialty = { contains: specialty, mode: 'insensitive' };
    }
    if (area) {
      where.area = { contains: area, mode: 'insensitive' };
    }
    if (location) {
      where.location = { contains: location, mode: 'insensitive' };
    }

    const doctors = await prisma.doctor.findMany({
      where,
      include: {
        user: { select: { email: true } },
        timeSlots: { orderBy: [{ day: 'asc' }, { startTime: 'asc' }] },
        _count: { select: { reviews: true } },
      },
      orderBy: [{ rating: 'desc' }, { name: 'asc' }],
    });

    res.json({ doctors });
  } catch (err) {
    logger.error(`Search doctors error: ${err.message}`);
    res.status(500).json({ error: 'Internal server error' });
  }
};

const getDoctorDetails = async (req, res) => {
  const { id } = req.params;

  try {
    const doctor = await prisma.doctor.findUnique({
      where: { userId: Number(id) },
      include: {
        user: { select: { email: true } },
        timeSlots: { orderBy: [{ day: 'asc' }, { startTime: 'asc' }] },
        reviews: {
          include: {
            patient: { select: { name: true } },
          },
          orderBy: { id: 'desc' },
        },
      },
    });

    if (!doctor) {
      return res.status(404).json({ error: 'Doctor not found' });
    }

    res.json({ doctor });
  } catch (err) {
    logger.error(`Get doctor details error: ${err.message}`);
    res.status(500).json({ error: 'Internal server error' });
  }
};

const bookAppointment = async (req, res) => {
  const { doctorId, date, time, reason } = req.body;

  if (!doctorId || !date || !time) {
    return res.status(400).json({ error: 'doctorId, date and time are required' });
  }

  try {
    const doctor = await prisma.doctor.findUnique({ where: { userId: Number(doctorId) } });
    if (!doctor) {
      return res.status(404).json({ error: 'Doctor not found' });
    }

    const appointmentDate = new Date(date);
    if (isNaN(appointmentDate.getTime())) {
      return res.status(400).json({ error: 'Invalid date' });
    }

    const appointment = await prisma.appointment.create({
      data: {
        patientId: req.user.userId,
        doctorId: Number(doctorId),
        date: appointmentDate,
        time,
        reason: reason || null,
        status: 'pending',
      },
    });

    // Notify doctor
    await createNotification(
      Number(doctorId),
      'New Appointment Request',
      `A patient requested an appointment on ${appointmentDate.toDateString()} at ${time}.`
    );

    // Notify patient
    const locationInfo = doctor.hospital ? `${doctor.hospital}, ${doctor.area || ''}` : (doctor.location || 'Clinic');
    await createNotification(
      req.user.userId,
      'Appointment Booked Successfully!',
      `Appointment with Dr. ${doctor.name} (${doctor.specialty || 'Specialist'}) at ${locationInfo} on ${appointmentDate.toDateString()} at ${time}.`
    );

    res.status(201).json({ message: 'Appointment requested successfully', appointment, doctor });
  } catch (err) {
    logger.error(`Book appointment error: ${err.message}`);
    res.status(500).json({ error: 'Internal server error' });
  }
};

const getAppointments = async (req, res) => {
  try {
    const appointments = await prisma.appointment.findMany({
      where: { patientId: req.user.userId },
      include: {
        doctor: {
          include: { user: { select: { email: true } } },
        },
      },
      orderBy: [{ date: 'desc' }, { time: 'asc' }],
    });
    res.json({ appointments });
  } catch (err) {
    logger.error(`Get patient appointments error: ${err.message}`);
    res.status(500).json({ error: 'Internal server error' });
  }
};

const cancelAppointment = async (req, res) => {
  const { id } = req.params;

  try {
    const appointment = await prisma.appointment.findUnique({
      where: { id: Number(id) },
      include: { doctor: { select: { name: true } } },
    });

    if (!appointment) {
      return res.status(404).json({ error: 'Appointment not found' });
    }
    if (appointment.patientId !== req.user.userId) {
      return res.status(403).json({ error: 'Access denied' });
    }
    if (appointment.status !== 'pending' && appointment.status !== 'accepted') {
      return res.status(400).json({ error: 'This appointment cannot be cancelled' });
    }

    const updated = await prisma.appointment.update({
      where: { id: Number(id) },
      data: { status: 'cancelled' },
    });

    await createNotification(
      appointment.doctorId,
      'Appointment Cancelled',
      `A patient cancelled their appointment on ${appointment.date.toDateString()} at ${appointment.time}.`
    );

    res.json({ message: 'Appointment cancelled', appointment: updated });
  } catch (err) {
    logger.error(`Cancel appointment error: ${err.message}`);
    res.status(500).json({ error: 'Internal server error' });
  }
};

const rateDoctor = async (req, res) => {
  const { doctorId, rating, comment } = req.body;

  if (!doctorId || !rating) {
    return res.status(400).json({ error: 'doctorId and rating are required' });
  }
  const numRating = Number(rating);
  if (!Number.isInteger(numRating) || numRating < 1 || numRating > 5) {
    return res.status(400).json({ error: 'rating must be an integer between 1 and 5' });
  }

  try {
    const doctor = await prisma.doctor.findUnique({ where: { userId: Number(doctorId) } });
    if (!doctor) {
      return res.status(404).json({ error: 'Doctor not found' });
    }

    const review = await prisma.review.upsert({
      where: {
        patientId_doctorId: {
          patientId: req.user.userId,
          doctorId: Number(doctorId),
        },
      },
      update: { rating: numRating, comment: comment || null },
      create: {
        patientId: req.user.userId,
        doctorId: Number(doctorId),
        rating: numRating,
        comment: comment || null,
      },
    });

    const agg = await prisma.review.aggregate({
      where: { doctorId: Number(doctorId) },
      _avg: { rating: true },
    });

    await prisma.doctor.update({
      where: { userId: Number(doctorId) },
      data: { rating: agg._avg.rating },
    });

    res.json({ message: 'Review submitted', review });
  } catch (err) {
    logger.error(`Rate doctor error: ${err.message}`);
    res.status(500).json({ error: 'Internal server error' });
  }
};

module.exports = {
  getProfile,
  updateProfile,
  searchDoctors,
  getDoctorDetails,
  bookAppointment,
  getAppointments,
  cancelAppointment,
  rateDoctor,
};
