// Mock service for testing without backend
class MockApiService {
  static int _sessionCounter = 1;
  static int _messageCounter = 1;
  
  static Future<Map<String, dynamic>> createSession(String title) async {
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate network delay
    
    return {
      'id': _sessionCounter++,
      'title': title,
      'created_at': DateTime.now().toIso8601String(),
    };
  }
  
  static Future<void> addMessage(int sessionId, String message, String sender) async {
    await Future.delayed(const Duration(milliseconds: 300));
    print('📝 Mock: Added message to session $sessionId: $message');
  }
  
  static Future<List<dynamic>> getSessions() async {
    await Future.delayed(const Duration(milliseconds: 400));
    
    return [
      {
        'id': 1,
        'title': 'Health Consultation',
        'created_at': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      },
      {
        'id': 2,
        'title': 'Medication Questions',
        'created_at': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
      },
    ];
  }
  
  static Future<Map<String, dynamic>> verifyAuth() async {
    await Future.delayed(const Duration(milliseconds: 200));
    
    return {
      'success': true,
      'user': {
        'uid': 'mock-user-123',
        'email': 'test@example.com',
        'displayName': 'Test User',
      },
    };
  }
}
