import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/appointment_models.dart';
import '../../models/doctor_models.dart' as dm;
import '../../services/appointment_service.dart';
import '../../services/storage_service.dart';
import '../../services/notification_service.dart';
import '../../services/hospital_service.dart';
import 'patient_dashboard.dart';
import 'hospital_list_screen.dart';
import 'booking_confirmation_screen.dart';

class BookAppointmentScreen extends StatefulWidget {
  final int? doctorId;
  final int? hospitalId;
  final String? hospitalName;

  const BookAppointmentScreen({super.key, this.doctorId, this.hospitalId, this.hospitalName});

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  final _service = AppointmentService();
  final _hospitalService = HospitalService();
  final _departmentController = TextEditingController(text: 'Cardiology');
  final _reasonController = TextEditingController(text: 'Consultation');
  late int _hospitalId;
  String? _hospitalName;
  bool _loadingHospital = false;

  bool _loadingDoctors = false;
  bool _loadingSlots = false;
  bool _booking = false;
  List<Doctor> _doctors = [];
  dynamic _selectedDoctor;
  List<SlotDay> _days = [];
  SlotDay? _selectedDay;
  DateTime? _selectedDate;
  Slot? _selectedSlot;

  Color get primaryColor => const Color(0xFF8c6239);
  Color get bgColor => const Color(0xfff2f2f2);

  @override
  void initState() {
    super.initState();
    _hospitalId = widget.hospitalId ?? 1;
    _loadHospitalName();
    
    if (widget.doctorId != null) {
      _loadDoctorSlots(widget.doctorId!);
    } else {
      _loadDoctors();
    }
  }

  Future<void> _loadHospitalName() async {
    setState(() {
      _loadingHospital = true;
    });
    
    try {
      final hospital = await _hospitalService.getHospitalById(_hospitalId);
      setState(() {
        _hospitalName = hospital?.name ?? widget.hospitalName ?? 'Hospital';
        _loadingHospital = false;
      });
    } catch (e) {
      setState(() {
        _hospitalName = widget.hospitalName ?? 'Hospital';
        _loadingHospital = false;
      });
    }
  }

  /// Validates that the selected doctor belongs to the current hospital
  bool _validateDoctorHospitalAssociation(dynamic doctor) {
    // For DoctorDetails model, we don't have hospitalId field
    if (doctor is DoctorDetails) {
      // Validate by comparing hospital name if available
      if (doctor.hospitalName != null && _hospitalName != null) {
        final matches = doctor.hospitalName!.toLowerCase() == _hospitalName!.toLowerCase();
        if (!matches) {
          print('WARNING: Doctor hospital name "${doctor.hospitalName}" != selected hospital name "$_hospitalName"');
        }
        return matches;
      }
      return true; // Can't validate without hospitalId
    }
    
    // For Doctor model, validate by hospitalId
    if (doctor is dm.Doctor) {
      final doctorHospitalId = doctor.hospitalId;
      if (doctorHospitalId != null) {
        final isValid = doctorHospitalId == _hospitalId;
        if (!isValid) {
          print('ERROR: Doctor hospital ID ($doctorHospitalId) != selected hospital ID ($_hospitalId)');
        }
        return isValid;
      }
    }
    
    return true; // Can't validate without hospitalId
  }

  /// Gets consistent hospital name with proper fallback hierarchy
  String _getConsistentHospitalName() {
    // Priority 1: Hospital API name (most reliable)
    if (_hospitalName != null && _hospitalName!.isNotEmpty) {
      return _hospitalName!;
    }
    
    // Priority 2: Widget parameter (passed from previous screen)
    if (widget.hospitalName != null && widget.hospitalName!.isNotEmpty) {
      return widget.hospitalName!;
    }
    
    // Priority 3: Selected doctor's hospital (only if validated)
    if (_selectedDoctor != null && _validateDoctorHospitalAssociation(_selectedDoctor)) {
      final doctor = _selectedDoctor is DoctorDetails 
          ? _selectedDoctor 
          : _selectedDoctor as dm.Doctor;
      if (doctor.hospitalName != null && doctor.hospitalName!.isNotEmpty) {
        return doctor.hospitalName!;
      }
    }
    
    // Priority 4: Fallback
    return 'Hospital';
  }

