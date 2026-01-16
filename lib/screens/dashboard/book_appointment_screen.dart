import 'package:flutter/material.dart';
import '../../models/appointment_models.dart';
import '../../services/appointment_service.dart';
import 'patient_dashboard.dart';
import 'hospital_screen.dart';

class BookAppointmentScreen extends StatefulWidget {
  const BookAppointmentScreen({super.key});

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  final _service = AppointmentService();
  final _departmentController = TextEditingController(text: 'Cardiology');
  final _reasonController = TextEditingController(text: 'Consultation');
  final int _hospitalId = 1;

  bool _loadingDoctors = false;
  bool _loadingSlots = false;
  bool _booking = false;
  List<Doctor> _doctors = [];
  Doctor? _selectedDoctor;
  List<SlotDay> _days = [];
  DateTime? _selectedDate;
  Slot? _selectedSlot;

  Color get primaryColor => const Color(0xFF8c6239);
  Color get bgColor => const Color(0xfff2f2f2);

  @override
  void initState() {
    super.initState();
    _loadDoctors();
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

  Future<void> _loadSlots(Doctor doctor) async {
    setState(() {
      _selectedDoctor = doctor;
      _loadingSlots = true;
      _days = [];
      _selectedSlot = null;
    });
    try {
      final days = await _service.fetchSlots(
        doctor.id,
        date: _selectedDate != null
            ? '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}'
            : null,
      );
      setState(() {
        _days = days;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load slots: $e')),
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

  Future<void> _bookSlot(Slot slot) async {
    if (_selectedDoctor == null || _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a doctor and date')),
      );
      return;
    }

    setState(() {
      _booking = true;
      _selectedSlot = slot;
    });
    try {
      final dateStr = '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}';
      
      final msg = await _service.bookAppointment(
        doctorId: _selectedDoctor!.id,
        slotId: slot.id,
        date: dateStr,
        reason: _reasonController.text,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Booking failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _booking = false;
          _selectedSlot = null;
        });
      }
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
              child: Column(
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
                                        final selected = d.id == _selectedDoctor?.id;
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
                                                      return ListTile(
                                                        title: Text('${slot.start} - ${slot.end}'),
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
              ),
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
                          builder: (_) => const HospitalScreen(),
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
                    icon: Icons.local_pharmacy,
                    label: 'Pharmacy',
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
