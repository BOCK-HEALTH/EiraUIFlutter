import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class ApiService {
  // This baseUrl remains the same.
  static const String baseUrl = 'https://eirabackend-nfgcausex-mohammadoweisis23-6585s-projects.vercel.app/';

  static Future<String?> _getAuthToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return await user.getIdToken();
    }
    return null;
  }

  static Future<Map<String, String>> _getHeaders() async {
    final token = await _getAuthToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // --- Auth endpoints ---
  static Future<Map<String, dynamic>> verifyAuth() async {
    try {
      final token = await _getAuthToken();
      if (token == null) throw Exception('No auth token available');

      // UPDATED: URL changed from /auth/verify to /auth
      final response = await http.post(
        Uri.parse('$baseUrl/auth'),
        headers: await _getHeaders(),
        body: jsonEncode({'idToken': token}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to verify auth: ${response.body}');
      }
    } catch (e) {
      throw Exception('Auth verification failed: $e');
    }
  }

  // --- Session endpoints ---
  static Future<Map<String, dynamic>> createSession(String title) async {
    try {
      // UPDATED: URL changed from /sessions/create to /sessions
      final response = await http.post(
        Uri.parse('$baseUrl/sessions'),
        headers: await _getHeaders(),
        body: jsonEncode({'title': title}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to create session: ${response.body}');
      }
    } catch (e) {
      throw Exception('Create session failed: $e');
    }
  }

  static Future<List<dynamic>> getSessions() async {
    try {
      // UPDATED: URL changed from /sessions/list to /sessions
      final response = await http.get(
        Uri.parse('$baseUrl/sessions'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get sessions: ${response.body}');
      }
    } catch (e) {
      throw Exception('Get sessions failed: $e');
    }
  }

  static Future<void> renameSession(int sessionId, String newTitle) async {
    try {
      // UPDATED: URL changed from /sessions/rename to /sessions
      final response = await http.put(
        Uri.parse('$baseUrl/sessions'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'sessionId': sessionId,
          'newTitle': newTitle,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to rename session: ${response.body}');
      }
    } catch (e) {
      throw Exception('Rename session failed: $e');
    }
  }

  static Future<void> deleteSession(int sessionId) async {
    try {
      // UPDATED: The URL path is now /sessions, and the ID is passed as a query parameter.
      final uri = Uri.parse('$baseUrl/sessions').replace(queryParameters: {
        'sessionId': sessionId.toString(),
      });

      final response = await http.delete(
        uri,
        headers: await _getHeaders(),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete session: ${response.body}');
      }
    } catch (e) {
      throw Exception('Delete session failed: $e');
    }
  }

  // --- Chat endpoints ---
  static Future<void> addMessage(int sessionId, String message, String sender) async {
    try {
      // UPDATED: URL changed from /chat/add to /chat
      final response = await http.post(
        Uri.parse('$baseUrl/chat'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'session_id': sessionId,
          'message': message,
          'sender': sender,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to add message: ${response.body}');
      }
    } catch (e) {
      throw Exception('Add message failed: $e');
    }
  }

  static Future<List<dynamic>> getChatHistory(int sessionId) async {
    try {
      // UPDATED: URL changed from /chat/history to /chat, but the query param logic remains the same.
      final uri = Uri.parse('$baseUrl/chat').replace(queryParameters: {
        'session_id': sessionId.toString(),
      });

      final response = await http.get(
        uri,
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get chat history: ${response.body}');
      }
    } catch (e) {
      throw Exception('Get chat history failed: $e');
    }
  }

  // --- User endpoints ---
  static Future<Map<String, dynamic>> getUser() async {
    try {
      // UPDATED: URL changed from /users/get-user to /users
      final response = await http.get(
        Uri.parse('$baseUrl/users'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get user: ${response.body}');
      }
    } catch (e) {
      throw Exception('Get user failed: $e');
    }
  }

  static Future<Map<String, dynamic>> getOrCreateUser(String name) async {
    try {
      // UPDATED: URL changed from /users/get-or-create to /users
      final response = await http.post(
        Uri.parse('$baseUrl/users'),
        headers: await _getHeaders(),
        body: jsonEncode({'name': name}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get or create user: ${response.body}');
      }
    } catch (e) {
      throw Exception('Get or create user failed: $e');
    }
  }

  // NOTE: There was no update name logic in the consolidated backend.
  // Assuming it's a PUT request to /users based on standard practice.
  // Make sure your users.js file can handle a PUT request.
  static Future<void> updateUserName(String name) async {
    try {
      // UPDATED: URL changed from /users/update-name to /users
      final response = await http.put(
        Uri.parse('$baseUrl/users'),
        headers: await _getHeaders(),
        body: jsonEncode({'name': name}),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update user name: ${response.body}');
      }
    } catch (e) {
      throw Exception('Update user name failed: $e');
    }
  }
}