import 'package:flutter/material.dart';
import '../../models/department_models.dart';
import '../../services/department_service.dart';
import '../../services/treatment_service.dart';
import '../../utils/department_icon_mapper.dart';
import 'treatment_list_screen.dart';
import '../../widgets/custom_bottom_navigation_bar.dart';

class DepartmentListScreen extends StatefulWidget {
  const DepartmentListScreen({super.key});

  @override
  State<DepartmentListScreen> createState() => _DepartmentListScreenState();
}

class _DepartmentListScreenState extends State<DepartmentListScreen> {
  final DepartmentService _departmentService = DepartmentService();
  final TreatmentService _treatmentService = TreatmentService();
  List<Department> _departments = [];
  Map<int, int> _departmentTreatmentCounts = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDepartments();
  }

  Future<void> _loadDepartments() async {
    try {
      final departments = await _departmentService.getDepartments();
      final treatments = await _treatmentService.getTreatments();
      
      // Calculate treatment counts per department and debug treatment data
      Map<int, int> treatmentCounts = {};
      print('DEBUG: Analyzing ALL treatments for department linking:');
      
      for (var i = 0; i < treatments.length; i++) {
        final treatment = treatments[i];
        print('DEBUG: Treatment $i:');
        print('  - Name: "${treatment.name}"');
        print('  - departmentId: ${treatment.departmentId} (${treatment.departmentId.runtimeType})');
        print('  - departmentName: "${treatment.departmentName}"');
        print('  - isActive: ${treatment.isActive}');
        print('  - Full JSON: ${treatment.toJson()}');
        
        if (treatment.isActive && treatment.departmentId != null) {
          treatmentCounts[treatment.departmentId!] = 
              (treatmentCounts[treatment.departmentId!] ?? 0) + 1;
          print('  - ✅ Added to count for department ${treatment.departmentId}');
        } else {
          print('  - ❌ SKIPPED (inactive or null departmentId)');
        }
      }
      
      print('DEBUG: Final treatment counts: $treatmentCounts');
      
      // Debug logging to identify issue
      print('DEBUG: Total departments loaded: ${departments.length}');
      print('DEBUG: Total treatments loaded: ${treatments.length}');
      print('DEBUG: Treatment counts: $treatmentCounts');
      
      setState(() {
        _departments = departments.where((d) => d.isActive).toList();
        _departmentTreatmentCounts = treatmentCounts;
        _isLoading = false;
        _error = null;
      });
      
      print('DEBUG: Active departments after filtering: ${_departments.length}');
      for (var dept in _departments) {
        final count = _departmentTreatmentCounts[dept.id] ?? 0;
        print('DEBUG: Active department: ${dept.name} (ID: ${dept.id}) - Treatments: $count');
      }
      
    } catch (e) {
      print('DEBUG: Error loading departments: $e');
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Color get primaryColor => const Color(0xFF8c6239);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Department'),
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
      return Center(child: CircularProgressIndicator(color: primaryColor));
    }

    if (_error != null) {
      return _buildErrorView();
    }

    if (_departments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.category_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No departments available',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
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
          Text(
            'Choose a Department',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select the department for your medical needs',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.0,
              ),
              itemCount: _departments.length,
              itemBuilder: (context, index) {
                final department = _departments[index];
                return _buildDepartmentCard(department);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDepartmentCard(Department department) {
    final treatmentCount = _departmentTreatmentCounts[department.id] ?? 0;
    final isLoadingCounts = _departmentTreatmentCounts.isEmpty;
    
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TreatmentListScreen(
              department: department,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: primaryColor.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    DepartmentIconMapper.getIconForDepartment(department.name),
                    size: 35,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    department.name,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            // Treatment count badge in top right corner
            if (!isLoadingCounts && treatmentCount > 0)
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
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    '$treatmentCount',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            // Loading indicator for counts
            if (isLoadingCounts)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
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
              onPressed: _loadDepartments,
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