import 'package:flutter/material.dart';
import 'package:contact_manager_app/services/location_service.dart';
import 'package:contact_manager_app/services/search_service.dart';
import 'package:contact_manager_app/services/user_data_service.dart';
import 'package:contact_manager_app/models/search_models.dart';
import 'patient_dashboard.dart';
import 'book_appointment_screen.dart';

class HospitalScreen extends StatefulWidget {
  final String? initialQuery;

  const HospitalScreen({super.key, this.initialQuery});

  @override
  State<HospitalScreen> createState() => _HospitalScreenState();
}

class _HospitalScreenState extends State<HospitalScreen> {
  final LocationService _locationService = LocationService();
  final SearchService _searchService = SearchService();
  final TextEditingController _searchController = TextEditingController();

  SearchResult? _searchResult;
  bool _loading = true;
  bool _searching = false;
  String _errorMessage = '';
  String? _resolvedKeyword;
  String? _cityName;

  Color get primaryColor => const Color(0xFF8c6239);
  Color get bgColor => const Color(0xfff2f2f2);

  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeScreen() async {
    setState(() {
      _loading = true;
      _errorMessage = '';
      _searchResult = null;
    });

    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      print('DEBUG: Initial query received: ${widget.initialQuery}');
      _searchController.text = widget.initialQuery!;
    }

    if (UserDataService().isLocationLoaded) {
      _cityName = UserDataService().cityName;
      print('DEBUG: Using saved location - City: $_cityName');
    } else {
      print('DEBUG: No saved location, getting fresh location...');
      try {
        final position = await _locationService.getCurrentLocation();
        final city = await _locationService.getCityName(position.latitude, position.longitude);

        UserDataService().latitude = position.latitude;
        UserDataService().longitude = position.longitude;
        UserDataService().cityName = city;

        _cityName = city;
        print('DEBUG: Fresh location loaded - City: $city');
      } catch (e) {
        print('DEBUG: Could not get location: $e');
        setState(() {
          _errorMessage = 'Could not get your location. Please enable location services.';
          _loading = false;
        });
        return;
      }
    }

    setState(() {
      _loading = false;
    });

    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty && _cityName != null && _cityName!.isNotEmpty) {
      print('DEBUG: Auto-searching with city=$_cityName, query=${widget.initialQuery}');
      _performSearch(widget.initialQuery!);
    } else {
      print('DEBUG: Auto-search skipped. initialQuery=${widget.initialQuery}, city=$_cityName');
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResult = null;
        _resolvedKeyword = null;
      });
      return;
    }

    final cityToSend = _cityName ?? 'Vadodara';
    print('DEBUG: Starting search - query: "$query", city: "$cityToSend"');

    setState(() {
      _searching = true;
      _errorMessage = '';
    });

    try {
      final result = await _searchService.universalSearch(
        query: query,
        city: cityToSend,
      );
      print('DEBUG: Search completed successfully');

      setState(() {
        _searchResult = result;
        _resolvedKeyword = result.resolvedKeyword;
        _searching = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _searching = false;
      });
    }
  }

  List<SearchHospital> get _displayHospitals =>
      _searchResult?.hospitals ?? [];

  List<SearchDoctor> get _displayDoctors =>
      _searchResult?.doctors ?? [];

  List<dynamic> get _filteredItems {
    if (_selectedTab == 0) {
      final all = <dynamic>[..._displayDoctors, ..._displayHospitals];
      return all;
    } else if (_selectedTab == 1) {
      return _displayDoctors;
    } else {
      return _displayHospitals;
    }
  }

  Widget _tabButton(int tabIndex, String label) {
    final isSelected = _selectedTab == tabIndex;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = tabIndex;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }

  void _onDoctorTap(SearchDoctor doctor) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookAppointmentScreen(),
      ),
    );
  }

  void _onHospitalTap(SearchHospital hospital) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookAppointmentScreen(),
      ),
    );
  }

  Widget _buildResultCard(dynamic item) {
    if (item is SearchDoctor) {
      return _ResultCard(
        title: item.name,
        subtitle: '${item.specialization ?? 'Doctor'} | ${item.hospitalName ?? ''}',
        icon: Icons.person,
        isDoctor: true,
        doctor: item,
        hospital: null,
        onTap: () => _onDoctorTap(item),
      );
    } else if (item is SearchHospital) {
      return _ResultCard(
        title: item.name,
        subtitle: 'Hospital | ${item.department ?? 'General'}',
        icon: Icons.local_hospital,
        isDoctor: false,
        doctor: null,
        hospital: item,
        onTap: () => _onHospitalTap(item),
      );
    }
    return const SizedBox.shrink();
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
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Icon(Icons.notifications_none, color: primaryColor),
                  ),
                ],
              ),
            ),

            if (_loading)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: primaryColor),
                      SizedBox(height: 16),
                      Text('Getting your location...'),
                    ],
                  ),
                ),
              )
            else if (_errorMessage.isNotEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red),
                      SizedBox(height: 16),
                      Text('Error: $_errorMessage'),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _initializeScreen,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                        ),
                        child: Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF245BFF), Color(0xFF4F7BFF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(24),
                          bottomRight: Radius.circular(24),
                        ),
                      ),
                       child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Find Hospital${_cityName != null ? ' in $_cityName' : ' Near Your Location'}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Search hospital or doctor to book an appointment',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: 'Search hospital or doctor (e.g., "chest pain")',
                                hintStyle: const TextStyle(fontSize: 13),
                                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                                suffixIcon: IconButton(
                                  icon: Icon(Icons.clear, color: Colors.grey),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _searchResult = null;
                                      _resolvedKeyword = null;
                                    });
                                  },
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                              onSubmitted: _performSearch,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    const SizedBox(height: 16),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _tabButton(0, 'All'),
                                  ),
                                  Expanded(
                                    child: _tabButton(1, 'Doctors'),
                                  ),
                                  Expanded(
                                    child: _tabButton(2, 'Hospitals'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    if (_resolvedKeyword != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Searched for: "$_resolvedKeyword"',
                                  style: TextStyle(color: Colors.blue.shade700, fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    Expanded(
                      child: _searching
                          ? Center(child: CircularProgressIndicator(color: primaryColor))
                          : _filteredItems.isEmpty
                              ? Center(child: Text('No results found'))
                              : ListView.builder(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  itemCount: _filteredItems.length,
                                  itemBuilder: (context, index) {
                                    final item = _filteredItems[index];

                                    if (_selectedTab == 0 && index == _displayDoctors.length && _displayDoctors.isNotEmpty && _displayHospitals.isNotEmpty) {
                                      return Column(
                                        children: [
                                          Container(
                                            height: 1,
                                            color: Colors.grey.shade300,
                                            margin: const EdgeInsets.symmetric(vertical: 16),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                            color: Colors.grey.shade200,
                                            child: Text(
                                              'Hospitals',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.grey.shade700,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          _buildResultCard(item),
                                        ],
                                      );
                                    } else {
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 10),
                                        child: _buildResultCard(item),
                                      );
                                    }
                                  },
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

class _ResultCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final IconData icon;
  final bool isDoctor;
  final SearchDoctor? doctor;
  final SearchHospital? hospital;

  const _ResultCard({
    required this.title,
    required this.subtitle,
    this.onTap,
    this.icon = Icons.local_hospital,
    required this.isDoctor,
    this.doctor,
    this.hospital,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF8c6239);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xfff2f2f2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.grey),
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
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 32,
              child: ElevatedButton(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  isDoctor ? 'Book' : 'View',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
