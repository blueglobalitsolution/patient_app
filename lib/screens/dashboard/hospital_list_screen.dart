import 'package:flutter/material.dart';
import 'package:contact_manager_app/services/hospital_service.dart';
import 'package:contact_manager_app/models/hospital_models.dart';
import 'hospital_details_screen.dart';
import 'patient_dashboard.dart';
import 'search_screen.dart';
import 'book_appointment_screen.dart';
import '../profile_screen.dart';
import '../../widgets/custom_bottom_navigation_bar.dart';

class HospitalListScreen extends StatefulWidget {
  const HospitalListScreen({super.key});

  @override
  State<HospitalListScreen> createState() => _HospitalListScreenState();
}

class _HospitalListScreenState extends State<HospitalListScreen> {
  final HospitalService _hospitalService = HospitalService();

  List<ApprovedHospital> _hospitals = [];
  bool _loading = true;
  String _errorMessage = '';

  Color get primaryColor => const Color(0xFF8c6239);
  Color get bgColor => const Color(0xfff2f2f2);

  @override
  void initState() {
    super.initState();
    _loadHospitals();
  }

  Future<void> _loadHospitals() async {
    setState(() {
      _loading = true;
      _errorMessage = '';
    });

    try {
      final hospitals = await _hospitalService.getApprovedHospitals();
      setState(() {
        _hospitals = hospitals;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _loading = false;
      });
    }
  }

  void _onHospitalTap(ApprovedHospital hospital) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HospitalDetailsScreen(
          hospitalId: hospital.id,
          hospitalName: hospital.name,
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
            Expanded(
              child: _loading
                  ? Center(child: CircularProgressIndicator(color: primaryColor))
                  : _errorMessage.isNotEmpty
                      ? _buildErrorView()
                      : _buildHospitalList(),
            ),
        ],
      ),
      ),
    );
  }

  Widget _bottomNavigation() {
    return Container(
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
            icon: Icons.local_hospital,
            label: 'Hospital',
            active: true,
            onTap: () {},
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
              'Hospitals',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
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
              onPressed: _loadHospitals,
              style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHospitalList() {
    if (_hospitals.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.local_hospital_outlined, size: 64, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text(
                'No hospitals available',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadHospitals,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _hospitals.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final hospital = _hospitals[index];
          return _HospitalCard(
            hospital: hospital,
            onTap: () => _onHospitalTap(hospital),
          );
        },
      ),
    );
  }
}

class _HospitalCard extends StatelessWidget {
  final ApprovedHospital hospital;
  final VoidCallback onTap;

  const _HospitalCard({
    required this.hospital,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF8c6239);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
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
          if (hospital.logo != null && hospital.logo!.isNotEmpty)
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xfff2f2f2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(hospital.logo!, fit: BoxFit.cover),
              ),
            )
          else
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xfff2f2f2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.local_hospital, color: Color(0xFF8c6239), size: 32),
            ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hospital.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                if (hospital.city != null)
                  Text(
                    hospital.city!,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                if (hospital.address != null && hospital.address!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    hospital.address!,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (hospital.totalDoctors != null || hospital.totalDepartments != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (hospital.totalDoctors != null) ...[
                        Icon(Icons.people, size: 14, color: primaryColor),
                        const SizedBox(width: 4),
                        Text(
                          '${hospital.totalDoctors} doctors',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                        ),
                      ],
                      if (hospital.totalDoctors != null && hospital.totalDepartments != null) ...[
                        const SizedBox(width: 8),
                        const Text('·', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        const SizedBox(width: 8),
                      ],
                      if (hospital.totalDepartments != null) ...[
                        Icon(Icons.medical_services, size: 14, color: primaryColor),
                        const SizedBox(width: 4),
                        Text(
                          '${hospital.totalDepartments} depts',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'View',
              style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      ),
    );
  }
}
