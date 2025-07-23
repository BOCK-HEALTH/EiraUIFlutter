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
  Future<Map<String, dynamic>> storeTextMessage(String message, {int? sessionId}) async {
  final token = await _getIdToken();
  if (token == null || message.isEmpty) {
    throw Exception("User not authenticated or message is empty");
  }

  // Build the request body, including the session ID
  final Map<String, dynamic> body = {
    'message': message,
    'sessionId': sessionId, // Can be null, which is what we want for a new chat
  };

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