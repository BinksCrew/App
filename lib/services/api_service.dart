import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'https://serverbinks.onrender.com/api';

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> setToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  Future<void> saveUserData(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', jsonEncode(user));
  }

  Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user_data');
    if (userData != null) {
      return jsonDecode(userData);
    }
    return null;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user_data');
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      await setToken(data['token']);
      await saveUserData(data);
      return data;
    } else {
      throw Exception(jsonDecode(response.body)['message'] ?? 'Error al iniciar sesión');
    }
  }

  Future<Map<String, dynamic>> register({
    required String cedula,
    required String email,
    required String password,
    String? fullName,
    String? username,
    String? phone,
    File? file,
  }) async {
    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/auth/register'));
    
    request.fields['cedula'] = cedula;
    request.fields['email'] = email;
    request.fields['password'] = password;
    if (fullName != null) request.fields['fullName'] = fullName;
    if (username != null) request.fields['username'] = username;
    if (phone != null) request.fields['phone'] = phone;

    if (file != null) {
      request.files.add(await http.MultipartFile.fromPath('file', file.path));
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      await setToken(data['token']);
      await saveUserData(data);
      return data;
    } else {
      throw Exception(jsonDecode(response.body)['message'] ?? 'Error al registrarse');
    }
  }

  Future<Map<String, dynamic>> updateUser(String id, Map<String, String> fields, File? file) async {
    final token = await getToken();
    var request = http.MultipartRequest('PATCH', Uri.parse('$baseUrl/users/$id'));
    
    request.headers['Authorization'] = 'Bearer $token';
    
    fields.forEach((key, value) {
      request.fields[key] = value;
    });

    if (file != null) {
      request.files.add(await http.MultipartFile.fromPath('file', file.path));
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      // Update local user data merging with existing
      final currentUser = await getUserData();
      if (currentUser != null) {
        final Map<String, dynamic> updatedUser = {...currentUser, ...data};
        await saveUserData(updatedUser);
        return updatedUser;
      }
      return data;
    } else {
      throw Exception(jsonDecode(response.body)['message'] ?? 'Error al actualizar perfil');
    }
  }

  Future<List<dynamic>> getQuestions() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/questions'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al obtener preguntas');
    }
  }

  Future<Map<String, dynamic>> answerQuestion(String questionId, String answer) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/questions/$questionId/answer'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'answer': answer}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al enviar respuesta');
    }
  }
}
