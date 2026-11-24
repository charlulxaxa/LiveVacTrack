import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../errors/app_exception.dart';

/// A selected barangay plus enough context to display it.
class AreaSelection {
  const AreaSelection({
    required this.id,
    required this.name,
    this.city,
    this.province,
  });

  final String id;
  final String name;
  final String? city;
  final String? province;

  /// e.g. "Poblacion, City of Batac, Ilocos Norte".
  String get fullName {
    final List<String> parts = <String>[
      name,
      if (city != null && city!.isNotEmpty) city!,
      if (province != null && province!.isNotEmpty) province!,
    ];
    return parts.join(', ');
  }
}

class PsgcRegion {
  const PsgcRegion({required this.code, required this.name});

  final String code;
  final String name;

  factory PsgcRegion.fromMap(Map<String, dynamic> map) => PsgcRegion(
        code: (map['code'] as String?) ?? '',
        name: (map['name'] as String?) ?? '',
      );
}

class PsgcProvince {
  const PsgcProvince({
    required this.code,
    required this.name,
    required this.region,
  });

  final String code;
  final String name;
  final String region;

  factory PsgcProvince.fromMap(Map<String, dynamic> map) => PsgcProvince(
        code: (map['code'] as String?) ?? '',
        name: (map['name'] as String?) ?? '',
        region: (map['region'] as String?) ?? '',
      );
}

class PsgcCity {
  const PsgcCity({
    required this.code,
    required this.name,
    required this.type,
    required this.province,
  });

  final String code;
  final String name;
  final String type;
  final String province;

  String get label => type == 'City' ? name : '$name (Municipality)';

  factory PsgcCity.fromMap(Map<String, dynamic> map) => PsgcCity(
        code: (map['code'] as String?) ?? '',
        name: (map['name'] as String?) ?? '',
        type: (map['type'] as String?) ?? '',
        province: (map['province'] as String?) ?? '',
      );
}

class PsgcBarangay {
  const PsgcBarangay({
    required this.code,
    required this.name,
    required this.cityMunicipality,
    required this.province,
  });

  final String code;
  final String name;
  final String cityMunicipality;
  final String province;

  factory PsgcBarangay.fromMap(Map<String, dynamic> map) => PsgcBarangay(
        code: (map['code'] as String?) ?? '',
        name: (map['name'] as String?) ?? '',
        cityMunicipality: (map['city_municipality'] as String?) ?? '',
        province: (map['province'] as String?) ?? '',
      );
}

/// Fetches Philippine locations from https://psgc.cloud with a local cache.
///
/// The full barangay list is ~42k rows, so the API is consumed as a cascade:
/// provinces -> cities/municipalities -> barangays.
class PsgcLocationService {
  PsgcLocationService({http.Client? client}) : _client = client ?? http.Client();

  static const String _base = 'https://psgc.cloud/api/v2';
  static const Duration _ttl = Duration(days: 7);

  final http.Client _client;

  /// PSGC barangay codes are 10 digits; the first 7 identify the city or
  /// municipality, whose own code ends in 000 (e.g. barangay 0102801001 is in
  /// 0102801000). Returns null for ids that are not PSGC barangay codes, such
  /// as the demo areas.
  static String? cityCodeForBarangay(String? barangayCode) {
    if (barangayCode == null ||
        !RegExp(r'^\d{10}$').hasMatch(barangayCode)) {
      return null;
    }
    return '${barangayCode.substring(0, 7)}000';
  }

  Future<List<PsgcRegion>> fetchRegions() async {
    final List<dynamic> data = await _getList('/regions', 'psgc:v2:regions');
    return data
        .whereType<Map<String, dynamic>>()
        .map(PsgcRegion.fromMap)
        .where((PsgcRegion r) => r.code.isNotEmpty)
        .toList();
  }

  /// Every city and municipality in a region, including ones that are not
  /// under a province (Metro Manila, Cotabato City, Isabela City).
  Future<List<PsgcCity>> fetchRegionCities(String regionCode) async {
    final List<dynamic> data = await _getList(
      '/regions/$regionCode/cities-municipalities',
      'psgc:v2:region-cities:$regionCode',
    );
    return data
        .whereType<Map<String, dynamic>>()
        .map(PsgcCity.fromMap)
        .where((PsgcCity c) => c.code.isNotEmpty)
        .toList();
  }

  Future<List<PsgcProvince>> fetchProvinces() async {
    final List<dynamic> data =
        await _getList('/provinces', 'psgc:v2:provinces');
    return data
        .whereType<Map<String, dynamic>>()
        .map(PsgcProvince.fromMap)
        .where((PsgcProvince p) => p.code.isNotEmpty)
        .toList();
  }

  Future<List<PsgcCity>> fetchCities(String provinceCode) async {
    final List<dynamic> data = await _getList(
      '/provinces/$provinceCode/cities-municipalities',
      'psgc:v2:cities:$provinceCode',
    );
    return data
        .whereType<Map<String, dynamic>>()
        .map(PsgcCity.fromMap)
        .where((PsgcCity c) => c.code.isNotEmpty)
        .toList();
  }

  Future<List<PsgcBarangay>> fetchBarangays(String cityCode) async {
    final List<dynamic> data = await _getList(
      '/cities-municipalities/$cityCode/barangays',
      'psgc:v2:barangays:$cityCode',
    );
    return data
        .whereType<Map<String, dynamic>>()
        .map(PsgcBarangay.fromMap)
        .where((PsgcBarangay b) => b.code.isNotEmpty)
        .toList();
  }

  Future<List<dynamic>> _getList(String path, String cacheKey) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic>? cached = _readCache(prefs, cacheKey);
    if (cached != null && _isFresh(cached)) {
      return cached['data'] as List<dynamic>;
    }

    try {
      final http.Response response = await _client
          .get(Uri.parse('$_base$path'))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        throw AppException(
          'Location service returned ${response.statusCode}.',
        );
      }
      final dynamic decoded = jsonDecode(response.body);
      final List<dynamic> data =
          (decoded is Map<String, dynamic> ? decoded['data'] : decoded)
                  as List<dynamic>? ??
              <dynamic>[];
      await prefs.setString(
        cacheKey,
        jsonEncode(<String, dynamic>{
          'ts': DateTime.now().millisecondsSinceEpoch,
          'data': data,
        }),
      );
      return data;
    } catch (error) {
      // Fall back to stale cache when the network is unavailable.
      if (cached != null) return cached['data'] as List<dynamic>;
      if (error is AppException) rethrow;
      throw const AppException(
        'Could not load locations. Check your connection and try again.',
      );
    }
  }

  Map<String, dynamic>? _readCache(SharedPreferences prefs, String key) {
    final String? raw = prefs.getString(key);
    if (raw == null) return null;
    try {
      final dynamic decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {
      return null;
    }
    return null;
  }

  bool _isFresh(Map<String, dynamic> cached) {
    final int? ts = (cached['ts'] as num?)?.toInt();
    if (ts == null) return false;
    final DateTime saved = DateTime.fromMillisecondsSinceEpoch(ts);
    return DateTime.now().difference(saved) < _ttl;
  }
}