  Future<void> _loadDoctors() async {
    setState(() {
      _loadingDoctors = true;
      _selectedDoctor = null;
      _days = [];
      _selectedSlot = null;
    });
    try {
      final docs = await _service.fetchDoctors(
        hospitalId: _hospitalId,
        department: _departmentController.text,
      );
      setState(() {
        _doctors = docs;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load doctors: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loadingDoctors = false;
        });
      }
}
  }

  Future<void> _loadSlots(dynamic doctor) async {
    setState(() {
      _selectedDoctor = doctor;
      _loadingSlots = true;
      _days = [];
      _selectedDay = null;
      _selectedSlot = null;
    });
    
    try {
      // Validate doctor belongs to current hospital before proceeding
      if (!_validateDoctorHospitalAssociation(doctor)) {
        throw Exception('This doctor is not associated with the selected hospital');
      }
      
      final doctorId = doctor is Doctor ? doctor.id : doctor.id;
      final days = await _service.fetchSlots(
        doctorId,
        date: _selectedDate != null
            ? '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}'
            : null,
      );
      setState(() {
        _days = days;
        if (_days.isNotEmpty) {
          _selectedDay = _days.first;
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load slots: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loadingSlots = false;
        });
      }
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
      if (_selectedDoctor != null) {
        _loadSlots(_selectedDoctor!);
      }
    }
  }

  Future<void> _loadDoctorSlots(int doctorId) async {
    setState(() {
      _loadingSlots = true;
      _days = [];
      _selectedDay = null;
      _selectedSlot = null;
    });
    try {
      final response = await _service.fetchMobileDoctorSlots(doctorId);
      print('DEBUG: Loaded ${response.days.length} days');
      
      // Validate doctor belongs to current hospital
      if (!_validateDoctorHospitalAssociation(response.doctor)) {
        throw Exception('This doctor is not associated with the selected hospital');
      }
      
      for (var day in response.days) {
        print('DEBUG: Day ${day.label} (${day.date}) has ${day.slots.length} slots');
        for (var slot in day.slots) {
          print('DEBUG:   Slot: id=${slot.id}, start=${slot.start}, end=${slot.end}, displayTime=${slot.displayTime}');
        }
      }
      setState(() {
        _selectedDoctor = response.doctor;
        _days = response.days;
        if (_days.isNotEmpty) {
          _selectedDay = _days.first;
          print('DEBUG: Set _selectedDay to ${_selectedDay!.label} with ${_selectedDay!.slots.length} slots');
        }
      });
    } catch (e) {
      print('DEBUG: Error loading slots: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load doctor slots: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loadingSlots = false;
        });
      }
    }
  }

  Future<void> _bookSlot(Slot slot) async {
    if (_selectedDoctor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please wait for doctor details to load')),
      );
      return;
    }

    setState(() {
      _booking = true;
    });
    try {
      final response = await _service.bookAppointment(
        availabilityId: slot.id,
      );

      if (mounted) {
        setState(() {
          _booking = false;
        });

        final doctor = _selectedDoctor is DoctorDetails 
            ? _selectedDoctor 
            : DoctorDetails(
                id: (_selectedDoctor as Doctor).id,
                name: (_selectedDoctor as Doctor).name,
                specialization: (_selectedDoctor as Doctor).specialization,
              );

        final tokenNum = response['token_number'] is int 
            ? response['token_number'] as int 
            : int.tryParse(response['token_number']?.toString() ?? '0') ?? 0;

        final dateValue = response['date']?.toString() ?? '';
        final messageValue = response['message']?.toString() ?? 'Appointment booked successfully';

        // Use consistent hospital name from single source of truth
        final consistentHospitalName = _getConsistentHospitalName();
        
        final appointment = MyAppointment(
          id: tokenNum,
          date: dateValue.isNotEmpty ? dateValue : _selectedDay?.date ?? '',
          time: slot.start,
          status: 'confirmed',
          reason: _reasonController.text,
          doctor: Doctor(
            id: doctor.id,
            name: doctor.name,
            specialization: doctor.specialization ?? '',
          ),
          hospitalName: consistentHospitalName,
          department: _departmentController.text,
        );

        try {
          final storage = StorageService();
          await storage.saveAppointment(appointment);
        } catch (e) {
          print('Error saving appointment to storage: $e');
        }

        try {
          final bookedNotificationId = (tokenNum * 100) + 0;
          await NotificationService().showLocalNotification(
            id: bookedNotificationId,
            title: 'Appointment Booked',
            body: 'Your appointment has been booked successfully.',
            payload: '{"type": "booking", "appointmentId": $tokenNum}',
          );
          final notificationStorage = StorageService();
          await notificationStorage.saveLocalNotification(LocalNotification(
            id: bookedNotificationId,
            title: 'Appointment Booked',
            message: 'Your appointment has been booked successfully.',
            type: 'booking',
            createdAt: DateTime.now(),
            appointmentId: tokenNum,
          ));
        } catch (e) {
          print('Error sending booked notification: $e');
        }

        try {
          final appointmentDateTime = appointment.appointmentDateTime;
          if (appointmentDateTime != null && appointmentDateTime.isAfter(DateTime.now())) {
            await NotificationService().scheduleAppointmentReminder(
              appointmentId: tokenNum,
              doctorName: doctor.name,
              appointmentTime: appointmentDateTime,
            );
            final reminderNotificationId = (tokenNum * 100) + 1;
            final reminderStorage = StorageService();
            await reminderStorage.saveLocalNotification(LocalNotification(
              id: reminderNotificationId,
              title: 'Appointment Reminder',
              message: 'Reminder: Your appointment with Dr. ${doctor.name} is scheduled for ${appointment.time}.',
              type: 'reminder',
              createdAt: DateTime.now(),
              appointmentId: tokenNum,
            ));
          } else {
            print('Warning: Cannot schedule reminder - appointment is in the past or invalid');
          }
        } catch (e) {
          print('Error scheduling reminder: $e');
        }

// Use the pre-loaded hospital name
final hospitalName = _getConsistentHospitalName();

// Get department from controller
final departmentName = _departmentController.text;

Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BookingConfirmationScreen(
              tokenNumber: tokenNum,
              doctorName: doctor.name,
              doctorSpecialization: doctor.specialization ?? '',
              date: dateValue,
              time: slot.displayTime,
              message: messageValue,
              hospitalName: hospitalName,
              department: departmentName,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Booking failed: $e')),
        );
        setState(() {
          _booking = false;
          _selectedSlot = null;
        });
      }
    }
  }

  String _getShift(String timeStr) {
    final time = timeStr.toLowerCase();
    if (time.contains('am')) {
      final hour = int.tryParse(time.split(':')[0]) ?? 0;
      if (hour < 12) return 'Morning';
    } else if (time.contains('pm')) {
      final hour = int.tryParse(time.split(':')[0]) ?? 0;
      if (hour == 12 || hour < 5) return 'Afternoon';
      return 'Evening';
    }
    return '';
  }

  IconData _getShiftIcon(String shift) {
    switch (shift) {
      case 'Morning':
        return Icons.wb_sunny;
      case 'Afternoon':
        return Icons.wb_twilight;
      case 'Evening':
        return Icons.bedtime;
      default:
        return Icons.access_time;
    }
  }

  Map<String, List<Slot>> _groupSlotsByShift(List<Slot> slots, {DateTime? selectedDate}) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isToday = selectedDate != null &&
        DateTime(selectedDate.year, selectedDate.month, selectedDate.day).isAtSameMomentAs(today);

    print('DEBUG: _groupSlotsByShift - Current time: $now');
    print('DEBUG: _groupSlotsByShift - Selected date: $selectedDate');
    print('DEBUG: _groupSlotsByShift - Today: $today');
    print('DEBUG: _groupSlotsByShift - Is today: $isToday');
    print('DEBUG: _groupSlotsByShift - Processing ${slots.length} slots');

    final grouped = <String, List<Slot>>{};
    int filteredCount = 0;

    for (var i = 0; i < slots.length; i++) {
      final slot = slots[i];
      print('DEBUG: Slot ${i+1}: start="${slot.start}", displayTime="${slot.displayTime}"');

      if (isToday && _isSlotInPast(slot.start, now)) {
        print('DEBUG: ⚠️ Filtering out past slot: ${slot.start} (${slot.displayTime})');
        filteredCount++;
        continue;
      }

      final shift = _getShift(slot.start);
      print('DEBUG: ✅ Slot "${slot.start}" -> Shift: $shift');
      if (shift.isNotEmpty) {
        grouped.putIfAbsent(shift, () => []);
        grouped[shift]!.add(slot);
      }
    }

    print('DEBUG: Filtered out $filteredCount past slots');
    print('DEBUG: Final grouped slots: ${grouped.map((k, v) => MapEntry(k, '${v.length} slots'))}');
    return grouped;
  }

  bool _isSlotInPast(String timeStr, DateTime now) {
    try {
      print('DEBUG: Parsing time string: "$timeStr"');

      int hour;
      int minute;

      if (timeStr.toUpperCase().contains('AM') || timeStr.toUpperCase().contains('PM')) {
        final timeWithoutMeridiem = timeStr.toUpperCase().replaceAll('AM', '').replaceAll('PM', '').trim();
        final parts = timeWithoutMeridiem.split(':');

        if (parts.length < 2) {
          print('DEBUG: Invalid AM/PM time format: $timeStr');
          return false;
        }

        final isPM = timeStr.toUpperCase().contains('PM');
        hour = int.tryParse(parts[0].trim()) ?? 0;
        minute = int.tryParse(parts[1].trim()) ?? 0;

        if (isPM && hour != 12) {
          hour += 12;
        } else if (!isPM && hour == 12) {
          hour = 0;
        }

        print('DEBUG: AM/PM time $timeStr -> Hour: $hour, Minute: $minute');
      } else {
        final parts = timeStr.split(':');
        if (parts.length < 2) {
          print('DEBUG: Invalid 24h format: $timeStr');
          return false;
        }
        hour = int.tryParse(parts[0]) ?? 0;
        minute = int.tryParse(parts[1]) ?? 0;
        print('DEBUG: 24h time $timeStr -> Hour: $hour, Minute: $minute');
      }

      final slotDateTime = DateTime(now.year, now.month, now.day, hour, minute);
      final isPast = slotDateTime.isBefore(now);

      print('DEBUG: Slot time: $slotDateTime, Current time: $now, Is past: $isPast');
      return isPast;
    } catch (e) {
      print('DEBUG: Error parsing time $timeStr: $e');
      return false;
    }
  }

  String _formatDateForDisplay(String dateStr) {
    try {
      final parts = dateStr.split('-');
      if (parts.length >= 3) {
        final year = int.tryParse(parts[0]) ?? 2024;
        final month = int.tryParse(parts[1]) ?? 1;
        final day = int.tryParse(parts[2]) ?? 1;
        if (month >= 1 && month <= 12) {
          final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
          final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
          final dateTime = DateTime(year, month, day);
          final dayOfWeek = days[dateTime.weekday - 1];
          return '$dayOfWeek $day ${months[month - 1]} $year';
        }
      }
    } catch (e) {
      print('DEBUG: Error parsing date $dateStr: $e');
    }
    return dateStr;
  }

  Widget _buildDirectBookingView() {
    return _loadingSlots
        ? Center(child: CircularProgressIndicator(color: primaryColor))
        : _selectedDoctor == null
            ? Center(child: Text('Loading doctor details...'))
            : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDoctorDetailsCard(),
                      const SizedBox(height: 20),
                      const Text(
                        'Select a Time',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      _buildDaysCalendar(),
                      const SizedBox(height: 16),
                      _buildSlotsList(),
                      if (_selectedSlot != null) ...[
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _booking ? null : () => _bookSlot(_selectedSlot!),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _booking
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Book Now',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
  }

  Widget _buildDoctorDetailsCard() {
    final doctor = _selectedDoctor;
    final name = doctor is DoctorDetails ? doctor.name : (doctor as Doctor).name;
    final specialization = doctor is DoctorDetails ? doctor.specialization : (doctor as Doctor).specialization;
    final hospital = doctor is DoctorDetails ? doctor.hospitalName : null;
    final address = doctor is DoctorDetails ? doctor.address : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.person, color: primaryColor, size: 30),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    if (specialization != null)
                      Text(
                        specialization,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (hospital != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.local_hospital, size: 18, color: primaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    hospital,
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                ),
              ],
            ),
          ],
          if (address != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on, size: 18, color: primaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    address,
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDaysCalendar() {
    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _days.length,
        itemBuilder: (context, index) {
          final day = _days[index];
          final isSelected = day == _selectedDay;
          final displayDate = _formatDateForDisplay(day.date);
          final dateParts = displayDate.split(' ');
          final dayLabel = day.label.isNotEmpty ? day.label : (dateParts.isNotEmpty ? dateParts[0] : '');
          final dayNum = dateParts.length > 1 ? dateParts[1] : '';
          final monthName = dateParts.length > 2 ? dateParts[2] : '';
          
          return Padding(
            padding: EdgeInsets.only(right: index == _days.length - 1 ? 0 : 8),
            child: GestureDetector(
              onTap: () {
                print('DEBUG: Tapped on day ${day.label} (${day.date}) with ${day.slots.length} slots');
                setState(() {
                  _selectedDay = day;
                  _selectedSlot = null;
                });
              },
              child: Container(
                width: 70,
                decoration: BoxDecoration(
                  color: isSelected ? primaryColor : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? primaryColor : Colors.grey.shade300,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      dayLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dayNum,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : primaryColor,
                      ),
                    ),
                    if (monthName.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        monthName,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: isSelected ? Colors.white70 : Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSlotsList() {
    final selectedDaySlots = _selectedDay?.slots ?? _days.firstOrNull?.slots ?? [];
    
    print('DEBUG: _buildSlotsList - selectedDaySlots length: ${selectedDaySlots.length}');
    print('DEBUG: _selectedDay: ${_selectedDay?.date}');
    
    if (selectedDaySlots.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Text('No slots available for this day'),
      );
    }

    final shiftGroups = _groupSlotsByShift(selectedDaySlots, selectedDate: _selectedDate);
    print('DEBUG: Shift groups: ${shiftGroups.keys}');
    
    final shifts = ['Morning', 'Afternoon', 'Evening'];
    bool hasAnyShiftSlots = false;
    for (var shift in shifts) {
      if ((shiftGroups[shift]?.length ?? 0) > 0) {
        hasAnyShiftSlots = true;
        break;
      }
    }

    if (!hasAnyShiftSlots) {
      print('DEBUG: No slots matched any shift, showing all slots');
      return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: selectedDaySlots.map((slot) {
          final isSelected = _selectedSlot?.id == slot.id;
          final isBooking = _booking && isSelected;
                final timeDisplay = slot.displayTime.isNotEmpty ? slot.displayTime : slot.start;
          return GestureDetector(
            onTap: isBooking ? null : () {
              setState(() {
                _selectedSlot = slot;
              });
            },
            child: Container(
              width: 100,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? primaryColor : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? primaryColor : Colors.grey.shade300,
                ),
              ),
              child: Center(
                child: isBooking
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        timeDisplay,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : Colors.black87,
                        ),
                      ),
              ),
            ),
          );
        }).toList(),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: shifts.map((shift) {
        final shiftSlots = shiftGroups[shift] ?? [];
        print('DEBUG: Shift $shift has ${shiftSlots.length} slots');
        
        if (shiftSlots.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Icon(
                    _getShiftIcon(shift),
                    size: 20,
                    color: const Color(0xFF8c6239),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    shift,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
            ),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: shiftSlots.map((slot) {
                final isSelected = _selectedSlot?.id == slot.id;
                final isBooking = _booking && isSelected;
                final timeDisplay = slot.displayTime.isNotEmpty ? slot.displayTime : slot.start;
                return GestureDetector(
                  onTap: isBooking ? null : () {
                    setState(() {
                      _selectedSlot = slot;
                    });
                  },
                  child: Container(
                    width: 100,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? primaryColor : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? primaryColor : Colors.grey.shade300,
                      ),
                    ),
                    child: Center(
                      child: isBooking
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              timeDisplay,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? Colors.white : Colors.black87,
                              ),
                            ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildSearchAndSelectView() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _departmentController,
                decoration: const InputDecoration(
                  labelText: 'Department (e.g. Cardiology)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _reasonController,
                decoration: const InputDecoration(
                  labelText: 'Reason for Visit',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _selectDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Select Date',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          _selectedDate != null
                              ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                              : 'Tap to select date',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _loadingDoctors ? null : _loadDoctors,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                    ),
                    child: _loadingDoctors
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Search'),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: _loadingDoctors
                    ? const Center(child: CircularProgressIndicator())
                    : _doctors.isEmpty
                        ? const Center(child: Text('No doctors found'))
                        : ListView.builder(
                            itemCount: _doctors.length,
                            itemBuilder: (context, index) {
                              final d = _doctors[index];
                              final selected = _selectedDoctor is Doctor && d.id == (_selectedDoctor as Doctor).id;
                              return ListTile(
                                title: Text(d.name),
                                subtitle: Text(d.specialization),
                                selected: selected,
                                onTap: () => _loadSlots(d),
                              );
                            },
                          ),
              ),
              Expanded(
                flex: 3,
                child: _loadingSlots
                    ? const Center(child: CircularProgressIndicator())
                    : _selectedDoctor == null
                        ? const Center(
                            child: Text('Select a doctor to see slots'),
                          )
                        : _days.isEmpty
                            ? const Center(
                                child: Text('No slots available'),
                              )
                            : ListView.builder(
                                itemCount: _days.length,
                                itemBuilder: (context, index) {
                                  final day = _days[index];
                                  return ExpansionTile(
                                    title: Text('${day.label} (${day.date})'),
                                    children: day.slots.isEmpty
                                        ? const [
                                            Padding(
                                              padding: EdgeInsets.all(8.0),
                                              child: Text('No slots available'),
                                            ),
                                          ]
                                        : day.slots.map((slot) {
                                            final isSelected = _selectedSlot?.id == slot.id;
                                            final isBooking = _booking && isSelected;
                                            final timeDisplay = slot.displayTime.isNotEmpty ? slot.displayTime : '${slot.start} - ${slot.end}';
                                            return ListTile(
                                              title: Text(timeDisplay),
                                              trailing: isBooking
                                                  ? const SizedBox(
                                                      width: 20,
                                                      height: 20,
                                                      child: CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                      ),
                                                    )
                                                  : isSelected
                                                      ? const Icon(
                                                          Icons.check_circle,
                                                          color: Colors.green,
                                                        )
                                                      : null,
                                              onTap: isBooking ? null : () => _bookSlot(slot),
                                            );
                                          }).toList(),
                                  );
                                },
                              ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          SafeArea(
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
                    ],
                  ),
                ),

                Expanded(
                  child: widget.doctorId != null
                      ? _buildDirectBookingView()
                      : _buildSearchAndSelectView(),
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
                        active: false,
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const HospitalListScreen(),
                            ),
                          );
                        },
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: primaryColor,
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(14),
                        child: const Icon(Icons.add, color: Colors.white),
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
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
              ],
             ),
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
}
