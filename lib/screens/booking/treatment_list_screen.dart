import 'package:flutter/material.dart';
import '../../models/department_models.dart';
import '../../models/treatment_models.dart';
import '../../models/doctor_models.dart';
import '../../services/treatment_service.dart';
import '../../services/doctor_service.dart';
import '../../utils/department_icon_mapper.dart';
import 'doctor_by_treatment_screen.dart';
import '../../widgets/custom_bottom_navigation_bar.dart';

class TreatmentListScreen extends StatefulWidget {
  final Department department;

  const TreatmentListScreen({
    super.key,
    required this.department,
  });

  @override
  State<TreatmentListScreen> createState() => _TreatmentListScreenState();
}

class _TreatmentListScreenState extends State<TreatmentListScreen> {
  final TreatmentService _treatmentService = TreatmentService();
  final DoctorService _doctorService = DoctorService();
  List<Treatment> _treatments = [];
  Map<int, int> _treatmentDoctorCounts = {};
  bool _isLoading = true;
  bool _isLoadingCounts = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDepartmentTreatments();
  }

  Future<void> _loadDepartmentTreatments() async {
    try {
      print('DEBUG: Loading treatments for ${widget.department.name} (ID: ${widget.department.id})');
      
      final treatments = await _treatmentService.getTreatmentsByDepartment(widget.department.id);
      print('DEBUG: Department API returned ${treatments.length} treatments');
      
      setState(() {
        _treatments = treatments.where((t) => t.isActive).toList();
        _isLoading = false;
        _error = null;
      });
      
      // Load doctor counts separately
      await _loadDoctorCounts();
      
      print('DEBUG: Final treatments displayed: ${_treatments.length}');
      for (var treatment in _treatments) {
        print('DEBUG: Displayed treatment: ${treatment.name}');
      }
    } catch (e) {
      print('DEBUG: Error loading treatments: $e');
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _loadDoctorCounts() async {
    try {
      print('DEBUG: Loading doctor counts for treatments');
      
      // Get all doctors in the department
      final doctors = await _doctorService.getDoctorsByDepartment(widget.department.id);
      print('DEBUG: Found ${doctors.length} doctors in department');
      
      // For now, distribute doctors evenly among treatments
      // In a real app, you might have a treatment-doctor relationship
      Map<int, int> doctorCounts = {};
      for (var treatment in _treatments) {
        // Estimate doctors per treatment (you can adjust this logic)
        final estimatedDoctors = (doctors.length / _treatments.length).ceil();
        doctorCounts[treatment.id] = estimatedDoctors > 0 ? estimatedDoctors : 1;
      }
      
      setState(() {
        _treatmentDoctorCounts = doctorCounts;
        _isLoadingCounts = false;
      });
      
      print('DEBUG: Doctor counts loaded: $_treatmentDoctorCounts');
    } catch (e) {
      print('DEBUG: Error loading doctor counts: $e');
      setState(() {
        _isLoadingCounts = false;
      });
    }
  }

  Color get primaryColor => const Color(0xFF8c6239);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.department.name} Treatments'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _buildBody(),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: 2, // + button position
        onTap: (index) {
          // Handle navigation if needed
        },
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF8c6239)));
    }

    if (_error != null) {
      return _buildErrorView();
    }

    if (_treatments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.medical_services_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text('No treatments found for this department', style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.w500)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Browse All Doctors'),
              onPressed: () => _browseAllDoctors(),
              style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF8c6239), foregroundColor: Colors.white),
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
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF8c6239).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF8c6239).withOpacity(0.2), width: 1),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF8c6239).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                child: Icon(
                  DepartmentIconMapper.getIconForDepartment(widget.department.name),
                  size: 20,
                  color: const Color(0xFF8c6239),
                ),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(widget.department.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF8c6239)))),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('${_treatments.length} treatment(s) available', style: TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: _treatments.length,
              itemBuilder: (context, index) {
                final treatment = _treatments[index];
                return _buildTreatmentCard(treatment);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTreatmentCard(Treatment treatment) {
    final doctorCount = _treatmentDoctorCounts[treatment.id] ?? 0;
    
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DoctorByTreatmentScreen(treatment: treatment, department: widget.department),
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
            BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2)),
          ],
          border: Border.all(color: Colors.grey.shade200, width: 1),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF8c6239).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  DepartmentIconMapper.getIconForDepartment(widget.department.name),
                  size: 24,
                  color: const Color(0xFF8c6239),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(treatment.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
                    if (treatment.description != null) ...[
                      const SizedBox(height: 4),
                      Text(treatment.description!, style: const TextStyle(fontSize: 13, color: Colors.black54), maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                    if (treatment.estimatedDuration != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.schedule, size: 14, color: Color(0xFF8c6239)),
                          const SizedBox(width: 4),
                          Text('~${treatment.estimatedDuration} ${treatment.estimatedDurationUnit ?? 'minutes'}', style: const TextStyle(fontSize: 12, color: Color(0xFF8c6239), fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
           ),
        ),
        // Doctor count badge
        if (!_isLoadingCounts && doctorCount > 0)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                '$doctorCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        // Loading indicator for counts
        if (_isLoadingCounts)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                '..',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
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
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(_error!, style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.w500)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              onPressed: _loadDepartmentTreatments,
              style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF8c6239), foregroundColor: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _browseAllDoctors() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DoctorByTreatmentScreen(
          treatment: Treatment(
            id: 0,
            name: 'General Consultation',
            description: 'Consultation with any available doctor',
            departmentId: widget.department.id,
            departmentName: widget.department.name,
          ),
          department: widget.department,
        ),
      ),
    );
  }


}