import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/hospital_models.dart';
import '../utils/constants.dart';

class HospitalService {
  Future<List<Hospital>> getNearbyHospitals(double lat, double lng, {double radius = 5.0}) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}/hospitals/nearby/?lat=$lat&lng=$lng&radius=$radius');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Hospital.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load hospitals: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}
