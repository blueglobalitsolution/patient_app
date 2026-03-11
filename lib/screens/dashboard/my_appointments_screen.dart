import 'package:flutter/material.dart';
import '../../models/appointment_models.dart';
import '../../services/storage_service.dart';
import '../../services/notification_service.dart';
import 'patient_dashboard.dart';
import 'book_appointment_screen.dart';
import '../../widgets/custom_bottom_navigation_bar.dart';

class MyAppointmentsScreen extends StatefulWidget {
  const MyAppointmentsScreen({super.key});

  @override
  State<MyAppointmentsScreen> createState() => _MyAppointmentsScreenState();
}

class _MyAppointmentsScreenState extends State<MyAppointmentsScreen> {
  final _storage = StorageService();
  List<MyAppointment> _appointments = [];
  bool _loading = true;

  Color get primaryColor => const Color(0xFF8c6239);
  Color get bgColor => const Color(0xfff2f2f2);

  bool _isTodayAppointment(String appointmentDate) {
    try {
      final now = DateTime.now();
      final dateParts = appointmentDate.split('-');
      if (dateParts.length != 3) return false;

      final year = int.parse(dateParts[0]);
      final month = int.parse(dateParts[1]);
      final day = int.parse(dateParts[2]);

      return year == now.year && month == now.month && day == now.day;
    } catch (e) {
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    setState(() {
      _loading = true;
    });
    try {
      final appointments = await _storage.getAppointments();
      final sortedAppointments = _sortAppointmentsByProximity(appointments);
      setState(() {
        _appointments = sortedAppointments;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load appointments: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  List<MyAppointment> _sortAppointmentsByProximity(List<MyAppointment> appointments) {
    final now = DateTime.now();
    
    return appointments.where((appointment) {
      final appointmentTime = appointment.appointmentDateTime;
      return appointmentTime != null && appointmentTime.isAfter(now);
    }).toList()..sort((a, b) {
      final timeA = a.appointmentDateTime;
      final timeB = b.appointmentDateTime;
      
      if (timeA == null && timeB == null) return 0;
      if (timeA == null) return 1;
      if (timeB == null) return -1;
      
      return timeA.compareTo(timeB);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'My Appointments',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Manage your upcoming appointments',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Icon(Icons.notifications_none, color: primaryColor),
                  ),
                ],
              ),
            ),

            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _appointments.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No appointments yet',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const BookAppointmentScreen(),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                ),
                                child: const Text('Book Appointment'),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadAppointments,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _appointments.length,
                            itemBuilder: (context, index) {
                              final appointment = _appointments[index];
                              return _AppointmentCard(
                                appointment: appointment,
                              );
                            },
                          ),
                        ),
            ),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _bottomItem(
                    icon: Icons.home,
                    label: 'Home',
                    active: false,
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PatientDashboard(),
                        ),
                      );
                    },
                  ),
                  _bottomItem(
                    icon: Icons.event,
                    label: 'Appointments',
                    active: true,
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const BookAppointmentScreen(),
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: primaryColor,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(14),
                      child: const Icon(Icons.add, color: Colors.white),
                    ),
                  ),
                  _bottomItem(
                    icon: Icons.history,
                    label: 'History',
                    active: false,
                    onTap: () {},
                  ),
                  _bottomItem(
                    icon: Icons.person,
                    label: 'Profile',
                    active: false,
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _bottomItem({
    required IconData icon,
    required String label,
    required bool active,
    VoidCallback? onTap,
  }) {
    const primaryColor = Color(0xFF8c6239);

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: active ? primaryColor : Colors.grey),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: active ? primaryColor : Colors.grey,
          ),
        ),
      ],
    );

    if (onTap == null) return content;
    return GestureDetector(onTap: onTap, child: content);
  }
}

class _AppointmentCard extends StatelessWidget {
  final MyAppointment appointment;

  const _AppointmentCard({
    required this.appointment,
  });

  bool _isTodayAppointment(String appointmentDate) {
    try {
      final now = DateTime.now();
      final dateParts = appointmentDate.split('-');
      if (dateParts.length != 3) return false;

      final year = int.parse(dateParts[0]);
      final month = int.parse(dateParts[1]);
      final day = int.parse(dateParts[2]);

      return year == now.year && month == now.month && day == now.day;
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isToday = _isTodayAppointment(appointment.date);
    final todayColor = isToday ? Colors.green : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isToday ? Border.all(color: Colors.green.shade300, width: 2) : null,
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (todayColor ?? appointment.statusColor).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isToday ? 'Today' : appointment.statusDisplay,
                  style: TextStyle(
                    fontSize: 11,
                    color: todayColor ?? appointment.statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          // NEW: Department Name - Big and prominent
          if (appointment.department?.isNotEmpty == true)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: isToday ? Colors.green.shade50 : const Color(0xFF8c6239).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: isToday ? Border.all(color: Colors.green.shade200) : null,
              ),
              child: Text(
                appointment.department!,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isToday ? Colors.green.shade700 : const Color(0xFF8c6239),
                ),
              ),
            ),
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xfff2f2f2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.person, color: Colors.grey),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${appointment.doctor.name}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      appointment.doctor.specialization,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    if (appointment.hospitalName != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        appointment.hospitalName!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                appointment.date,
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              ),
              const SizedBox(width: 16),
              Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                appointment.time,
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Reason: ${appointment.reason}',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
           ),
          ],
      ),
    );
  }
}
