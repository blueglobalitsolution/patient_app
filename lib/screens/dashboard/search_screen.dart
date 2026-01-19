import 'package:flutter/material.dart';
import 'package:contact_manager_app/services/search_service.dart';
import 'package:contact_manager_app/services/location_service.dart';
import 'package:contact_manager_app/services/user_data_service.dart';
import 'package:contact_manager_app/models/search_models.dart';
import 'package:contact_manager_app/screens/dashboard/book_appointment_screen.dart';
import 'package:contact_manager_app/screens/dashboard/hospital_details_screen.dart';
import 'package:contact_manager_app/screens/dashboard/patient_dashboard.dart';
import 'package:contact_manager_app/screens/dashboard/hospital_list_screen.dart';
import 'package:contact_manager_app/screens/profile_screen.dart';

class SearchScreen extends StatefulWidget {
  final String? initialQuery;

  const SearchScreen({super.key, this.initialQuery});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final SearchService _searchService = SearchService();
  final LocationService _locationService = LocationService();
  final TextEditingController _searchController = TextEditingController();

  SearchResult? _searchResult;
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
    print('DEBUG: SearchScreen initialQuery = ${widget.initialQuery}');
    print('DEBUG: UserDataService.isLocationLoaded = ${UserDataService().isLocationLoaded}');
    print('DEBUG: UserDataService.cityName = ${UserDataService().cityName}');

    if (UserDataService().isLocationLoaded) {
      _cityName = UserDataService().cityName;
      print('DEBUG: Using saved city - City: $_cityName');
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
        _cityName = 'Vadodara';
      }
    }

    setState(() {});

    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      print('DEBUG: Auto-searching with city=$_cityName, query=${widget.initialQuery}');
      _searchController.text = widget.initialQuery!;
      _performSearch(widget.initialQuery!);
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
      print('DEBUG: Search completed - Doctors: ${result.doctors.length}, Hospitals: ${result.hospitals.length}');

      setState(() {
        _searchResult = result;
        _resolvedKeyword = result.resolvedKeyword;
        _searching = false;
      });
    } catch (e) {
      print('DEBUG: Search error: $e');
      setState(() {
        _errorMessage = e.toString();
        _searching = false;
      });
    }
  }

  List<SearchHospital> get _displayHospitals {
    final hospitals = _searchResult?.hospitals ?? [];
    print('DEBUG: _displayHospitals count = ${hospitals.length}');
    return hospitals;
  }

  List<SearchDoctor> get _displayDoctors {
    final doctors = _searchResult?.doctors ?? [];
    print('DEBUG: _displayDoctors count = ${doctors.length}');
    return doctors;
  }

  List<dynamic> get _filteredItems {
    final filtered = <dynamic>[];

    if (_selectedTab == 0) {
      filtered.addAll(_displayDoctors);
      filtered.addAll(_displayHospitals);
      print('DEBUG: All tab - total items = ${filtered.length}');
    } else if (_selectedTab == 1) {
      filtered.addAll(_displayDoctors);
      print('DEBUG: Doctors tab - total items = ${filtered.length}');
    } else {
      filtered.addAll(_displayHospitals);
      print('DEBUG: Hospitals tab - total items = ${filtered.length}');
    }

    return filtered;
  }

  Widget _tabButton(int tabIndex, String label) {
    final isSelected = _selectedTab == tabIndex;
    return Expanded(
      child: GestureDetector(
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
      ),
    );
  }

  void _onDoctorTap(SearchDoctor doctor) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookAppointmentScreen(doctorId: doctor.id),
      ),
    );
  }

  void _onHospitalTap(SearchHospital hospital) {
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

  Widget _buildResultCard(dynamic item) {
    if (item is SearchDoctor) {
      return _ResultCard(
        title: item.name,
        subtitle: '${item.specialization ?? 'Doctor'} | ${item.hospitalName ?? ''}',
        icon: Icons.person,
        isDoctor: true,
        onTap: () => _onDoctorTap(item),
      );
    } else if (item is SearchHospital) {
      return _ResultCard(
        title: item.name,
        subtitle: 'Hospital | ${item.department ?? 'General'}',
        icon: Icons.local_hospital,
        isDoctor: false,
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
            _buildHeader(),
            Expanded(
              child: Column(
                children: [
                  _searchResult == null && !_searching
                      ? _buildInitialView()
                      : _buildResultsView(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _bottomNavigation(),
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
            child: Container(
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextField(
                controller: _searchController,
                autofocus: widget.initialQuery == null || widget.initialQuery!.isEmpty,
                decoration: InputDecoration(
                  hintText: 'Search hospital or doctor',
                  hintStyle: const TextStyle(fontSize: 13),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchResult = null;
                              _resolvedKeyword = null;
                            });
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onSubmitted: _performSearch,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Search for hospitals or doctors',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsView() {
    print('DEBUG: _buildResultsView called');
    print('DEBUG: _searching = $_searching');
    print('DEBUG: _errorMessage = "$_errorMessage"');
    print('DEBUG: _searchResult = $_searchResult');
    print('DEBUG: _filteredItems.length = ${_filteredItems.length}');

    if (_searching) {
      print('DEBUG: Showing loading indicator');
      return Center(child: CircularProgressIndicator(color: primaryColor));
    }

    if (_errorMessage.isNotEmpty) {
      print('DEBUG: Showing error: $_errorMessage');
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
                onPressed: () => _performSearch(_searchController.text),
                style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    print('DEBUG: Showing results view with ${_filteredItems.length} items');

    if (_filteredItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No results found',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        const SizedBox(height: 16),

        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              _tabButton(0, 'All'),
              _tabButton(1, 'Doctors'),
              _tabButton(2, 'Hospitals'),
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
                  const SizedBox(width: 8),
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
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _filteredItems.length,
            itemBuilder: (context, index) {
              final item = _filteredItems[index];
              print('DEBUG: Building card for item at index $index: $item');

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
    );
  }
}

class _ResultCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final IconData icon;
  final bool isDoctor;

  const _ResultCard({
    required this.title,
    required this.subtitle,
    this.onTap,
    this.icon = Icons.local_hospital,
    required this.isDoctor,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF8c6239);

    return Container(
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
    );
  }
}
