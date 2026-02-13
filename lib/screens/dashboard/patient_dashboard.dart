import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart' as slider;
import 'package:contact_manager_app/services/location_service.dart';
import 'package:contact_manager_app/services/user_data_service.dart';
import 'package:contact_manager_app/services/storage_service.dart';
import 'package:contact_manager_app/services/patient_service.dart';
import 'package:contact_manager_app/models/appointment_models.dart';
import 'search_screen.dart';
import 'hospital_list_screen.dart';
import 'my_appointments_screen.dart';
import '../profile_screen.dart';
import '../notifications_screen.dart';
import '../booking/department_list_screen.dart';
import '../../widgets/custom_bottom_navigation_bar.dart';

class PatientDashboard extends StatefulWidget {
  const PatientDashboard({super.key});

  @override
  State<PatientDashboard> createState() => _PatientDashboardState();
}

class _PatientDashboardState extends State<PatientDashboard> {
  final TextEditingController _searchController = TextEditingController();
  final LocationService _locationService = LocationService();
  final StorageService _storageService = StorageService();
  final PatientService _patientService = PatientService();
  final slider.CarouselSliderController _carouselController = slider.CarouselSliderController();

  List<MyAppointment> _upcomingAppointments = [];
  bool _loadingAppointments = true;
  String? _patientName;
  int _unreadNotificationCount = 0;

  Color get primaryColor => const Color(0xFF8c6239);
  Color get bgColor => const Color(0xfff2f2f2);

  @override
  void initState() {
    super.initState();
    _loadPatientProfile();
    _loadLocationIfNeeded();
    _loadUpcomingAppointment();
    _loadUnreadNotificationCount();

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

  Future<void> _loadPatientProfile() async {
    try {
      final profile = await _patientService.getProfile();
      setState(() {
        _patientName = profile.fullName;
      });
    } catch (e) {
      print('DEBUG: Could not load patient profile: $e');
    }
  }

  Future<void> _loadUnreadNotificationCount() async {
    try {
      final notifications = await _storageService.getLocalNotifications();
      final unreadCount = notifications.where((n) => !n.isRead).length;
      if (mounted) {
        setState(() {
          _unreadNotificationCount = unreadCount;
        });
      }
    } catch (e) {
      print('DEBUG: Could not load notification count: $e');
    }
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
      print('DEBUG: Loading appointments from local storage...');
      final appointments = await _storageService.getAppointments();
      print('DEBUG: Total appointments loaded: ${appointments.length}');
      
      // Just load appointments without adding sample data
      if (appointments.isNotEmpty) {
        print('DEBUG: First appointment hospital: ${appointments.isNotEmpty ? appointments[0].hospitalName : "NONE"}');
        print('DEBUG: Second appointment hospital: ${appointments.length > 1 ? appointments[1].hospitalName : "NONE"}');
        await _processAppointments(appointments);
      } else {
        setState(() {
          _upcomingAppointments = [];
          _loadingAppointments = false;
        });
      }
    } catch (e) {
      print('DEBUG: Could not load appointments: $e');
      print('DEBUG: Error stack trace: ${StackTrace.current}');
      setState(() {
        _loadingAppointments = false;
      });
    }
  }

  Future<void> _processAppointments(List<MyAppointment> appointments) async {
    for (var i = 0; i < appointments.length; i++) {
      print('DEBUG: Appointment $i - ID: ${appointments[i].id}, Date: ${appointments[i].date}, Time: ${appointments[i].time}, Status: ${appointments[i].status}, Doctor: ${appointments[i].doctor.name}');
    }
    
    final upcoming = _sortAppointmentsByProximity(appointments);
    print('DEBUG: Upcoming appointments after filtering: ${upcoming.length}');
    setState(() {
      _upcomingAppointments = upcoming;
      _loadingAppointments = false;
    });
  }

  List<MyAppointment> _sortAppointmentsByProximity(List<MyAppointment> appointments) {
    final now = DateTime.now();
    
    return appointments.where((appointment) {
      final status = appointment.status.toLowerCase();
      final isValidStatus = status == 'confirmed' || status == 'scheduled' || status == 'pending';
      
      if (!isValidStatus) {
        print('DEBUG: Appointment ${appointment.id} filtered - invalid status: $status');
        return false;
      }

      final appointmentTime = appointment.appointmentDateTime;
      if (appointmentTime == null) {
        print('DEBUG: Appointment ${appointment.id} filtered - invalid date/time');
        return false;
      }
      
      final isFuture = appointmentTime.isAfter(now);
      print('DEBUG: Appointment ${appointment.id} date/time: $appointmentTime, Is future: $isFuture');
      return isFuture;
    }).toList()..sort((a, b) {
      final timeA = a.appointmentDateTime;
      final timeB = b.appointmentDateTime;
      
      if (timeA == null && timeB == null) return 0;
      if (timeA == null) return 1;
      if (timeB == null) return -1;
      
      return timeA.compareTo(timeB);
    });
  }

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

