import 'package:flutter_application_1/models/platform_file_wrapper.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final List<PlatformFileWrapper>? attachments;
  final DateTime timestamp;
  final String? fileUrl;
  final String? fileType;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.attachments,
    DateTime? timestamp,
    this.fileUrl,
    this.fileType,
  }) : timestamp = timestamp ?? DateTime.now();

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final fileUrlData = json['file_url'];
    final fileTypeData = json['file_type'];

    return ChatMessage(
      text: json['message'] ?? '',
      isUser: json['sender'] == 'user',
      timestamp: DateTime.parse(json['created_at']),
      fileUrl: (fileUrlData is List && fileUrlData.isNotEmpty)
          ? fileUrlData[0] as String?
          : null,
      fileType: (fileTypeData is List && fileTypeData.isNotEmpty)
          ? fileTypeData[0] as String?
          : null,
    );
  }
}