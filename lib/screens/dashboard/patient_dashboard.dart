import 'package:flutter/material.dart';
import 'package:contact_manager_app/services/location_service.dart';
import 'package:contact_manager_app/services/user_data_service.dart';
import 'package:contact_manager_app/services/appointment_service.dart';
import 'package:contact_manager_app/models/appointment_models.dart';
import 'search_screen.dart';
import 'hospital_list_screen.dart';
import 'book_appointment_screen.dart';
import 'my_appointments_screen.dart';
import '../profile_screen.dart';
import '../notifications_screen.dart';

class PatientDashboard extends StatefulWidget {
  const PatientDashboard({super.key});

  @override
  State<PatientDashboard> createState() => _PatientDashboardState();
}

class _PatientDashboardState extends State<PatientDashboard> {
  final TextEditingController _searchController = TextEditingController();
  final LocationService _locationService = LocationService();
  final AppointmentService _appointmentService = AppointmentService();

  MyAppointment? _upcomingAppointment;
  bool _loadingAppointments = true;

  Color get primaryColor => const Color(0xFF8c6239);
  Color get bgColor => const Color(0xfff2f2f2);

  @override
  void initState() {
    super.initState();
    _loadLocationIfNeeded();
    _loadUpcomingAppointment();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('DEBUG PatientDashboard: Location loaded = ${UserDataService().isLocationLoaded}');
      print('DEBUG PatientDashboard: City = ${UserDataService().cityName}');
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadLocationIfNeeded() async {
    if (!UserDataService().isLocationLoaded) {
      try {
        final position = await _locationService.getCurrentLocation();
        final city = await _locationService.getCityName(position.latitude, position.longitude);

        UserDataService().latitude = position.latitude;
        UserDataService().longitude = position.longitude;
        UserDataService().cityName = city;

        print('DEBUG: Location loaded on dashboard - City: $city');
      } catch (e) {
        print('DEBUG: Could not get location on dashboard: $e');
      }
    } else {
      print('DEBUG: Location already loaded - City: ${UserDataService().cityName}');
    }
  }

  Future<void> _loadUpcomingAppointment() async {
    try {
      final appointments = await _appointmentService.getMyAppointments();
      final upcoming = appointments.where((a) {
        final status = a.status.toLowerCase();
        return status == 'confirmed' || status == 'scheduled' || status == 'pending';
      }).firstOrNull;

      setState(() {
        _upcomingAppointment = upcoming;
        _loadingAppointments = false;
      });
    } catch (e) {
      print('DEBUG: Could not load appointments: $e');
      setState(() {
        _loadingAppointments = false;
      });
    }
  }

  String _getTimeRemaining(String appointmentDate, String appointmentTime) {
    try {
      final now = DateTime.now();
      final dateParts = appointmentDate.split('-');
      if (dateParts.length != 3) return '';

      final year = int.parse(dateParts[0]);
      final month = int.parse(dateParts[1]);
      final day = int.parse(dateParts[2]);

      final timeParts = appointmentTime.split(':');
      if (timeParts.length < 2) return '';

      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

      final appointmentDateTime = DateTime(year, month, day, hour, minute);
      final difference = appointmentDateTime.difference(now);

      if (difference.isNegative) return 'Past';

      final days = difference.inDays;
      final hours = difference.inHours % 24;

      if (days > 0) {
        return '${days}D ${hours}h';
      } else if (hours > 0) {
        final minutes = difference.inMinutes % 60;
        return '${hours}h ${minutes}m';
      } else {
        return '${difference.inMinutes}m';
      }
    } catch (e) {
      print('DEBUG: Error calculating time remaining: $e');
      return '';
    }
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
                          'Hi, Patient 👋',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Stay safe and follow your doctor\'s advice',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  Stack(
                    children: [
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
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 20,
                            minHeight: 20,
                          ),
                          child: const Text(
                            '3',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search doctor or medicines',
                          prefixIcon: Icon(Icons.search, color: primaryColor),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(vertical: 0),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onSubmitted: (query) {
                          if (query.trim().isNotEmpty) {
                            print('DEBUG: Search submitted from dashboard: ${query.trim()}');
                            print('DEBUG: Current city: ${UserDataService().cityName}');
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SearchScreen(initialQuery: query.trim()),
                              ),
                            );
                          }
                        },
                      ),
                    ),

                    const SizedBox(height: 12),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        height: 140,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8c6239),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'New to our Hospital?',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Get your first consultation\nwith a special discount.',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryColor,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 10,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                    onPressed: () {},
                                    child: const Text('Claim now'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Upcoming Consultation',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const MyAppointmentsScreen(),
                                ),
                              );
                            },
                            child: const Text(
                              'View All',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blueAccent,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _loadingAppointments
                          ? Center(child: CircularProgressIndicator(color: primaryColor))
                          : _upcomingAppointment == null
                              ? _buildNoAppointmentCard()
                              : _buildAppointmentCard(_upcomingAppointment!),
                    ),

                    const SizedBox(height: 16),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Medical Services',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'View all',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blueAccent,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: _serviceItem(Icons.science, 'Laboratory'),
                          ),
                          Expanded(
                            child: _serviceItem(Icons.bloodtype, 'Transfusion'),
                          ),
                          Expanded(
                            child: _serviceItem(Icons.vaccines, 'Vaccine'),
                          ),
                          Expanded(
                            child: _serviceItem(Icons.local_hospital, 'X-Ray'),
                          ),
                        ],
                      ),
                    ),
                  ],
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
                    active: true,
                    onTap: () {},
                  ),
                  _bottomItem(
                    icon: Icons.local_hospital,
                    label: 'Hospital',
                    active: false,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const HospitalListScreen(),
                        ),
                      );
                    },
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
                    icon: Icons.local_pharmacy,
                    label: 'Pharmacy',
                    active: false,
                    onTap: () {},
                  ),
                  _bottomItem(
                    icon: Icons.person,
                    label: 'Profile',
                    active: false,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ProfileScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoAppointmentCard() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const BookAppointmentScreen(),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(Icons.add_circle_outline, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              'No upcoming appointments',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              'Book now to get started',
              style: TextStyle(fontSize: 12, color: primaryColor, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(MyAppointment appointment) {
    final timeRemaining = _getTimeRemaining(appointment.date, appointment.time);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const MyAppointmentsScreen(),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Icon(Icons.timelapse, size: 20),
                  const SizedBox(height: 4),
                  Text(
                    'TK${appointment.id}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  if (timeRemaining.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(timeRemaining, style: const TextStyle(fontSize: 10)),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appointment.reason.isNotEmpty ? appointment.reason : 'Consultation',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${appointment.date} · ${appointment.time}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Dr. ${appointment.doctor.name}',
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: appointment.statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: appointment.statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    appointment.statusDisplay,
                    style: TextStyle(fontSize: 10, color: appointment.statusColor, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _serviceItem(IconData icon, String label) {
    const primaryColor = Color(0xFF8c6239);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, color: primaryColor, size: 20),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
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
