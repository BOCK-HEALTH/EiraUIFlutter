// lib/api_service.dart
import 'dart:convert';
import 'package:dio/dio.dart'; // Using Dio as it's already in your project
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/main.dart'; // To access ChatMessage
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'dart:io';

// At the top of lib/api_service.dart
class ChatSession {
  final int id;
  final String title;
  final DateTime createdAt;

  ChatSession({required this.id, required this.title, required this.createdAt});

  // Factory constructor to create a ChatSession from JSON
  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(
      id: json['id'],
      title: json['title'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class ApiService {
  // !!! PASTE YOUR VERCEL URL HERE !!!
  final String _baseUrl = "https://eira-backend-mu.vercel.app";
  final Dio _dio = Dio();

  // Helper function to get the current user's token
  Future<String?> _getIdToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("ApiService Error: User is not authenticated.");
      return null;
    }
    return await user.getIdToken();
  }

  // --- MODIFIED: Corrected the endpoint and data payload ---
  Future<void> updateSessionTitle(int sessionId, String newTitle) async {
    try {
      final token = await _getIdToken();
      if (token == null) {
        throw Exception("User not authenticated");
      }

      print('Attempting to update session $sessionId with title: "$newTitle"');
      
      // The endpoint likely follows the pattern of your other APIs (e.g., /api/updateSession)
      // We also send the sessionId in the body of the request.
      final response = await _dio.put(
        '$_baseUrl/api/updateSession', // CORRECTED ENDPOINT
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
      
      print('Session $sessionId title updated to "$newTitle"');
      print('Update response: ${response.statusCode}');
    } on DioException catch (e) {
      print('Dio error updating session title: ${e.response?.statusCode}');
      print('Error response data: ${e.response?.data}');
      throw Exception('Failed to update session title.');
    } catch (e) {
      print('Unknown error updating session title: $e');
      throw Exception('An unknown error occurred.');
    }
  }

  /// Deletes a specific session.
  // --- MODIFIED: Corrected the endpoint and data payload ---
  Future<void> deleteSession(int sessionId) async {
    try {
      final token = await _getIdToken();
      if (token == null) {
        throw Exception("User not authenticated");
      }

      print('Attempting to delete session $sessionId');
      
      // The endpoint likely follows the pattern of your other APIs (e.g., /api/deleteSession)
      // We are sending the sessionId in the request body.
      final response = await _dio.delete(
        '$_baseUrl/api/deleteSession', // CORRECTED ENDPOINT
        data: { 'sessionId': sessionId }, // Pass the ID in the body
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json', // Required for sending data
          },
        ),
      );
      
      print('Session $sessionId deleted successfully');
      print('Delete response: ${response.statusCode}');
    } on DioException catch (e) {
      print('Dio error deleting session: ${e.response?.statusCode}');
      print('Error response data: ${e.response?.data}');
      throw Exception('Failed to delete session.');
    } catch (e) {
      print('Unknown error deleting session: $e');
      throw Exception('An unknown error occurred.');
    }
  }

  Future<List<ChatSession>> fetchSessions() async {
    final token = await _getIdToken();
    if (token == null) return [];

    try {
      final response = await _dio.get(
        '$_baseUrl/api/getSessions',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        // Convert the JSON list to a list of ChatSession objects
        return data.map((json) => ChatSession.fromJson(json)).toList();
      } else {
        return [];
      }
    } on DioException catch (e) {
      print("Error fetching sessions: $e");
      return [];
    }
  }

  // Method to fetch all messages from the backend
  // In lib/api_service.dart
  Future<List<ChatMessage>> fetchMessages({int? sessionId}) async {
    final token = await _getIdToken();
    if (token == null) return [];

    // Build the URL. If a sessionId is provided, add it as a query parameter.
    String url = '$_baseUrl/api/getMessages';
    if (sessionId != null) {
      url += '?sessionId=$sessionId';
    }

    try {
      final response = await _dio.get(
        url,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((item) => ChatMessage.fromJson(item)).toList();
      } else {
        return [];
      }
    } on DioException catch (e) {
      print("Error fetching messages: $e");
      return [];
    }
  }

  // Method to store a new text message
  // MODIFIED: Added optional 'title' parameter to set the title on creation
  Future<Map<String, dynamic>> storeTextMessage(String message, {int? sessionId, String? title}) async {
    final token = await _getIdToken();
    if (token == null || message.isEmpty) {
      throw Exception("User not authenticated or message is empty");
    }

    // Build the request body, including the session ID and optional title
    final Map<String, dynamic> body = {
      'message': message,
      'sessionId': sessionId,
    };
    
    // If a title is provided (for a new session), add it to the body
    if (sessionId == null && title != null) {
      body['title'] = title;
    }

    try {
      final response = await _dio.post(
        '$_baseUrl/api/storeMessage',
        data: jsonEncode(body), // Send the new body
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );
      return response.data;
    } on DioException catch (e) {
      print("Error storing message: $e");
      throw Exception("Failed to send message.");
    }
  }

  // In lib/api_service.dart
  Future<Map<String, dynamic>> storeFileMessage(String message, File file, {int? sessionId}) async {
    final token = await _getIdToken();
    if (token == null) throw Exception("User not authenticated");

    String fileName = file.path.split('/').last;
    
    // Create a map to hold form data
    final Map<String, dynamic> formDataMap = {
      'message': message,
      'file': await MultipartFile.fromFile(
        file.path,
        filename: fileName,
        contentType: MediaType.parse(lookupMimeType(file.path) ?? 'application/octet-stream'),
      ),
    };

    // Only add sessionId to the form if it's not null
    if (sessionId != null) {
      formDataMap['sessionId'] = sessionId.toString();
    }

    FormData formData = FormData.fromMap(formDataMap);

    try {
      final response = await _dio.post(
        '$_baseUrl/api/storeFileMessage',
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      // Return the server's response
      return response.data;
    } on DioException catch (e) {
      print("Error storing file message: $e");
      throw Exception("Failed to send file.");
    }
  }
}