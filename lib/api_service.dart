// lib/api_service.dart

import 'dart:convert';
import 'package:dio/dio.dart'; // Using Dio as it's already in your project
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/main.dart'; // To access ChatMessage

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

  // Method to fetch all messages from the backend
  // In lib/api_service.dart

Future<List<ChatMessage>> fetchMessages() async {
  final token = await _getIdToken();
  if (token == null) return [];

  try {
    final response = await _dio.get(
      '$_baseUrl/api/getMessages',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = response.data;
      return data.map((item) => ChatMessage(
        text: item['message'] ?? '',
        // Use the 'sender' column to determine who sent the message
        isUser: item['sender'] == 'user',
        timestamp: DateTime.parse(item['created_at']),
        // Map the new file columns
        fileUrl: item['file_url'],
        fileType: item['file_type'],
      )).toList();
    } else {
      return [];
    }
  } on DioException catch (e) {
    print("Error fetching messages: $e");
    return [];
  }
}

  // Method to store a new text message
  Future<void> storeTextMessage(String message) async {
    final token = await _getIdToken();
    if (token == null || message.isEmpty) return;

    try {
      await _dio.post(
        '$_baseUrl/api/storeMessage',
        data: jsonEncode({'message': message}),
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );
    } on DioException catch (e) {
      print("Error storing message: $e");
      // Re-throw the exception so the UI can handle it
      throw Exception("Failed to send message.");
    }
  }
}