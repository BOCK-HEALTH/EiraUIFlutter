import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/main.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'dart:io';
import 'dart:typed_data'; // For Uint8List

class ChatSession {
  final int id;
  final String title;
  final DateTime createdAt;

  ChatSession({required this.id, required this.title, required this.createdAt});

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(
      id: json['id'],
      title: json['title'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class ApiService {
  final String _baseUrl = "https://eira-backend-mu.vercel.app";
  final Dio _dio = Dio();

  Future<String?> _getIdToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("ApiService Error: User is not authenticated.");
      return null;
    }
    return await user.getIdToken();
  }

  // --- FINAL CORRECTED VERSION ---
  Future<void> updateSessionTitle(int sessionId, String newTitle) async {
    try {
      final token = await _getIdToken();
      if (token == null) throw Exception("User not authenticated");

      print('Attempting to update session $sessionId with title: "$newTitle"');
      
      final response = await _dio.put(
        '$_baseUrl/api/updateSession',
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
      
      print('Update response: ${response.statusCode}');
    } on DioException catch (e) {
      print('Dio error updating session title: ${e.response?.statusCode}');
      print('Error response data: ${e.response?.data}');
      throw Exception('Failed to update session title.');
    }
  }

  // --- FINAL CORRECTED VERSION ---
  Future<void> deleteSession(int sessionId) async {
    try {
      final token = await _getIdToken();
      if (token == null) throw Exception("User not authenticated");

      print('Attempting to delete session $sessionId');
      
      final response = await _dio.delete(
        '$_baseUrl/api/deleteSession',
        data: {'sessionId': sessionId},
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );
      
      print('Delete response: ${response.statusCode}');
    } on DioException catch (e) {
      print('Dio error deleting session: ${e.response?.statusCode}');
      print('Error response data: ${e.response?.data}');
      throw Exception('Failed to delete session.');
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
        return data.map((json) => ChatSession.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print("Error fetching sessions: $e");
      return [];
    }
  }

  Future<List<ChatMessage>> fetchMessages({int? sessionId}) async {
    final token = await _getIdToken();
    if (token == null) return [];

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
      }
      return [];
    } catch (e) {
      print("Error fetching messages: $e");
      return [];
    }
  }

  Future<Map<String, dynamic>> storeTextMessage(String message, {int? sessionId, String? title}) async {
    final token = await _getIdToken();
    if (token == null) throw Exception("User not authenticated");

    final Map<String, dynamic> body = {
      'message': message,
      'sessionId': sessionId,
    };
    if (sessionId == null && title != null) {
      body['title'] = title;
    }

    try {
      final response = await _dio.post(
        '$_baseUrl/api/storeMessage',
        data: jsonEncode(body),
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );
      return response.data;
    } catch (e) {
      print("Error storing message: $e");
      throw Exception("Failed to send message.");
    }
  }

  Future<Map<String, dynamic>> storeFileMessage(
    String message,
    PlatformFileWrapper file, { // Accepts the new wrapper class
    int? sessionId,
  }) async {
    final token = await _getIdToken();
    if (token == null) throw Exception("User not authenticated");

    final String fileName = file.name;
    final String? mimeType = lookupMimeType(fileName, headerBytes: file.bytes);

    MultipartFile multipartFile;

    // Intellgently create the MultipartFile from either bytes (web) or path (mobile)
    if (file.bytes != null) {
      // This is a web file
      multipartFile = MultipartFile.fromBytes(
        file.bytes!,
        filename: fileName,
        contentType: mimeType != null ? MediaType.parse(mimeType) : null,
      );
    } else if (file.path != null) {
      // This is a mobile/desktop file
      multipartFile = await MultipartFile.fromFile(
        file.path!,
        filename: fileName,
        contentType: mimeType != null ? MediaType.parse(mimeType) : null,
      );
    } else {
      throw Exception("Invalid file provided. No bytes or path.");
    }

    final Map<String, dynamic> formDataMap = {
      'message': message,
      'file': multipartFile,
    };

    if (sessionId != null) {
      formDataMap['sessionId'] = sessionId.toString();
    }

    FormData formData = FormData.fromMap(formDataMap);

    try {
      final response = await _dio.post(
        '$_baseUrl/api/storeFileMessage',
        data: formData,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
      return response.data;
    } on DioException catch (e) {
      print("Error storing file message: ${e.response?.data ?? e.message}");
      throw Exception("Failed to send file.");
    }
  }
}
