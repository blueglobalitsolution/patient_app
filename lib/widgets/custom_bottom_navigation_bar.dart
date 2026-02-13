import 'package:flutter/material.dart';
import '../screens/booking/department_list_screen.dart';
import '../screens/dashboard/hospital_list_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/dashboard/patient_dashboard.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  Color get primaryColor => const Color(0xFF8c6239);

  void _navigateToScreen(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 6,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _bottomItem(
            icon: Icons.home,
            label: 'Home',
            active: currentIndex == 0,
            onTap: () {
              if (currentIndex != 0) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const PatientDashboard()),
                  (route) => false,
                );
              }
            },
          ),
          _bottomItem(
            icon: Icons.local_hospital,
            label: 'Hospital',
            active: currentIndex == 1,
            onTap: () => _navigateToScreen(context, const HospitalListScreen()),
          ),
          // + Button for booking
          InkWell(
            onTap: () => _navigateToScreen(context, const DepartmentListScreen()),
            borderRadius: BorderRadius.circular(30),
            child: Container(
              decoration: BoxDecoration(
                color: primaryColor,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(10),
              child: const Icon(Icons.add, color: Colors.white),
            ),
          ),
          _bottomItem(
            icon: Icons.history,
            label: 'History',
            active: currentIndex == 3,
            onTap: () {
              // TODO: Navigate to History screen when implemented
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('History coming soon!')),
              );
            },
          ),
          _bottomItem(
            icon: Icons.person,
            label: 'Profile',
            active: currentIndex == 4,
            onTap: () => _navigateToScreen(context, const ProfileScreen()),
          ),
        ],
      ),
    );
  }

  Widget _bottomItem({
    required IconData icon,
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 24,
            color: active ? primaryColor : Colors.grey[600],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: active ? primaryColor : Colors.grey[600],
              fontWeight: active ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}