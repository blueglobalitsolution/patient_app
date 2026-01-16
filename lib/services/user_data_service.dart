class UserDataService {
  static final UserDataService _instance = UserDataService._internal();
  factory UserDataService() => _instance;
  UserDataService._internal();

  double? latitude;
  double? longitude;
  String? cityName;

  bool get isLocationLoaded => latitude != null && longitude != null && cityName != null;
}
