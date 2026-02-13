import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:contact_manager_app/services/hospital_service.dart';
import 'package:contact_manager_app/services/doctor_service.dart';
import 'package:contact_manager_app/services/department_service.dart';
import 'package:contact_manager_app/models/hospital_models.dart';
import 'package:contact_manager_app/models/doctor_models.dart';
import 'package:contact_manager_app/models/department_models.dart';
import 'book_appointment_screen.dart';
import '../booking/treatment_list_screen.dart';
import 'hospital_list_screen.dart';
import '../profile_screen.dart';
import '../../widgets/custom_bottom_navigation_bar.dart';
import '../../utils/department_icon_mapper.dart';

class HospitalDetailsScreen extends StatefulWidget {
  final int hospitalId;
  final String? hospitalName;

  const HospitalDetailsScreen({
    super.key,
    required this.hospitalId,
    this.hospitalName,
  });

  @override
  State<HospitalDetailsScreen> createState() => _HospitalDetailsScreenState();
}

class _HospitalDetailsScreenState extends State<HospitalDetailsScreen>
    with TickerProviderStateMixin {
  final HospitalService _hospitalService = HospitalService();
  final DoctorService _doctorService = DoctorService();
  final DepartmentService _departmentService = DepartmentService();

  ApprovedHospital? _hospital;
  List<Doctor> _doctors = [];
  List<Department> _departments = [];
  late final TabController _tabController;
  bool _loading = true;
  bool _loadingDepartments = false;
  String _errorMessage = '';

  Color get primaryColor => const Color(0xFF8c6239);
  Color get bgColor => const Color(0xfff2f2f2);

@override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _errorMessage = '';
    });

    try {
      final hospital = await _hospitalService.getHospitalById(widget.hospitalId);
      if (hospital == null) {
        throw Exception('Hospital not found');
      }
      _hospital = hospital;

      final doctors = await _doctorService.getDoctorsByHospital(widget.hospitalId);
      _doctors = doctors;

      try {
        setState(() {
          _loadingDepartments = true;
        });
        final departments = await _departmentService.getDepartmentsByHospital(widget.hospitalId);
        _departments = departments;
        setState(() {
          _loadingDepartments = false;
        });
      } catch (e) {
        print('Error loading departments: $e');
        setState(() {
          _departments = [];
          _loadingDepartments = false;
        });
      }
    } catch (e) {
      _errorMessage = e.toString();
    }

    setState(() {
      _loading = false;
    });
  }

void _onDoctorTap(Doctor doctor) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookAppointmentScreen(
          doctorId: doctor.id,
          hospitalId: widget.hospitalId,
          hospitalName: widget.hospitalName ?? _hospital?.name,
        ),
      ),
    );
  }

@override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            Expanded(
              child: _loading
                  ? Center(child: CircularProgressIndicator(color: primaryColor))
                  : _errorMessage.isNotEmpty
                      ? _buildErrorView()
                      : SingleChildScrollView(
                          child: Column(
                            children: [
                              _buildHospitalInfo(),
                              const SizedBox(height: 20),
                              _buildTabBarView(),
                              const SizedBox(height: 80),
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: 0,
        onTap: (index) {
          // Handle navigation if needed
          switch (index) {
            case 0:
              // Home - current screen
              break;
            case 1:
              // Hospital List
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const HospitalListScreen(),
                ),
              );
              break;
            case 2:
              // Departments - could navigate to department list screen
              break;
            case 3:
              // Profile
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const ProfileScreen(),
                ),
              );
              break;
          }
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back, color: Color(0xFF8c6239)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Hospital Details',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(width: 12),
          if (_hospital != null && _hospital!.pNumber != null && _hospital!.pNumber!.isNotEmpty)
            GestureDetector(
              onTap: () => _makePhoneCall(_hospital!.pNumber!),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.call, color: Color(0xFF8c6239)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              'Error: $_errorMessage',
              style: const TextStyle(fontSize: 14, color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

Widget _buildHospitalInfo() {
    if (_hospital == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Column 1: Logo/Image (Left side - fixed width)
          Container(
            width: 100,
            child: Column(
              children: [
                if (_hospital!.logo != null && _hospital!.logo!.isNotEmpty)
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(_hospital!.logo!, fit: BoxFit.cover),
                    ),
                  )
                else
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.local_hospital, color: primaryColor, size: 40),
                  ),
              ],
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Column 2: Hospital Name + Address + Call Button (Right side - takes remaining space)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hospital Name
                Text(
                  _hospital!.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Address
                Text(
                  _buildAddress(),
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                

              ],
            ),
          ),
        ],
      ),
    );
  }

  String _buildAddress() {
    final parts = <String>[];
    if (_hospital!.address != null && _hospital!.address!.isNotEmpty) {
      parts.add(_hospital!.address!);
    }
    if (_hospital!.city != null && _hospital!.city!.isNotEmpty) {
      parts.add(_hospital!.city!);
    }
    return parts.isEmpty ? 'Not available' : parts.join(', ');
  }

Widget _buildTabBarView() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xfff2f2f2), width: 1),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: primaryColor,
              labelColor: primaryColor,
              unselectedLabelColor: Colors.grey[600],
              labelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              tabs: [
                Tab(
                  icon: Icon(Icons.people, size: 20),
                  text: 'Doctors (${_doctors.length})',
                ),
                Tab(
                  icon: Icon(Icons.medical_services, size: 20),
                  text: 'Departments (${_departments.length})',
                ),
              ],
            ),
          ),
          SizedBox(
            height: 400,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDoctorsTab(),
                _buildDepartmentsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorsTab() {
    if (_doctors.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              'No doctors available',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _doctors.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final doctor = _doctors[index];
        return _DoctorCard(
          doctor: doctor,
          onTap: () => _onDoctorTap(doctor),
        );
      },
    );
  }

  Widget _buildDepartmentsTab() {
    if (_loadingDepartments) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: primaryColor),
            const SizedBox(height: 16),
            Text(
              'Loading departments...',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    if (_departments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.category_outlined, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              'No departments available',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'This hospital has no active departments',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _departments.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final department = _departments[index];
        return _DepartmentCard(
          department: department,
          onTap: () => _onDepartmentTap(department),
        );
      },
    );
  }

  void _onDepartmentTap(Department department) {
    // Navigate to treatment list for this department
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TreatmentListScreen(department: department),
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not launch phone dialer'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xfff2f2f2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF8c6239), size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
}
}

class _DoctorCard extends StatelessWidget {
  final Doctor doctor;
  final VoidCallback onTap;

  const _DoctorCard({
    required this.doctor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xfff2f2f2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: doctor.profileImage != null && doctor.profileImage!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(doctor.profileImage!, fit: BoxFit.cover),
                    )
                  : const Icon(Icons.person, color: Colors.grey, size: 26),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doctor.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    doctor.specialization ?? 'General',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  if (doctor.departmentName != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      doctor.departmentName!,
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF8c6239),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Book',
                style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ],
         ),
      ),
    );
  }
}

class _DepartmentCard extends StatelessWidget {
  final Department department;
  final VoidCallback onTap;

  const _DepartmentCard({
    required this.department,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF8c6239);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xfff2f2f2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                DepartmentIconMapper.getIconForDepartment(department.name),
                color: primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    department.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  if (department.description != null && department.description!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      department.description!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'View',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}