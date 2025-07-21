import 'package:flutter/material.dart';
import 'package:flutter_application_1/config/app_config.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DebugPanel extends StatelessWidget {
  const DebugPanel({super.key});

  @override
  Widget build(BuildContext context) {
    if (!AppConfig.enableDebugLogs) return const SizedBox.shrink();
    
    final user = FirebaseAuth.instance.currentUser;
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '🐛 DEBUG INFO',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          _buildDebugRow('Backend URL:', AppConfig.backendUrl),
          _buildDebugRow('Backend Configured:', AppConfig.isBackendConfigured.toString()),
          _buildDebugRow('User Email:', user?.email ?? 'Not logged in'),
          _buildDebugRow('User UID:', user?.uid ?? 'N/A'),
          _buildDebugRow('Mock Mode:', AppConfig.enableMockMode.toString()),
        ],
      ),
    );
  }
  
  Widget _buildDebugRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 10,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
