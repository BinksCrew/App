import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'https://serverbinks.onrender.com/api';
  static const Duration timeout = Duration(seconds: 30);
  // Simple in-memory caches to speed up navigation without re-fetching
  static List<dynamic>? _cachedAnimes;
  static final Map<String, List<dynamic>> _cachedQuestionsByAnime = {};
  static Map<String, dynamic>? _cachedUserData;

  // Enhanced error handling
  Future<T> _handleRequest<T>(
    Future<http.Response> Function() request,
    T Function(dynamic) onSuccess,
    String errorMessage,
    {int maxRetries = 2}
  ) async {
    int attempts = 0;
    while (attempts <= maxRetries) {
      try {
        final response = await request().timeout(timeout);
        if (response.statusCode >= 200 && response.statusCode < 300) {
          return onSuccess(jsonDecode(response.body));
        } else if (response.statusCode == 401) {
          throw Exception('Sesión expirada. Por favor, inicia sesión nuevamente.');
        } else if (response.statusCode >= 500) {
          if (attempts < maxRetries) {
            attempts++;
            await Future.delayed(Duration(seconds: attempts * 2));
            continue;
          }
          throw Exception('Error del servidor. Inténtalo más tarde.');
        } else {
          final errorData = jsonDecode(response.body);
          final message = errorData['message'] ?? errorMessage;
          throw Exception(message);
        }
      } on SocketException {
        if (attempts < maxRetries) {
          attempts++;
          await Future.delayed(Duration(seconds: attempts));
          continue;
        }
        throw Exception('Sin conexión a internet. Verifica tu conexión.');
      } on TimeoutException {
        if (attempts < maxRetries) {
          attempts++;
          await Future.delayed(Duration(seconds: attempts));
          continue;
        }
        throw Exception('Tiempo de espera agotado. Inténtalo nuevamente.');
      } catch (e) {
        if (e is Exception && e.toString().contains('Sesión expirada')) {
          rethrow;
        }
        throw Exception(errorMessage);
      }
    }
    throw Exception(errorMessage);
  }

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
    _cachedUserData = user;
  }

  Future<Map<String, dynamic>?> getUserData() async {
    if (_cachedUserData != null) return _cachedUserData;
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user_data');
    if (userData != null) {
      _cachedUserData = jsonDecode(userData);
      return _cachedUserData;
    }
    return null;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user_data');
    _cachedAnimes = null;
    _cachedQuestionsByAnime.clear();
    _cachedUserData = null;
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
    // Server docs:
    // - POST /api/auth/register expects application/json and returns { ..., token }
    // - POST /api/users accepts multipart/form-data (useful if uploading photo)

    if (file == null) {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/register'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'cedula': cedula,
              'email': email,
              'password': password,
              if (fullName != null) 'fullName': fullName,
              if (username != null) 'username': username,
              if (phone != null) 'phone': phone,
            }),
          )
          .timeout(timeout);

      if (response.statusCode == 201) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final token = data['token'];
        if (token is String && token.isNotEmpty) {
          await setToken(token);
        }
        await saveUserData(data);
        return data;
      }

      throw Exception(jsonDecode(response.body)['message'] ?? 'Error al registrarse');
    }

    // Photo upload flow: create user via /users then login to obtain token.
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/users'));
    request.fields['cedula'] = cedula;
    request.fields['email'] = email;
    request.fields['password'] = password;
    if (fullName != null) request.fields['fullName'] = fullName;
    if (username != null) request.fields['username'] = username;
    if (phone != null) request.fields['phone'] = phone;
    request.files.add(await http.MultipartFile.fromPath('file', file.path));

    final streamedResponse = await request.send().timeout(timeout);
    final response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode != 201) {
      throw Exception(jsonDecode(response.body)['message'] ?? 'Error al registrarse');
    }

    // Now authenticate to get token.
    return login(email, password);
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

  Future<Map<String, dynamic>> getUserProfile() async {
    final token = await getToken();
    return _handleRequest(
      () => http.get(
        Uri.parse('$baseUrl/users/profile/me'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      ),
      (data) => data as Map<String, dynamic>,
      'Error al obtener el perfil del usuario.',
    );
  }

  Future<List<dynamic>> getQuestions({String? animeId}) async {
    final token = await getToken();

    // Return cached questions if available
    if (animeId != null && _cachedQuestionsByAnime.containsKey(animeId)) {
      return _cachedQuestionsByAnime[animeId]!;
    }

    var uri = Uri.parse('$baseUrl/questions');
    if (animeId != null) {
      uri = uri.replace(queryParameters: {'animeId': animeId});
    }

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (animeId != null) {
        _cachedQuestionsByAnime[animeId] = data;
      }
      return data;
    } else {
      throw Exception('Error al obtener preguntas');
    }
  }
  Future<List<dynamic>> getRandomQuestions(int count) async {
    final token = await getToken();

    final response = await http.get(
      Uri.parse('$baseUrl/questions/random?count=$count'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al obtener preguntas random');
    }
  }
  Future<List<dynamic>> getAnimes() async {
    final token = await getToken();

    if (_cachedAnimes != null) return _cachedAnimes!;

    final response = await http.get(
      Uri.parse('$baseUrl/animes'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      _cachedAnimes = jsonDecode(response.body);
      return _cachedAnimes!;
    } else {
      throw Exception('Error al obtener animes');
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

  // ===== GAME SYSTEM =====
  Future<Map<String, dynamic>> startGame({int questionCount = 10}) async {
    final token = await getToken();
    return _handleRequest(
      () => http.post(
        Uri.parse('$baseUrl/game/start?questions=$questionCount'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      ),
      (data) => data as Map<String, dynamic>,
      'Error al iniciar el juego. Verifica tu conexión.',
    );
  }

  Future<Map<String, dynamic>> answerGameQuestion(String sessionId, String questionId, String answer) async {
    final token = await getToken();
    return _handleRequest(
      () => http.post(
        Uri.parse('$baseUrl/game/answer?sessionId=$sessionId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'questionId': questionId,
          'answer': answer,
        }),
      ),
      (data) => data as Map<String, dynamic>,
      'Error al enviar la respuesta. Inténtalo nuevamente.',
    );
  }

  Future<Map<String, dynamic>> endGame(String sessionId) async {
    final token = await getToken();
    return _handleRequest(
      () => http.post(
        Uri.parse('$baseUrl/game/$sessionId/end'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      ),
      (data) => data as Map<String, dynamic>,
      'Error al finalizar el juego.',
    );
  }

  Future<Map<String, dynamic>> getGameStats() async {
    final token = await getToken();
    return _handleRequest(
      () => http.get(
        Uri.parse('$baseUrl/game/stats'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      ),
      (data) => data as Map<String, dynamic>,
      'Error al obtener estadísticas del juego.',
    );
  }

  // ===== PRODUCTS SYSTEM =====
  Future<List<dynamic>> getProducts() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/products'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al obtener productos');
    }
  }

  Future<Map<String, dynamic>> getProduct(String id) async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/products/$id'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al obtener producto');
    }
  }

  // ===== REDEMPTIONS SYSTEM =====
  /// User redemption history (server docs: GET /api/redemptions/history).
  Future<List<dynamic>> getRedemptions() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/redemptions/history'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al obtener redenciones');
    }
  }

  /// Admin-only: all redemptions (server docs: GET /api/redemptions).
  Future<List<dynamic>> getAllRedemptionsAdmin() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/redemptions'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al obtener redenciones');
    }
  }

  Future<Map<String, dynamic>> createRedemption(
    String productId, {
    int quantity = 1,
    String? notes,
  }) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/redemptions'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'productId': productId,
        'quantity': quantity,
        if (notes != null) 'notes': notes,
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al crear redención');
    }
  }

  // ===== LEADERBOARD SYSTEM =====
  Future<List<dynamic>> getLeaderboard({int limit = 50}) async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/leaderboard?limit=$limit'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al obtener leaderboard');
    }
  }
}
