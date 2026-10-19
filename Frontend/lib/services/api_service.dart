import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Change this to your backend URL
  static const String baseUrl = 'https://campuscleaning-express.vercel.app/api';

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
  }

  static Future<void> saveUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user', jsonEncode(user));
  }

  static Future<Map<String, dynamic>?> getSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString('user');
    if (str == null) return null;
    return jsonDecode(str);
  }

  static Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = {'Content-Type': 'application/json'};
    if (auth) {
      final token = await getToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static Future<dynamic> _handleResponse(http.Response response) async {
    final body = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    } else {
      throw Exception(body['message'] ?? 'Something went wrong');
    }
  }

  // Auth
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: await _headers(auth: false),
      body: jsonEncode({'email': email, 'password': password}),
    );
    final data = await _handleResponse(res);
    if (data['token'] != null) {
      await saveToken(data['token']);
      await saveUser(data['data']);
    }
    return data;
  }

  static Future<Map<String, dynamic>> getMe() async {
    final res = await http.get(
      Uri.parse('$baseUrl/auth/me'),
      headers: await _headers(),
    );
    return await _handleResponse(res);
  }

  // Departments
  static Future<List<dynamic>> getDepartments() async {
    final res = await http.get(
      Uri.parse('$baseUrl/departments'),
      headers: await _headers(),
    );
    final data = await _handleResponse(res);
    return data['data'] ?? [];
  }

  static Future<Map<String, dynamic>> createDepartment(Map<String, dynamic> body) async {
    final res = await http.post(
      Uri.parse('$baseUrl/departments'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    return await _handleResponse(res);
  }

  static Future<Map<String, dynamic>> updateDepartment(String id, Map<String, dynamic> body) async {
    final res = await http.put(
      Uri.parse('$baseUrl/departments/$id'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    return await _handleResponse(res);
  }

  static Future<void> deleteDepartment(String id) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/departments/$id'),
      headers: await _headers(),
    );
    await _handleResponse(res);
  }

  // Rooms
  static Future<List<dynamic>> getRooms({String? department, String? type}) async {
    var url = '$baseUrl/rooms';
    final params = <String>[];
    if (department != null) params.add('department=$department');
    if (type != null) params.add('type=$type');
    if (params.isNotEmpty) url += '?${params.join('&')}';

    final res = await http.get(Uri.parse(url), headers: await _headers());
    final data = await _handleResponse(res);
    return data['data'] ?? [];
  }

  static Future<List<dynamic>> getMyRooms() async {
    final res = await http.get(
      Uri.parse('$baseUrl/rooms/my'),
      headers: await _headers(),
    );
    final data = await _handleResponse(res);
    return data['data'] ?? [];
  }

  static Future<Map<String, dynamic>> createRoom(Map<String, dynamic> body) async {
    final res = await http.post(
      Uri.parse('$baseUrl/rooms'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    return await _handleResponse(res);
  }

  static Future<Map<String, dynamic>> updateRoom(String id, Map<String, dynamic> body) async {
    final res = await http.put(
      Uri.parse('$baseUrl/rooms/$id'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    return await _handleResponse(res);
  }

  static Future<void> deleteRoom(String id) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/rooms/$id'),
      headers: await _headers(),
    );
    await _handleResponse(res);
  }

  // Users
  static Future<List<dynamic>> getUsers({String? role}) async {
    var url = '$baseUrl/users';
    if (role != null) url += '?role=$role';
    final res = await http.get(Uri.parse(url), headers: await _headers());
    final data = await _handleResponse(res);
    return data['data'] ?? [];
  }

  static Future<Map<String, dynamic>> createUser(Map<String, dynamic> body) async {
    final res = await http.post(
      Uri.parse('$baseUrl/users'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    return await _handleResponse(res);
  }

  static Future<Map<String, dynamic>> updateUser(String id, Map<String, dynamic> body) async {
    final res = await http.put(
      Uri.parse('$baseUrl/users/$id'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    return await _handleResponse(res);
  }

  static Future<void> deleteUser(String id) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/users/$id'),
      headers: await _headers(),
    );
    await _handleResponse(res);
  }

  // Tasks
  static Future<Map<String, dynamic>> getDashboardStats({String? date}) async {
    var url = '$baseUrl/tasks/stats';
    if (date != null) url += '?date=$date';
    final res = await http.get(Uri.parse(url), headers: await _headers());
    return await _handleResponse(res);
  }

  static Future<List<dynamic>> getTasks({
    String? status,
    String? date,
    String? sweeper,
  }) async {
    var url = '$baseUrl/tasks';
    final params = <String>[];
    if (status != null) params.add('status=$status');
    if (date != null) params.add('date=$date');
    if (sweeper != null) params.add('sweeper=$sweeper');
    if (params.isNotEmpty) url += '?${params.join('&')}';

    final res = await http.get(Uri.parse(url), headers: await _headers());
    final data = await _handleResponse(res);
    return data['data'] ?? [];
  }

  static Future<List<dynamic>> getMyTasks({String? date, String? status}) async {
    var url = '$baseUrl/tasks/my';
    final params = <String>[];
    if (date != null) params.add('date=$date');
    if (status != null) params.add('status=$status');
    if (params.isNotEmpty) url += '?${params.join('&')}';

    final res = await http.get(Uri.parse(url), headers: await _headers());
    final data = await _handleResponse(res);
    return data['data'] ?? [];
  }

  static Future<List<dynamic>> getInvigilatorTasks({String? date, String? status}) async {
    var url = '$baseUrl/tasks/invigilator';
    final params = <String>[];
    if (date != null) params.add('date=$date');
    if (status != null) params.add('status=$status');
    if (params.isNotEmpty) url += '?${params.join('&')}';

    final res = await http.get(Uri.parse(url), headers: await _headers());
    final data = await _handleResponse(res);
    return data['data'] ?? [];
  }

  static Future<Map<String, dynamic>> assignTasks(List<Map<String, String>> assignments, {String? dutyDate}) async {
    final Map<String, dynamic> body = {'assignments': assignments};
    if (dutyDate != null) body['dutyDate'] = dutyDate;
    final res = await http.post(
      Uri.parse('$baseUrl/tasks/assign'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    return await _handleResponse(res);
  }

  static Future<Map<String, dynamic>> completeTask(String id, {String? notes}) async {
    final res = await http.put(
      Uri.parse('$baseUrl/tasks/$id/complete'),
      headers: await _headers(),
      body: jsonEncode({'notes': notes}),
    );
    return await _handleResponse(res);
  }

  static Future<Map<String, dynamic>> verifyTask(String id, {String? notes}) async {
    final res = await http.put(
      Uri.parse('$baseUrl/tasks/$id/verify'),
      headers: await _headers(),
      body: jsonEncode({'notes': notes}),
    );
    return await _handleResponse(res);
  }

  static Future<Map<String, dynamic>> rejectTask(String id, String reason) async {
    final res = await http.put(
      Uri.parse('$baseUrl/tasks/$id/reject'),
      headers: await _headers(),
      body: jsonEncode({'reason': reason}),
    );
    return await _handleResponse(res);
  }

  static Future<Map<String, dynamic>> getTask(String id) async {
    final res = await http.get(
      Uri.parse('$baseUrl/tasks/$id'),
      headers: await _headers(),
    );
    return await _handleResponse(res);
  }
}
