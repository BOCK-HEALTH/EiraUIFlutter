import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:math' as math;
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:camera/camera.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:dio/dio.dart';
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';

// --- THEME AND STYLING ---
const Color kEiraYellow = Color(0xFFFDB821);
const Color kEiraYellowLight = Color(0xFFFFF8E6);
const Color kEiraYellowHover = Color(0xFFE6A109);
const Color kEiraText = Color(0xFF343541);
const Color kEiraTextSecondary = Color(0xFF6E6E80);
const Color kEiraBackground = Color(0xFFFFFFFF);
const Color kEiraSidebarBg = Color(0xFFF7F7F8);
const Color kEiraBorder = Color(0xFFE5E5E5);
const Color kEiraUserBg = Color(0xFFF7F7F8);
const double kSidebarWidth = 280.0;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const EiraApp());
}

class EiraApp extends StatelessWidget {
  const EiraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Eira Mobile',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Inter',
        scaffoldBackgroundColor: kEiraBackground,
        primaryColor: kEiraYellow,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: kEiraText),
          bodyMedium: TextStyle(color: kEiraText),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: kEiraBackground,
          elevation: 0,
          iconTheme: IconThemeData(color: kEiraText),
          titleTextStyle: TextStyle(
            color: kEiraText,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            fontFamily: 'Inter',
          ),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

// Message model to handle different types of content
class ChatMessage {
  final String text;
  final bool isUser;
  final List<File>? attachments;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.attachments,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _hasActiveChat = false;
  
  // Chat messages
  final List<ChatMessage> _messages = [];
  
  // Audio recording
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _recognizedText = '';
  FlutterSoundRecorder? _audioRecorder;
  bool _isRecordingAudio = false;
  String? _audioPath;
  
  // Video recording
  CameraController? _cameraController;
  Future<void>? _initializeCameraFuture;
  bool _isRecordingVideo = false;
  String? _videoPath;
  bool _isCameraInitialized = false;
  
