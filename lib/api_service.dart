// lib/api_service.dart (UPDATED WITH getUserInfo METHOD)

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';

// Your model imports (make sure these paths are correct)
import 'package:flutter_application_1/models/chat_session.dart';
import 'package:flutter_application_1/models/chat_message.dart';
import 'package:flutter_application_1/models/platform_file_wrapper.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'dart:html' as html; // For localStorage fallback (web only)

class ApiService {
  // IMPORTANT: Make sure this IP address is correct for your EC2 instance.
  final String _baseUrl = "http://13.61.173.50:8080"; 
  final Dio _dio = Dio();
  final _storage = const FlutterSecureStorage();

  // --- Core Auth Methods ---

  Future<String?> _getJwtToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  Future<void> register({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      await _dio.post(
        '$_baseUrl/api/register',
        data: {
          'email': email,
          'password': password,
          'name': name,
        },
      );
    } on DioException catch (e) {
      final errorMessage = e.response?.data['error'] ?? 'Registration failed.';
      throw Exception(errorMessage);
    }
  }

  Future<void> login({ required String email, required String password }) async {
  try {
    final response = await _dio.post(
      '$_baseUrl/api/login',
      data: { 'email': email, 'password': password },
    );
    
    // Debug log: Print full response (remove in production)
    print('Login Response Status: ${response.statusCode}');
    print('Login Response Body: ${response.data}');
    
    // Safely cast and validate response data
    if (response.statusCode != 200) {
      throw Exception('Login failed: Server returned ${response.statusCode}');
    }
    
    final Map<String, dynamic> data = response.data is Map ? response.data as Map<String, dynamic> : {};
    final String? token = data['token']?.toString();
    final Map<String, dynamic>? user = data['user'] is Map ? data['user'] as Map<String, dynamic>? : null;
    
    print('Extracted token: $token'); // Debug: Check token
    print('Extracted user: $user');   // Debug: Check user
    
    if (token == null || token.isEmpty) {
      // Handle missing/invalid token (e.g., bad creds)
      final errorMsg = data['error'] ?? data['message'] ?? 'Login failed: No valid token received';
      throw Exception(errorMsg);
    }
    
    // Store token using safe helper
    print('Storing token...'); // Debug
    await _safeWrite('jwt_token', token);
    print('Token stored!'); // Debug
    
    // Store user info if present
    if (user != null) {
      print('Storing user info...'); // Debug
      final userJson = jsonEncode(user);
      print('JSON encoded user: $userJson'); // Debug
      await _safeWrite('user_info', userJson);
      
      final name = user['name']?.toString();
      if (name != null && name.isNotEmpty) {
        await _safeWrite('user_name', name);
        print('User name stored: $name'); // Debug
      }
      
      final emailStr = user['email']?.toString();
      if (emailStr != null && emailStr.isNotEmpty) {
        await _safeWrite('user_email', emailStr);
        print('User email stored: $emailStr'); // Debug
      }
    }
    
    print('Login successful: Token and user info stored'); // Debug
  } on DioException catch (e) {
    print('DioException in login: ${e.message}'); // Debug
    final errorMessage = e.response?.data['error'] ?? e.response?.data['message'] ?? 'Login failed.';
    throw Exception(errorMessage.toString());
  } catch (e) {
    print('Unexpected error in login: $e'); // Catch-all debug
    print('Stack trace: ${StackTrace.current}'); // More debug info
    throw Exception('Login failed: $e');
  }
}
  Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');
    await _storage.deleteAll();
  }

  // NEW: Get user information
  Future<Map<String, dynamic>> getUserInfo() async {
    final token = await _getJwtToken();
    if (token == null) throw Exception("User not authenticated");

    try {
      // First try to get user info from the API
      final response = await _dio.get(
        '$_baseUrl/api/user',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
      
      if (response.statusCode == 200 && response.data != null) {
        // Update cached user info
        await _storage.write(key: 'user_info', value: jsonEncode(response.data));
        return response.data;
      } else {
        throw Exception("Invalid response from server");
      }
    } on DioException catch (e) {
      print("API error fetching user info: ${e.response?.data ?? e.message}");
      
      // If API call fails, try to get cached user info
      final cachedUserInfo = await _storage.read(key: 'user_info');
      if (cachedUserInfo != null) {
        return jsonDecode(cachedUserInfo);
      }
      
      // If no cached data, try to get individual stored values
      final userName = await _storage.read(key: 'user_name');
      final userEmail = await _storage.read(key: 'user_email');
      
      if (userName != null || userEmail != null) {
        return {
          'username': userName ?? 'User',
          'email': userEmail ?? 'your.account@email.com',
          'name': userName,
        };
      }
      
      // If everything fails, throw the exception
      throw Exception("Failed to get user information");
    }
  }

// Helper: Safe storage write with web fallback (prevents crashes on HTTP/web)
Future<void> _safeWrite(String key, String value) async {
  try {
    await _storage.write(key: key, value: value);
    print('Secure storage write success: $key'); // Debug
  } catch (e) {
    print('Secure storage failed for $key: $e - Using localStorage fallback'); // Debug
    // Web fallback: Use native localStorage (works on HTTP)
    if (kIsWeb) {
      html.window.localStorage[key] = value;
      print('LocalStorage fallback success: $key'); // Debug
    } else {
      // Non-web: Re-throw (mobile/desktop should use secure storage)
      rethrow;
    }
  }
}
  // --- Data Fetching Methods ---

  Future<List<ChatSession>> fetchSessions() async {
    final token = await _getJwtToken();
    if (token == null) return [];

    try {
      final response = await _dio.get(
        '$_baseUrl/api/sessions',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return (response.data as List).map((json) => ChatSession.fromJson(json)).toList();
    } catch (e) {
      print("Error fetching sessions: $e");
      return [];
    }
  }

  Future<List<ChatMessage>> fetchMessages({required int sessionId}) async {
    final token = await _getJwtToken();
    if (token == null) return [];

    try {
      final response = await _dio.get(
        '$_baseUrl/api/messages',
        queryParameters: {'sessionId': sessionId},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return (response.data as List).map((item) => ChatMessage.fromJson(item)).toList();
    } catch (e) {
      print("Error fetching messages: $e");
      return [];
    }
  }

  // --- Data Mutation Methods ---

  Future<Map<String, dynamic>> storeTextMessage(String message, {int? sessionId, String? title}) async {
    final token = await _getJwtToken();
    if (token == null) throw Exception("User not authenticated");

    try {
      final response = await _dio.post(
        '$_baseUrl/api/messages',
        data: {
          'message': message,
          'sessionId': sessionId,
          'title': title,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );
      return response.data;
    } on DioException catch (e) {
      print("Error storing message: ${e.response?.data ?? e.message}");
      throw Exception("Failed to send message.");
    }
  }

  Future<void> updateSessionTitle(int sessionId, String newTitle) async {
    final token = await _getJwtToken();
    if (token == null) throw Exception("User not authenticated");

    try {
      await _dio.put(
        '$_baseUrl/api/sessions',
        data: {
          'sessionId': sessionId,
          'title': newTitle
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );
    } on DioException catch (e) {
      print('Dio error updating session title: ${e.response?.data ?? e.message}');
      throw Exception('Failed to update session title.');
    }
  }

  Future<void> deleteSession(int sessionId) async {
    final token = await _getJwtToken();
    if (token == null) throw Exception("User not authenticated");

    try {
      await _dio.delete(
        '$_baseUrl/api/sessions',
        data: {'sessionId': sessionId},
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );
    } on DioException catch (e) {
      print('Dio error deleting session: ${e.response?.data ?? e.message}');
      throw Exception('Failed to delete session.');
    }
  }

Future<Map<String, dynamic>> changeUsername({
  required String newName,
}) async {
  final token = await _getJwtToken();
  if (token == null) throw Exception("User not authenticated");

  try {
    final response = await _dio.put(
      '$_baseUrl/api/user/name',
      data: {'newName': newName},
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ),
    );
    
    // --- THIS IS THE FIX ---
    // Check if the response contains a new token and update storage.
    if (response.data['token'] != null) {
      await _storage.write(key: 'jwt_token', value: response.data['token']);
    }
    // ----------------------

    return response.data; // Return the full response data
  } on DioException catch (e) {
    final errorMessage = e.response?.data['error'] ?? 'Failed to change username.';
    throw Exception(errorMessage);
  }
}

Future<void> changePassword({
  required String oldPassword,
  required String newPassword,
}) async {
  final token = await _getJwtToken();
  if (token == null) throw Exception("User not authenticated");

  try {
    await _dio.put(
      '$_baseUrl/api/user/password',
      data: {
        'oldPassword': oldPassword,
        'newPassword': newPassword,
      },
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ),
    );
  } on DioException catch (e) {
    final errorMessage = e.response?.data['error'] ?? 'Failed to change password.';
    throw Exception(errorMessage);
  }
}

  Future<Map<String, dynamic>> storeFileMessage(
      String message,
      PlatformFileWrapper file, {
      int? sessionId,
    }) async {
      final token = await _getJwtToken();
      if (token == null) throw Exception("User not authenticated");

      final String fileName = file.name;
      MultipartFile multipartFile;

      if (file.bytes != null) {
        final String mimeType = lookupMimeType(fileName, headerBytes: file.bytes) ?? 'application/octet-stream';
        multipartFile = MultipartFile.fromBytes(
          file.bytes!,
          filename: fileName,
          contentType: MediaType.parse(mimeType),
        );
      } else if (file.path != null) {
        final String mimeType = lookupMimeType(file.path!) ?? 'application/octet-stream';
        multipartFile = await MultipartFile.fromFile(
          file.path!,
          filename: fileName,
          contentType: MediaType.parse(mimeType),
        );
      } else {
        throw Exception("Invalid file provided. No bytes or path.");
      }

      final Map<String, dynamic> formDataMap = {
        'message': message,
        'file': multipartFile,
      };

      if (sessionId != null) {
        formDataMap['sessionId'] = sessionId;
      }

      FormData formData = FormData.fromMap(formDataMap);

      try {
        final response = await _dio.post(
          '$_baseUrl/api/file-messages',
          data: formData,
          options: Options(
            headers: {'Authorization': 'Bearer $token'},
            sendTimeout: const Duration(seconds: 60),
            receiveTimeout: const Duration(seconds: 60),
          ),
        );
        return response.data;
      } on DioException catch (e) {
        print("Error storing file message: ${e.response?.data ?? e.message}");
        throw Exception("Failed to send file.");
      }
    }
}
