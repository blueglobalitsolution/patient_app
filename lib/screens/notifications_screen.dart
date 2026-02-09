import 'package:flutter/material.dart';
import '../models/appointment_models.dart';
import '../services/storage_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _storageService = StorageService();
  List<LocalNotification> _notifications = [];
  bool _loading = true;

  Color get primaryColor => const Color(0xFF8c6239);
  Color get bgColor => const Color(0xfff2f2f2);

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _loading = true;
    });
    try {
      final notifications = await _storageService.getLocalNotifications();
      setState(() {
        _notifications = notifications;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load notifications: $e')),
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

  Future<void> _markAsRead(LocalNotification notification) async {
    if (notification.isRead) return;

    try {
      await _storageService.markLocalNotificationAsRead(notification.id);

      setState(() {
        final index = _notifications.indexWhere((n) => n.id == notification.id);
        if (index != -1) {
          _notifications[index] = LocalNotification(
            id: notification.id,
            title: notification.title,
            message: notification.message,
            isRead: true,
            createdAt: notification.createdAt,
            type: notification.type,
            appointmentId: notification.appointmentId,
          );
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to mark notification as read: $e')),
        );
      }
    }
  }

  void _showNotificationBottomSheet(LocalNotification notification) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.4,
        minChildSize: 0.3,
        maxChildSize: 0.8,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: _getNotificationColor(notification.type).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Icon(
                              _getNotificationIcon(notification.type),
                              color: _getNotificationColor(notification.type),
                              size: 24,
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  notification.title,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[800],
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  _formatDate(notification.createdAt.toIso8601String()),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      Text(
                        notification.message,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey[700],
                          height: 1.5,
                        ),
                      ),
                      SizedBox(height: 24),
                      if (!notification.isRead)
                        ElevatedButton(
                          onPressed: () {
                            _markAsRead(notification);
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            minimumSize: Size(double.infinity, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text('Mark as Read'),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: const Text('Notifications', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_notifications.any((n) => !n.isRead))
            IconButton(
              icon: const Icon(Icons.mark_email_read, color: Colors.white),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Mark All as Read'),
                    content: const Text('Mark all unread notifications as read?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _markAllAsRead();
                        },
                        child: const Text('Yes'),
                      ),
                    ],
                  ),
                );
              },
            ),
          if (_notifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep, color: Colors.white),
              onPressed: _clearAllNotifications,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_none,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No notifications',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final notification = _notifications[index];
                      return _NotificationCard(
                        notification: notification,
                        onTap: () => _showNotificationBottomSheet(notification),
                      );
                    },
                  ),
                ),
    );
  }

  Future<void> _markAllAsRead() async {
    try {
      await _storageService.markAllLocalNotificationsAsRead();
    } catch (e) {
      print('Failed to mark all notifications as read: $e');
    }
    _loadNotifications();
  }

  Future<void> _clearAllNotifications() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All'),
        content: const Text('Clear all notifications?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _storageService.clearAllLocalNotifications();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All notifications cleared')),
        );
      }
      _loadNotifications();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to clear notifications: $e')),
        );
      }
    }
  }
  }

  Color _getNotificationColor(String? type) {
    switch (type?.toLowerCase()) {
      case 'appointment':
      case 'booking':
        return const Color(0xFF4CAF50);
      case 'cancel':
      case 'cancelled':
      case 'reminder':
        return const Color(0xFFF44336);
      case 'medical':
        return const Color(0xFF2196F3);
      default:
        return const Color(0xFF8c6239);
    }
  }

  IconData _getNotificationIcon(String? type) {
    switch (type?.toLowerCase()) {
      case 'appointment':
      case 'booking':
        return Icons.calendar_month;
      case 'cancel':
      case 'cancelled':
        return Icons.cancel;
      case 'reminder':
        return Icons.alarm;
      case 'medical':
        return Icons.medical_services;
      default:
        return Icons.notifications;
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 7) {
        return '${date.day}/${date.month}/${date.year}';
      } else if (difference.inDays > 0) {
        return '${difference.inDays} days ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} hours ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} minutes ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return dateStr;
    }
  }

  class _NotificationCard extends StatelessWidget {
    final LocalNotification notification;
    final VoidCallback onTap;

    const _NotificationCard({
      required this.notification,
      required this.onTap,
    });

    Color get primaryColor => const Color(0xFF8c6239);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: notification.isRead ? Colors.white : Colors.blue[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: notification.isRead ? Colors.transparent : primaryColor.withOpacity(0.3),
            width: notification.isRead ? 0 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: _getNotificationColor(notification.type).withOpacity(0.15),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Icon(
                _getNotificationIcon(notification.type),
                color: _getNotificationColor(notification.type),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!notification.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: primaryColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.message,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                   Text(
                     _formatDate(notification.createdAt.toIso8601String()),
                     style: TextStyle(
                       fontSize: 11,
                       color: Colors.grey[500],
                     ),
                   ),

                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