  bool _isTomorrowAppointment(String appointmentDate) {
    try {
      final now = DateTime.now();
      final tomorrow = now.add(const Duration(days: 1));
      final dateParts = appointmentDate.split('-');
      if (dateParts.length != 3) return false;

      final year = int.parse(dateParts[0]);
      final month = int.parse(dateParts[1]);
      final day = int.parse(dateParts[2]);

      return year == tomorrow.year && month == tomorrow.month && day == tomorrow.day;
    } catch (e) {
      return false;
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hi, ${_patientName ?? 'Patient'} 👋',
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
                  GestureDetector(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NotificationsScreen(),
                        ),
                      );
                      _loadUnreadNotificationCount();
                    },
                    child: Stack(
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
                        if (_unreadNotificationCount > 0)
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
                              child: Text(
                                _unreadNotificationCount > 99 ? '99+' : '$_unreadNotificationCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  children: [
                    const SizedBox(height: 12),

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
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'New to our Hospital?',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Get your first consultation\nwith a special discount.',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    height: 32,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white, // button bg white
                                        foregroundColor: const Color(0xFF8c6239), // text/icon color
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        minimumSize: const Size(0, 32),
                                        elevation: 0, // optional (remove shadow)
                                      ),
                                      onPressed: () {},
                                      child: const Text('Claim now'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

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

                    const SizedBox(height: 6),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _loadingAppointments
                          ? Center(child: CircularProgressIndicator(color: primaryColor))
                          : _upcomingAppointments.isEmpty
                              ? _buildNoAppointmentCard()
                              : _buildAppointmentsCarousel(),
                    ),

                    const SizedBox(height: 12),

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

            CustomBottomNavigationBar(
              currentIndex: 0,
              onTap: (index) {
                // Handle navigation if needed
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoAppointmentCard() {
    return Container(
      padding: const EdgeInsets.all(16),
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
        ],
      ),
    );
  }

  Widget _buildAppointmentsCarousel() {
    return Column(
      children: [
        slider.CarouselSlider(
          carouselController: _carouselController,
          options: slider.CarouselOptions(
            height: 120,
            viewportFraction: 0.92,
            enlargeCenterPage: true,
            enableInfiniteScroll: false,
            autoPlay: false,
          ),
          items: _upcomingAppointments.map((appointment) {
            return Builder(
              builder: (BuildContext context) {
                return _buildAppointmentCard(appointment);
              },
            );
          }).toList(),
        ),
        if (_upcomingAppointments.length > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back_ios, size: 20, color: primaryColor),
                onPressed: () => _carouselController.previousPage(),
              ),
              SizedBox(width: 20),
              Text(
                '${_upcomingAppointments.length} appointments',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              SizedBox(width: 20),
              IconButton(
                icon: Icon(Icons.arrow_forward_ios, size: 20, color: primaryColor),
                onPressed: () => _carouselController.nextPage(),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildAppointmentCard(MyAppointment appointment) {
    final isToday = _isTodayAppointment(appointment.date);
    final isTomorrow = _isTomorrowAppointment(appointment.date);

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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 70,
              height: 85,
              decoration: BoxDecoration(
                color: isToday ? Colors.green.shade100 : bgColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: isToday ? [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ] : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Token',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: isToday ? Colors.green.shade600 : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${appointment.id.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: isToday ? Colors.green.shade700 : primaryColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isToday ? 'In Progress' : (isTomorrow ? 'Upcoming' : ''),
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: isToday ? Colors.green.shade700 : isTomorrow ? Colors.orange.shade700 : Colors.transparent,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appointment.department?.isNotEmpty == true 
                        ? appointment.department! 
                        : 'Consultation',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    ' ${appointment.doctor.name}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  if (appointment.hospitalName != null) ...[
                    Row(
                      children: [
                        Icon(Icons.local_hospital, size: 12, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            appointment.hospitalName!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                  ],
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 12, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        '${appointment.date} · ${appointment.time}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
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

  Widget _serviceItem(IconData icon, String label) {
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

}