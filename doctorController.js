const prisma = require('../utils/db');
const logger = require('../utils/logger');
const { createNotification } = require('../utils/notifications');

const DAYS = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

const getProfile = async (req, res) => {
  try {
    const doctor = await prisma.doctor.findUnique({
      where: { userId: req.user.userId },
      include: { user: { select: { email: true } } },
    });
    if (!doctor) {
      return res.status(404).json({ error: 'Doctor profile not found' });
    }
    res.json({ doctor });
  } catch (err) {
    logger.error(`Get doctor profile error: ${err.message}`);
    res.status(500).json({ error: 'Internal server error' });
  }
};

const updateProfile = async (req, res) => {
  const { name, specialty, phone, licenseNumber, experienceYears, bio, consultationFee, location, hospital, area } = req.body;

  try {
    const data = {};
    if (name !== undefined) data.name = name;
    if (specialty !== undefined) data.specialty = specialty;
    if (phone !== undefined) data.phone = phone;
    if (licenseNumber !== undefined) data.licenseNumber = licenseNumber;
    if (experienceYears !== undefined) data.experienceYears = experienceYears;
    if (bio !== undefined) data.bio = bio;
    if (consultationFee !== undefined) data.consultationFee = consultationFee;
    if (location !== undefined) data.location = location;
    if (hospital !== undefined) data.hospital = hospital;
    if (area !== undefined) data.area = area;

    const doctor = await prisma.doctor.update({
      where: { userId: req.user.userId },
      data,
      include: { user: { select: { email: true } } },
    });
    res.json({ message: 'Profile updated', doctor });
  } catch (err) {
    logger.error(`Update doctor profile error: ${err.message}`);
    res.status(500).json({ error: 'Internal server error' });
  }
};

const getTimeSlots = async (req, res) => {
  try {
    const timeSlots = await prisma.timeSlot.findMany({
      where: { doctorId: req.user.userId },
      orderBy: [{ day: 'asc' }, { startTime: 'asc' }],
    });
    res.json({ timeSlots });
  } catch (err) {
    logger.error(`Get time slots error: ${err.message}`);
    res.status(500).json({ error: 'Internal server error' });
  }
};

const setTimeSlots = async (req, res) => {
  const { slots } = req.body;

  if (!Array.isArray(slots)) {
    return res.status(400).json({ error: 'slots must be an array' });
  }

  const valid = slots.every((s) =>
    s &&
    typeof s.day === 'string' &&
    DAYS.includes(s.day) &&
    typeof s.startTime === 'string' &&
    typeof s.endTime === 'string'
  );

  if (!valid) {
    return res.status(400).json({ error: `Each slot must have day (${DAYS.join(', ')}), startTime, endTime` });
  }

  try {
    await prisma.$transaction(async (tx) => {
      await tx.timeSlot.deleteMany({ where: { doctorId: req.user.userId } });
      if (slots.length > 0) {
        await tx.timeSlot.createMany({
          data: slots.map((s) => ({
            doctorId: req.user.userId,
            day: s.day,
            date: s.date || null,
            startTime: s.startTime,
            endTime: s.endTime,
          })),
        });
      }
    });
    res.json({ message: 'Time slots updated' });
  } catch (err) {
    logger.error(`Set time slots error: ${err.message}`);
    res.status(500).json({ error: 'Internal server error' });
  }
};

const getAppointments = async (req, res) => {
  const { status } = req.query;
  try {
    const where = { doctorId: req.user.userId };
    if (status) where.status = status;

    const appointments = await prisma.appointment.findMany({
      where,
      include: {
        patient: { include: { user: { select: { email: true } } } },
      },
      orderBy: [{ date: 'desc' }, { time: 'asc' }],
    });
    res.json({ appointments });
  } catch (err) {
    logger.error(`Get doctor appointments error: ${err.message}`);
    res.status(500).json({ error: 'Internal server error' });
  }
};

const VALID_STATUSES = ['pending', 'accepted', 'rejected', 'completed', 'cancelled'];

const updateAppointmentStatus = async (req, res) => {
  const { id } = req.params;
  const { status } = req.body;

  if (!status || !VALID_STATUSES.includes(status)) {
    return res.status(400).json({ error: `status must be one of: ${VALID_STATUSES.join(', ')}` });
  }

  try {
    const appointment = await prisma.appointment.findUnique({
      where: { id: Number(id) },
    });
    if (!appointment) {
      return res.status(404).json({ error: 'Appointment not found' });
    }
    if (appointment.doctorId !== req.user.userId) {
      return res.status(403).json({ error: 'Access denied' });
    }

    const updated = await prisma.appointment.update({
      where: { id: Number(id) },
      data: { status },
    });

    const messages = {
      accepted: { title: 'Appointment Accepted', message: 'Your appointment request has been accepted.' },
      rejected: { title: 'Appointment Rejected', message: 'Your appointment request has been declined.' },
      completed: { title: 'Appointment Completed', message: 'Your appointment has been marked as completed.' },
      cancelled: { title: 'Appointment Cancelled', message: 'Your appointment has been cancelled.' },
    };

    if (messages[status]) {
      await createNotification(updated.patientId, messages[status].title, messages[status].message);
    }

    res.json({ message: 'Appointment updated', appointment: updated });
  } catch (err) {
    logger.error(`Update appointment status error: ${err.message}`);
    res.status(500).json({ error: 'Internal server error' });
  }
};

const getStats = async (req, res) => {
  try {
    const doctorId = req.user.userId;
    const todayStart = new Date();
    todayStart.setHours(0, 0, 0, 0);
    const todayEnd = new Date(todayStart);
    todayEnd.setDate(todayEnd.getDate() + 1);

    const [totalAppointments, todayAppointments, pendingAppointments, acceptedAppointments, completedAppointments, totalPatients] =
      await Promise.all([
        prisma.appointment.count({ where: { doctorId } }),
        prisma.appointment.count({ where: { doctorId, date: { gte: todayStart, lt: todayEnd } } }),
        prisma.appointment.count({ where: { doctorId, status: 'pending' } }),
        prisma.appointment.count({ where: { doctorId, status: 'accepted' } }),
        prisma.appointment.count({ where: { doctorId, status: 'completed' } }),
        prisma.appointment.groupBy({
          by: ['patientId'],
          where: { doctorId },
        }),
      ]);

    res.json({
      stats: {
        totalAppointments,
        todayAppointments,
        pendingAppointments,
        acceptedAppointments,
        completedAppointments,
        totalPatients: totalPatients.length,
      },
    });
  } catch (err) {
    logger.error(`Get doctor stats error: ${err.message}`);
    res.status(500).json({ error: 'Internal server error' });
  }
};

module.exports = { getProfile, updateProfile, getTimeSlots, setTimeSlots, getAppointments, updateAppointmentStatus, getStats };
