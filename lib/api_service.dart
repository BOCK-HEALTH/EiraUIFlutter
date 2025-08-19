// lib/api_service.dart (CORRECTED)

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

// --- IMPORTS FOR YOUR CENTRALIZED MODELS ---
import 'package:flutter_application_1/models/chat_session.dart';
import 'package:flutter_application_1/models/chat_message.dart';
import 'package:flutter_application_1/models/platform_file_wrapper.dart';


class ApiService {
  // This is correctly pointing to your new AWS server
  final String _baseUrl = "http://51.20.96.159:8080";
  final Dio _dio = Dio();

  Future<String?> _getIdToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("ApiService Error: User is not authenticated.");
      return null;
    }
    return await user.getIdToken();
  }

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
      PlatformFileWrapper file, {
      int? sessionId,
    }) async {
      final token = await _getIdToken();
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
          '$_baseUrl/api/storeFileMessage',
          data: formData,
          options: Options(
            headers: {'Authorization': 'Bearer $token'},
            sendTimeout: const Duration(seconds: 60),
            receiveTimeout: const Duration(seconds: 60),
          ),
        );
        return response.data;
      } on DioException catch (e) {
        if (e.type == DioExceptionType.connectionError || e.type == DioExceptionType.connectionTimeout) {
            print(
              "Connection Error: Could not connect to the AWS server. " +
              "Please check the device's internet connection and verify the EC2 server is running. " +
              "Also, check the EC2 Security Group rules."
            );
        }
        print("Error storing file message: ${e.response?.data ?? e.message}");
        throw Exception("Failed to send file.");
      }
    }
}