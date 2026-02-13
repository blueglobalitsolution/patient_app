import 'package:flutter/material.dart';
import '../../models/department_models.dart';
import '../../models/treatment_models.dart';
import '../../models/appointment_models.dart' hide Doctor;
import '../../models/doctor_models.dart';
import '../../services/appointment_service.dart';
import '../../services/doctor_service.dart';
import '../dashboard/book_appointment_screen.dart';
import '../../widgets/custom_bottom_navigation_bar.dart';
import '../../widgets/custom_bottom_navigation_bar.dart';

class DoctorByTreatmentScreen extends StatefulWidget {
  final Treatment treatment;
  final Department department;

  const DoctorByTreatmentScreen({
    super.key,
    required this.treatment,
    required this.department,
  });

  @override
  State<DoctorByTreatmentScreen> createState() => _DoctorByTreatmentScreenState();
}

class _DoctorByTreatmentScreenState extends State<DoctorByTreatmentScreen> {
  final AppointmentService _appointmentService = AppointmentService();
  final DoctorService _doctorService = DoctorService();
  List<Doctor> _doctors = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDoctors();
  }

  Future<void> _loadDoctors() async {
    try {
      print('DEBUG: Loading doctors for treatment: ${widget.treatment.name} (ID: ${widget.treatment.id})');
      print('DEBUG: Department: ${widget.department.name} (ID: ${widget.department.id})');

      // First try to get doctors by department (more reliable)
      final doctors = await _doctorService.getDoctorsByDepartment(widget.department.id);
      print('DEBUG: Found ${doctors.length} doctors in department');

      setState(() {
        _doctors = doctors;
        _isLoading = false;
        _error = null;
      });

      print('DEBUG: Displaying ${doctors.length} doctors for treatment ${widget.treatment.name}');
    } catch (e) {
      print('DEBUG: Error loading doctors: $e');
      
      // Fallback to appointment service if doctor service fails
      try {
        final hospitalId = 1;
        final appointmentDoctors = await _appointmentService.fetchDoctors(
          hospitalId: hospitalId,
          department: widget.department.name,
        );
        
        // Convert appointment doctors to doctor model doctors
        final doctors = appointmentDoctors.map((doc) => Doctor(
          id: doc.id,
          name: doc.name,
          specialization: doc.specialization,
          hospitalName: doc.hospitalName,
        )).toList();
        
        setState(() {
          _doctors = doctors;
          _isLoading = false;
          _error = null;
        });
      } catch (fallbackError) {
        setState(() {
          _isLoading = false;
          _error = 'Failed to load doctors: $fallbackError';
        });
      }
    }
  }

  Color get primaryColor => const Color(0xFF8c6239);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Doctors for ${widget.treatment.name}'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _buildBody(),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: 2, // + button position (booking flow)
        onTap: (index) {
          // Handle navigation if needed
        },
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: primaryColor));
    }

    if (_error != null) {
      return _buildErrorView();
    }

    if (_doctors.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_search,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No doctors available',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'for ${widget.treatment.name}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Treatment info card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: primaryColor.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.medication,
                      color: primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.treatment.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
                if (widget.treatment.description != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    widget.treatment.description!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.local_hospital,
                      color: primaryColor,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.department.name,
                      style: TextStyle(
                        fontSize: 14,
                        color: primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Available Doctors',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_doctors.length} doctor(s) available for ${widget.treatment.name}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: _doctors.length,
              itemBuilder: (context, index) {
                final doctor = _doctors[index];
                return _buildDoctorCard(doctor);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorCard(Doctor doctor) {
    return InkWell(
      onTap: () {
        // Navigate to existing booking screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BookAppointmentScreen(doctorId: doctor.id),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Doctor image placeholder
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person,
                  size: 30,
                  color: Colors.grey[400],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doctor.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    if (doctor.specialization != null && doctor.specialization!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        doctor.specialization!,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                    if (doctor.hospitalName != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        doctor.hospitalName!,
                        style: TextStyle(
                          fontSize: 12,
                          color: primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Book',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadDoctors,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}