  // File handling
  final List<File> _selectedFiles = [];
  final ImagePicker _picker = ImagePicker();
  final Dio _dio = Dio();
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initializeSpeech();
    _initAudioRecorder();
    _initializeCamera();
  }

  void _initializeSpeech() async {
    try {
      bool available = await _speech.initialize(
        onStatus: (val) => print('Speech status: $val'),
        onError: (val) => print('Speech error: $val'),
      );
      if (available) {
        print('Speech recognition initialized successfully');
      } else {
        print('Speech recognition not available');
      }
    } catch (e) {
      print('Error initializing speech: $e');
    }
  }

  Future<void> _initAudioRecorder() async {
    try {
      _audioRecorder = FlutterSoundRecorder();
      await _audioRecorder!.openRecorder();
      print('Audio recorder initialized successfully');
    } catch (e) {
      print('Error initializing audio recorder: $e');
      _showErrorDialog('Failed to initialize audio recorder: $e');
    }
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        final firstCamera = cameras.first;
        
        _cameraController = CameraController(
          firstCamera,
          ResolutionPreset.medium,
        );
        
        _initializeCameraFuture = _cameraController!.initialize().then((_) {
          if (mounted) {
            setState(() {
              _isCameraInitialized = true;
            });
            print('Camera initialized successfully');
          }
        });
      }
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }

  void _startNewChat() {
    setState(() {
      _hasActiveChat = true;
      _selectedFiles.clear();
      _recognizedText = '';
      _textController.clear();
      _messages.clear();
    });
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.microphone,
      Permission.camera,
      Permission.storage,
    ].request();
    
    statuses.forEach((permission, status) {
      if (status != PermissionStatus.granted) {
        print('$permission permission denied');
      }
    });
  }

  Future<void> _startAudioRecording() async {
    try {
      await _requestPermissions();
      
      final status = await Permission.microphone.status;
      if (status != PermissionStatus.granted) {
        _showPermissionDeniedDialog('Microphone');
        return;
      }

      if (_audioRecorder == null) {
        await _initAudioRecorder();
      }

      final tempDir = await getTemporaryDirectory();
      final fileName = 'audio_${DateTime.now().millisecondsSinceEpoch}.aac';
      final filePath = '${tempDir.path}/$fileName';
      
      await _audioRecorder!.startRecorder(
        toFile: filePath,
        codec: Codec.aacADTS,
      );
      
      setState(() {
        _isRecordingAudio = true;
        _audioPath = filePath;
        _recognizedText = '';
      });

      // Start speech recognition
      if (_speech.isAvailable) {
        await _speech.listen(
          onResult: (result) {
            setState(() {
              _recognizedText = result.recognizedWords;
              _textController.text = _recognizedText;
            });
          },
          listenFor: const Duration(minutes: 5),
          pauseFor: const Duration(seconds: 3),
        );
      }

      _showSnackBar('Recording started...', Colors.green);
    } catch (e) {
      print('Error starting audio recording: $e');
      _showErrorDialog('Failed to start audio recording: $e');
    }
  }

  Future<void> _stopAudioRecording() async {
    try {
      if (_speech.isListening) {
        await _speech.stop();
      }
      
      if (_audioRecorder != null && _isRecordingAudio) {
        String? recordedPath = await _audioRecorder!.stopRecorder();
        
        setState(() {
          _isRecordingAudio = false;
        });
        
        if (recordedPath != null && File(recordedPath).existsSync()) {
          final file = File(recordedPath);
          setState(() {
            _selectedFiles.add(file);
          });
          
          _showSnackBar('Audio recorded successfully!', Colors.green);
          
          // Add message with audio attachment
          if (_recognizedText.isNotEmpty || _selectedFiles.isNotEmpty) {
            _addMessage(_recognizedText.isEmpty ? "Audio message" : _recognizedText, true, [file]);
          }
        }
      }
    } catch (e) {
      print('Error stopping audio recording: $e');
      _showErrorDialog('Failed to stop audio recording: $e');
    }
  }

  Future<void> _startVideoRecording() async {
    try {
      await _requestPermissions();
      
      final status = await Permission.camera.status;
      if (status != PermissionStatus.granted) {
        _showPermissionDeniedDialog('Camera');
        return;
      }

      if (_cameraController == null || !_isCameraInitialized) {
        await _initializeCamera();
        if (_initializeCameraFuture != null) {
          await _initializeCameraFuture!;
        }
      }

      if (_cameraController != null && _cameraController!.value.isInitialized) {
        await _cameraController!.startVideoRecording();
        
        setState(() {
          _isRecordingVideo = true;
        });
        
        _showSnackBar('Video recording started...', Colors.green);
      } else {
        _showErrorDialog('Camera not initialized');
      }
    } catch (e) {
      print('Error starting video recording: $e');
      _showErrorDialog('Failed to start video recording: $e');
    }
  }

  Future<void> _stopVideoRecording() async {
    try {
      if (_cameraController != null && _isRecordingVideo) {
        final file = await _cameraController!.stopVideoRecording();
        
        setState(() {
          _isRecordingVideo = false;
        });
        
        final savedFile = File(file.path);
        if (savedFile.existsSync()) {
          setState(() {
            _selectedFiles.add(savedFile);
          });
          
          _showSnackBar('Video recorded successfully!', Colors.green);
          
          // Add message with video attachment
          _addMessage("Video message", true, [savedFile]);
        }
      }
    } catch (e) {
      print('Error stopping video recording: $e');
      _showErrorDialog('Failed to stop video recording: $e');
    }
  }

  Future<void> _pickFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'mp4', 'mp3', 'aac', 'wav', 'mov'],
        allowMultiple: true,
      );
      
      if (result != null) {
        List<File> files = result.paths
            .where((path) => path != null)
            .map((path) => File(path!))
            .where((file) => file.existsSync())
            .toList();
        
        if (files.isNotEmpty) {
          setState(() {
            _selectedFiles.addAll(files);
          });
          
          _showSnackBar('${files.length} file(s) selected', Colors.green);
          
          // Add message with file attachments
          String fileNames = files.map((f) => path.basename(f.path)).join(', ');
          _addMessage("Uploaded files: $fileNames", true, files);
        }
      }
    } catch (e) {
      print('Error picking files: $e');
      _showErrorDialog('Failed to pick files: $e');
    }
  }

  void _addMessage(String text, bool isUser, [List<File>? attachments]) {
    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: isUser,
        attachments: attachments,
      ));
    });
  }

  String _getFileType(String path) {
    final extension = path.split('.').last.toLowerCase();
    if (['pdf'].contains(extension)) return 'document';
    if (['jpg', 'jpeg', 'png'].contains(extension)) return 'image';
    if (['mp4', 'mov'].contains(extension)) return 'video';
    if (['mp3', 'aac', 'wav'].contains(extension)) return 'audio';
    return 'file';
  }

  Future<void> _toggleRecording() async {
    if (_isRecordingAudio) {
      await _stopAudioRecording();
    } else {
      await _startAudioRecording();
    }
  }

  Future<void> _toggleVideoRecording() async {
    if (_isRecordingVideo) {
      await _stopVideoRecording();
    } else {
      await _startVideoRecording();
    }
  }

  void _sendMessage() {
    if (_textController.text.trim().isNotEmpty || _selectedFiles.isNotEmpty) {
      String messageText = _textController.text.trim();
      List<File> attachments = List.from(_selectedFiles);
      
      _addMessage(
        messageText.isEmpty ? "Files shared" : messageText, 
        true, 
        attachments.isNotEmpty ? attachments : null
      );
      
      setState(() {
        _textController.clear();
        _selectedFiles.clear();
        _recognizedText = '';
      });
      
      // Simulate AI response
      Future.delayed(const Duration(seconds: 1), () {
        _addMessage("Thank you for your message. How can I help you with your health concerns?", false);
      });
    }
  }

  void _showPermissionDeniedDialog(String permission) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('$permission Permission Required'),
          content: Text('Please grant $permission permission to use this feature.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              child: const Text('Settings'),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _audioRecorder?.closeRecorder();
    _cameraController?.dispose();
    _dio.close();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: null,
        backgroundColor: kEiraBackground,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: kEiraYellow,
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            icon: const Icon(Icons.menu, color: Colors.white, size: 20),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: kEiraYellow,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.person, color: Colors.white, size: 16),
                const SizedBox(width: 4),
                Text("0", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
      drawer: AppDrawer(onNewSession: _startNewChat),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 140.0),
            child: _hasActiveChat
                ? MessagesListView(messages: _messages)
                : WelcomeView(onCapabilityTap: _startNewChat),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ChatInputArea(
              isRecordingAudio: _isRecordingAudio,
              isRecordingVideo: _isRecordingVideo,
              uploadedFiles: _selectedFiles,
              recognizedText: _recognizedText,
              textController: _textController,
              onRecordToggle: _toggleRecording,
              onFileAdd: _pickFiles,
              onCameraOpen: _toggleVideoRecording,
              onFileRemove: (index) => setState(() => _selectedFiles.removeAt(index)),
              onSendMessage: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}

