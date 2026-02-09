import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  final NotificationService _notificationService = NotificationService();
  final StorageService _storageService = StorageService();

  bool _pushNotificationsEnabled = true;
  bool _appointmentRemindersEnabled = true;
  bool _medicationRemindersEnabled = true;
  bool _promotionNotificationsEnabled = false;
  int _reminderTime = 1;

  Color get primaryColor => const Color(0xFF8c6239);
  Color get bgColor => const Color(0xfff2f2f2);

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _pushNotificationsEnabled =
          prefs.getBool('push_notifications_enabled') ?? true;
      _appointmentRemindersEnabled =
          prefs.getBool('appointment_reminders_enabled') ?? true;
      _medicationRemindersEnabled =
          prefs.getBool('medication_reminders_enabled') ?? true;
      _promotionNotificationsEnabled =
          prefs.getBool('promotion_notifications_enabled') ?? false;
      _reminderTime = prefs.getInt('reminder_time_hours') ?? 1;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('push_notifications_enabled', _pushNotificationsEnabled);
    await prefs.setBool(
        'appointment_reminders_enabled', _appointmentRemindersEnabled);
    await prefs.setBool(
        'medication_reminders_enabled', _medicationRemindersEnabled);
    await prefs.setBool(
        'promotion_notifications_enabled', _promotionNotificationsEnabled);
    await prefs.setInt('reminder_time_hours', _reminderTime);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings saved successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: const Text(
          'Notification Settings',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _saveSettings,
            child: const Text(
              'Save',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('General'),
            const SizedBox(height: 12),
            _buildSwitchTile(
              title: 'Push Notifications',
              subtitle: 'Receive notifications from the hospital',
              value: _pushNotificationsEnabled,
              onChanged: (value) {
                setState(() {
                  _pushNotificationsEnabled = value;
                });
              },
              icon: Icons.notifications_active,
            ),
            const SizedBox(height: 24),

            _buildSectionHeader('Appointment Reminders'),
            const SizedBox(height: 12),
            _buildSwitchTile(
              title: 'Appointment Reminders',
              subtitle: 'Get reminded before your appointments',
              value: _appointmentRemindersEnabled,
              onChanged: (value) {
                setState(() {
                  _appointmentRemindersEnabled = value;
                });
              },
              icon: Icons.calendar_month,
            ),
            if (_appointmentRemindersEnabled) ...[
              const SizedBox(height: 12),
              _buildReminderTimeSelector(),
            ],
            const SizedBox(height: 24),

            _buildSectionHeader('Health Reminders'),
            const SizedBox(height: 12),
            _buildSwitchTile(
              title: 'Medication Reminders',
              subtitle: 'Reminders for your medications',
              value: _medicationRemindersEnabled,
              onChanged: (value) {
                setState(() {
                  _medicationRemindersEnabled = value;
                });
              },
              icon: Icons.medication,
            ),
            const SizedBox(height: 24),

            _buildSectionHeader('Other'),
            const SizedBox(height: 12),
            _buildSwitchTile(
              title: 'Promotions & Offers',
              subtitle: 'Receive special offers and health tips',
              value: _promotionNotificationsEnabled,
              onChanged: (value) {
                setState(() {
                  _promotionNotificationsEnabled = value;
                });
              },
              icon: Icons.local_offer,
            ),
            const SizedBox(height: 24),

            _buildSectionHeader('Test'),
            const SizedBox(height: 12),
            _buildTestButton(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildTestButton() {
    return ElevatedButton.icon(
      onPressed: () async {
        try {
          await _notificationService.showLocalNotification(
            id: DateTime.now().millisecondsSinceEpoch,
            title: 'Test Notification',
            body: 'This is a test notification from your Patient App',
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Test notification sent! Check your notification shade.'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to send test notification: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
      icon: const Icon(Icons.notifications),
      label: const Text('Send Test Notification'),
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: primaryColor,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: primaryColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildReminderTimeSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.alarm, color: primaryColor, size: 20),
              const SizedBox(width: 12),
              const Text(
                'Reminder Time',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: [
              _buildTimeChip(1, '1 hour'),
              _buildTimeChip(2, '2 hours'),
              _buildTimeChip(4, '4 hours'),
              _buildTimeChip(8, '8 hours'),
              _buildTimeChip(24, '1 day'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeChip(int hours, String label) {
    final isSelected = _reminderTime == hours;
    return GestureDetector(
      onTap: () {
        setState(() {
          _reminderTime = hours;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}