class AppDrawer extends StatelessWidget {
  final VoidCallback onNewSession;
  const AppDrawer({super.key, required this.onNewSession});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: kEiraSidebarBg,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: kEiraYellow,
                    radius: 20,
                    child: const Text("O", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Owaiz", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                      Text("123@gmail.com", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ElevatedButton.icon(
                onPressed: onNewSession,
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text("New Session", style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kEiraYellow,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text("Recent Sessions", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              ),
            ),
            
            const SizedBox(height: 10),
            
            ListTile(
              title: const Text("test2", style: TextStyle(fontSize: 14)),
              subtitle: const Text("4 days ago", style: TextStyle(fontSize: 12)),
              onTap: () {},
            ),
            ListTile(
              title: const Text("test", style: TextStyle(fontSize: 14)),
              subtitle: const Text("6/5/2025", style: TextStyle(fontSize: 12)),
              onTap: () {},
            ),
            
            const Spacer(),
            
            const Divider(color: kEiraBorder),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text("Logout", style: TextStyle(color: Colors.red)),
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}

class WelcomeView extends StatelessWidget {
  final VoidCallback onCapabilityTap;
  const WelcomeView({super.key, required this.onCapabilityTap});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 40.0),
      child: Column(
        children: [
          const SizedBox(height: 60),
          
          // Eira title with icon
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: kEiraYellow,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.auto_awesome, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              const Text(
                "Eira",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                  color: kEiraText,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          const Text(
            "Eira - Your AI Health Assistant",
            style: TextStyle(
              fontSize: 16,
              color: kEiraTextSecondary,
              fontWeight: FontWeight.w400,
            ),
          ),
          
          const SizedBox(height: 60),
          
          // Capability cards in vertical layout
          Column(
            children: [
              CapabilityCard(
                icon: '🏥',
                title: 'Medical Assistance',
                description: 'Get reliable medical information and health guidance',
                onTap: onCapabilityTap,
              ),
              const SizedBox(height: 16),
              CapabilityCard(
                icon: '💊',
                title: 'Medication Info',
                description: 'Learn about medications, dosages, and potential interactions',
                onTap: onCapabilityTap,
              ),
              const SizedBox(height: 16),
              CapabilityCard(
                icon: '🧬',
                title: 'Health Analysis',
                description: 'Understand symptoms and get personalized health insights',
                onTap: onCapabilityTap,
              ),
            ],
          ),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class CapabilityCard extends StatelessWidget {
  final String icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const CapabilityCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: kEiraBackground,
          border: Border.all(color: kEiraBorder.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: kEiraYellow.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  icon,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: kEiraText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: kEiraTextSecondary,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MessagesListView extends StatelessWidget {
  final List<ChatMessage> messages;
  
  const MessagesListView({super.key, required this.messages});

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) {
      return const Center(
        child: Text(
          'Start a conversation...',
          style: TextStyle(
            color: kEiraTextSecondary,
            fontSize: 16,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        return MessageBubble(
          isUser: message.isUser,
          text: message.text,
          attachments: message.attachments,
          timestamp: message.timestamp,
        );
      },
    );
  }
}

class MessageBubble extends StatelessWidget {
  final bool isUser;
  final String text;
  final List<File>? attachments;
  final DateTime timestamp;

  const MessageBubble({
    super.key, 
    required this.isUser, 
    required this.text, 
    this.attachments,
    required this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      decoration: BoxDecoration(
        color: isUser ? kEiraUserBg : kEiraBackground,
        border: const Border(bottom: BorderSide(color: kEiraBorder)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: isUser ? kEiraText : kEiraYellow,
            child: isUser
                ? const Text("U", style: TextStyle(color: Colors.white))
                : const Icon(Icons.health_and_safety, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      isUser ? "You" : "Eira 0.1",
                      style: TextStyle(
                        fontWeight: FontWeight.bold, 
                        color: isUser ? kEiraText : kEiraYellowHover
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatTime(timestamp),
                      style: const TextStyle(
                        fontSize: 12,
                        color: kEiraTextSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (text.isNotEmpty)
                  Text(text, style: const TextStyle(height: 1.5)),
                if (attachments != null && attachments!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  ...attachments!.map((file) => AttachmentChip(file: file)),
                ],
              ],
            ),
          )
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
  }
}

class AttachmentChip extends StatelessWidget {
  final File file;
  const AttachmentChip({super.key, required this.file});

  @override
  Widget build(BuildContext context) {
    final fileName = path.basename(file.path);
    final fileSize = _formatFileSize(file.lengthSync());
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: InkWell(
        onTap: () => _openFile(context, file),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_getFileIcon(file.path), color: kEiraYellowHover, size: 18),
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fileName, 
                      style: const TextStyle(fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      fileSize,
                      style: const TextStyle(
                        fontSize: 12,
                        color: kEiraTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openFile(BuildContext context, File file) {
    // TODO: Implement file viewer based on file type
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening ${path.basename(file.path)}')),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  IconData _getFileIcon(String path) {
    final extension = path.split('.').last.toLowerCase();
    if (['pdf'].contains(extension)) return Icons.picture_as_pdf;
    if (['jpg', 'jpeg', 'png'].contains(extension)) return Icons.image;
    if (['mp4', 'mov'].contains(extension)) return Icons.videocam;
    if (['mp3', 'aac', 'wav'].contains(extension)) return Icons.audiotrack;
    return Icons.insert_drive_file;
  }
}

class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: kEiraYellow,
          child: const Icon(Icons.health_and_safety, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(20)),
          child: Row(
            children: List.generate(3, (index) {
              return AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  final double t = ((_controller.value + (index * 0.2)) % 1.0);
                  final double scale = 1.0 - (4.0 * math.pow(t - 0.5, 2));
                  return Transform.scale(scale: scale, child: child);
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  child: CircleAvatar(radius: 4, backgroundColor: Colors.grey.shade500),
                ),
              );
            }),
          ),
        )
      ],
    );
  }
}

class ChatInputArea extends StatefulWidget {
  final bool isRecordingAudio;
  final bool isRecordingVideo;
  final List<File> uploadedFiles;
  final String recognizedText;
  final TextEditingController textController;
  final VoidCallback onRecordToggle;
  final VoidCallback onFileAdd;
  final VoidCallback onCameraOpen;
  final Function(int) onFileRemove;
  final VoidCallback onSendMessage;

  const ChatInputArea({
    super.key,
    required this.isRecordingAudio,
    required this.isRecordingVideo,
    required this.uploadedFiles,
    required this.recognizedText,
    required this.textController,
    required this.onRecordToggle,
    required this.onFileAdd,
    required this.onCameraOpen,
    required this.onFileRemove,
    required this.onSendMessage,
  });

  @override
  State<ChatInputArea> createState() => _ChatInputAreaState();
}

class _ChatInputAreaState extends State<ChatInputArea> {
  @override
  void didUpdateWidget(ChatInputArea oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.recognizedText != oldWidget.recognizedText) {
      widget.textController.text = widget.recognizedText;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: kEiraBackground,
        border: Border(top: BorderSide(color: kEiraBorder.withOpacity(0.3))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Input field
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: kEiraBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: widget.textController,
                    decoration: const InputDecoration(
                      hintText: "Start typing a prompt",
                      hintStyle: TextStyle(color: kEiraTextSecondary),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                    ),
                    maxLines: null,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add, color: kEiraTextSecondary),
                  onPressed: widget.onFileAdd,
                ),
                Container(
                  margin: const EdgeInsets.only(right: 4),
                  decoration: BoxDecoration(
                    color: kEiraYellow,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: widget.onSendMessage,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildActionButton(
                icon: Icons.mic,
                label: "Talk",
                onPressed: widget.onRecordToggle,
              ),
              const SizedBox(width: 24),
              _buildActionButton(
                icon: Icons.videocam,
                label: "Webcam",
                onPressed: widget.onCameraOpen,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: kEiraText),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: kEiraText,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
