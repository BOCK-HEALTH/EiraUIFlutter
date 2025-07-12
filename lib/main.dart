import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  
  // Force English locale
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  
  runApp(const EiraApp());
}

class EiraApp extends StatelessWidget {
  const EiraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Eira Mobile',
      debugShowCheckedModeBanner: false,
      locale: const Locale('en', 'US'), // Force English locale
      theme: ThemeData(
        fontFamily: 'Roboto', // Use system default font
        scaffoldBackgroundColor: kEiraBackground,
        primaryColor: kEiraYellow,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: kEiraText, fontFamily: 'Roboto'),
          bodyMedium: TextStyle(color: kEiraText, fontFamily: 'Roboto'),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: kEiraBackground,
          elevation: 0,
          iconTheme: IconThemeData(color: kEiraText),
          titleTextStyle: TextStyle(
            color: kEiraText,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            fontFamily: 'Roboto',
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
  
  // File handling - these will be displayed above input and sent only when user presses send
  final List<File> _pendingFiles = [];
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
    }
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      
      CameraDescription? frontCamera;
      CameraDescription? backCamera; // Keep track of back camera for fallback

      for (var camera in cameras) {
        if (camera.lensDirection == CameraLensDirection.front) {
          frontCamera = camera;
        } else if (camera.lensDirection == CameraLensDirection.back) {
          backCamera = camera;
        }
      }

      // Prefer front camera, then back camera, then any available camera
      CameraDescription? selectedCamera = frontCamera ?? backCamera;
      selectedCamera ??= cameras.isNotEmpty ? cameras.first : null;

      if (selectedCamera != null) {
        _cameraController = CameraController(
          selectedCamera,
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
      } else {
        print('No cameras available');
      }
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }

  void _startNewChat() {
    setState(() {
      _hasActiveChat = true;
      _pendingFiles.clear();
      _recognizedText = '';
      _textController.clear();
      _messages.clear();
    });
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _requestPermissions() async {
    try {
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
    } catch (e) {
      print('Error requesting permissions: $e');
    }
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

      if (_audioRecorder != null) {
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
      }
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
            _pendingFiles.add(file);
          });
          
          _showSnackBar('Audio recorded! Press send to share.', Colors.green);
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

        // Show the video recording preview dialog
        showDialog(
          context: context,
          barrierDismissible: false, // Prevent dismissing by tapping outside
          builder: (BuildContext context) {
            return VideoRecordingPreview(
              cameraController: _cameraController!,
              onStopRecording: () async {
                await _stopVideoRecording();
                Navigator.of(context).pop(); // Dismiss dialog after stopping
              },
              onClose: () {
                // If recording, stop it before closing
                if (_isRecordingVideo) {
                  _stopVideoRecording(); // Stop recording but don't add to pending files if user just closes
                }
                Navigator.of(context).pop();
              },
            );
          },
        );

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
            _pendingFiles.add(savedFile);
          });
          
          _showSnackBar('Video recorded! Press send to share.', Colors.green);
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
            _pendingFiles.addAll(files);
          });
          
          _showSnackBar('${files.length} file(s) added. Press send to share.', Colors.green);
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
      
      // Start new chat if not already active
      if (!_hasActiveChat) {
        _hasActiveChat = true;
      }
    });
  }

  void _removePendingFile(int index) {
    setState(() {
      _pendingFiles.removeAt(index);
    });
  }

  Future<void> _toggleRecording() async {
    print('Toggle recording called - isRecording: $_isRecordingAudio');
    if (_isRecordingAudio) {
      await _stopAudioRecording();
    } else {
      await _startAudioRecording();
    }
  }

  Future<void> _toggleVideoRecording() async {
    print('Toggle video recording called - isRecording: $_isRecordingVideo');
    if (_isRecordingVideo) {
      // If already recording, this means the dialog is open and user wants to stop from outside
      // This case should ideally be handled by the dialog's stop button, but for robustness:
      await _stopVideoRecording();
    } else {
      await _startVideoRecording();
    }
  }

  void _sendMessage() {
    print('Send message called - text: ${_textController.text.trim()}, files: ${_pendingFiles.length}');
    
    if (_textController.text.trim().isNotEmpty || _pendingFiles.isNotEmpty) {
      String messageText = _textController.text.trim();
      List<File> attachments = List.from(_pendingFiles);
      
      _addMessage(
        messageText.isEmpty ? "Files shared" : messageText, 
        true, 
        attachments.isNotEmpty ? attachments : null
      );
      
      setState(() {
        _textController.clear();
        _pendingFiles.clear(); // Clear pending files after sending
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
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          duration: const Duration(seconds: 2),
        ),
      );
    }
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
            onPressed: () {
              print('Menu button pressed');
              _scaffoldKey.currentState?.openDrawer();
            },
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
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("U", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontFamily: 'Roboto')),
                SizedBox(width: 4),
                Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 16),
              ],
            ),
          ),
        ],
      ),
      drawer: AppDrawer(onNewSession: _startNewChat),
      body: Stack(
        children: [
          Padding(
            padding: EdgeInsets.only(
              bottom: _pendingFiles.isNotEmpty ? 140.0 : 100.0, // Adjusted padding for new chip size
            ),
            child: _hasActiveChat
                ? MessagesListView(messages: _messages)
                : WelcomeView(onCapabilityTap: _startNewChat),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Pending files display
                if (_pendingFiles.isNotEmpty)
                  PendingFilesDisplay(
                    files: _pendingFiles,
                    onRemove: _removePendingFile,
                  ),
                // Chat input area
                ChatInputArea(
                  isRecordingAudio: _isRecordingAudio,
                  isRecordingVideo: _isRecordingVideo,
                  recognizedText: _recognizedText,
                  textController: _textController,
                  onRecordToggle: _toggleRecording,
                  onFileAdd: _pickFiles,
                  onCameraOpen: _toggleVideoRecording,
                  onSendMessage: _sendMessage,
                  hasPendingFiles: _pendingFiles.isNotEmpty,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PendingFilesDisplay extends StatelessWidget {
  final List<File> files;
  final Function(int) onRemove;

  const PendingFilesDisplay({
    super.key,
    required this.files,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0), // Adjusted padding
      decoration: BoxDecoration(
        color: kEiraBackground,
        border: Border(
          top: BorderSide(color: kEiraBorder.withOpacity(0.3)),
        ),
      ),
      child: SingleChildScrollView( // Use SingleChildScrollView for horizontal chips
        scrollDirection: Axis.horizontal,
        child: Row(
          children: files.asMap().entries.map((entry) {
            int index = entry.key;
            File file = entry.value;
            return Padding(
              padding: const EdgeInsets.only(right: 8.0), // Spacing between chips
              child: PendingFileChip(
                file: file,
                onRemove: () => onRemove(index),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class PendingFileChip extends StatelessWidget {
  final File file;
  final VoidCallback onRemove;

  const PendingFileChip({
    super.key,
    required this.file,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final fileName = path.basename(file.path);
    final fileType = _getFileType(file.path);
    
    // Determine display name for recording types
    String displayName;
    IconData displayIcon;

    if (fileType == 'Audio') {
      displayName = 'Voice Recording';
      displayIcon = Icons.mic;
    } else if (fileType == 'Video') {
      displayName = 'Video Recording';
      displayIcon = Icons.videocam;
    } else {
      displayName = fileName;
      displayIcon = _getFileIcon(file.path);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // Smaller padding
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20), // Pill shape
        border: Border.all(color: kEiraBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            displayIcon,
            color: kEiraTextSecondary, // Icon color as in image
            size: 16,
          ),
          const SizedBox(width: 6), // Smaller spacing
          Flexible(
            child: Text(
              displayName,
              style: const TextStyle(
                fontSize: 13, // Smaller font size
                color: kEiraText,
                fontFamily: 'Roboto',
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(
              Icons.close,
              color: kEiraTextSecondary, // Close icon color as in image
              size: 14, // Smaller close icon
            ),
          ),
        ],
      ),
    );
  }

  String _getFileType(String path) {
    final extension = path.split('.').last.toLowerCase();
    if (['pdf'].contains(extension)) return 'Document';
    if (['jpg', 'jpeg', 'png'].contains(extension)) return 'Image';
    if (['mp4', 'mov'].contains(extension)) return 'Video';
    if (['mp3', 'aac', 'wav'].contains(extension)) return 'Audio';
    return 'File';
  }

  IconData _getFileIcon(String path) {
    final extension = path.split('.').last.toLowerCase();
    if (['pdf'].contains(extension)) return Icons.insert_drive_file; // Changed to generic file icon for PDF
    if (['jpg', 'jpeg', 'png'].contains(extension)) return Icons.image;
    if (['mp4', 'mov'].contains(extension)) return Icons.videocam;
    if (['mp3', 'aac', 'wav'].contains(extension)) return Icons.mic; // Changed to mic for audio files
    return Icons.insert_drive_file;
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
              child: const Row(
                children: [
                  CircleAvatar(
                    backgroundColor: kEiraYellow,
                    radius: 20,
                    child: Text("O", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Roboto')),
                  ),
                  SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Owaiz", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, fontFamily: 'Roboto')),
                      Text("123@gmail.com", style: TextStyle(color: Colors.grey, fontSize: 12, fontFamily: 'Roboto')),
                    ],
                  ),
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ElevatedButton.icon(
                onPressed: () {
                  print('New Session button pressed');
                  onNewSession();
                },
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text("New Session", style: TextStyle(color: Colors.white, fontFamily: 'Roboto')),
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
                child: Text("Recent Sessions", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, fontFamily: 'Roboto')),
              ),
            ),
            
            const SizedBox(height: 10),
            
            ListTile(
              title: const Text("test2", style: TextStyle(fontSize: 14, fontFamily: 'Roboto')),
              subtitle: const Text("4 days ago", style: TextStyle(fontSize: 12, fontFamily: 'Roboto')),
              onTap: () {
                print('Recent session tapped: test2');
              },
            ),
            ListTile(
              title: const Text("test", style: TextStyle(fontSize: 14, fontFamily: 'Roboto')),
              subtitle: const Text("6/5/2025", style: TextStyle(fontSize: 12, fontFamily: 'Roboto')),
              onTap: () {
                print('Recent session tapped: test');
              },
            ),
            
            const Spacer(),
            
            const Divider(color: kEiraBorder),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text("Logout", style: TextStyle(color: Colors.red, fontFamily: 'Roboto')),
              onTap: () {
                print('Logout tapped');
              },
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
                child: const Icon(Icons.settings, color: Colors.white, size: 24), 
              ),
              const SizedBox(width: 12),
              const Text(
                "Eira",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                  color: kEiraText,
                  fontFamily: 'Roboto',
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
              fontFamily: 'Roboto',
            ),
          ),
          
          const SizedBox(height: 60),
          
          // Capability cards in 2x2 grid layout
          GridView.builder(
            shrinkWrap: true, // Important to make GridView work inside SingleChildScrollView
            physics: const NeverScrollableScrollPhysics(), // Disable GridView's own scrolling
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // 2 columns
              crossAxisSpacing: 16.0, // Spacing between columns
              mainAxisSpacing: 16.0, // Spacing between rows
              childAspectRatio: 0.8, // Adjusted aspect ratio to give more vertical space
            ),
            itemCount: 4, // Total number of cards
            itemBuilder: (context, index) {
              List<Map<String, dynamic>> cardsData = [
                {
                  'icon': Icons.local_hospital,
                  'title': 'Medical Assistance',
                  'description': 'Get reliable medical information and health guidance',
                },
                {
                  'icon': Icons.medication,
                  'title': 'Medication Info',
                  'description': 'Learn about medications, dosages, and potential interactions',
                },
                {
                  'icon': Icons.analytics,
                  'title': 'Health Analysis',
                  'description': 'Understand symptoms and get personalized health insights',
                },
                {
                  'icon': Icons.favorite, // New icon for Wellness Tips
                  'title': 'Wellness Tips',
                  'description': 'Receive personalized wellness and lifestyle recommendations',
                },
              ];
              
              final card = cardsData[index];
              return CapabilityCard(
                icon: card['icon'],
                title: card['title'],
                description: card['description'],
                onTap: () {
                  print('${card['title']} card tapped');
                  onCapabilityTap();
                },
              );
            },
          ),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class CapabilityCard extends StatelessWidget {
  final IconData icon;
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
        // Removed fixed width to allow GridView to manage sizing
        padding: const EdgeInsets.all(16), // Reduced padding slightly
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
        child: Column( // Changed to Column for vertical alignment of icon and text
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: kEiraYellow.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: kEiraYellow,
                size: 24,
              ),
            ),
            const SizedBox(height: 10), // Spacing between icon and title
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15, // Slightly reduced font size
                color: kEiraText,
                fontFamily: 'Roboto',
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13, // Slightly reduced font size
                color: kEiraTextSecondary,
                height: 1.3,
                fontFamily: 'Roboto',
              ),
              maxLines: 3, // Allow up to 3 lines for description
              overflow: TextOverflow.ellipsis, // Add ellipsis for overflow
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
            fontFamily: 'Roboto',
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
          attachments: message.attachments, // Pass attachments back to MessageBubble
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
                ? const Text("U", style: TextStyle(color: Colors.white, fontFamily: 'Roboto'))
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
                        color: isUser ? kEiraText : kEiraYellowHover,
                        fontFamily: 'Roboto',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatTime(timestamp),
                      style: const TextStyle(
                        fontSize: 12,
                        color: kEiraTextSecondary,
                        fontFamily: 'Roboto',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (text.isNotEmpty)
                  Text(text, style: const TextStyle(height: 1.5, fontFamily: 'Roboto')),
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
                      style: const TextStyle(fontWeight: FontWeight.w500, fontFamily: 'Roboto'),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      fileSize,
                      style: const TextStyle(
                        fontSize: 12,
                        color: kEiraTextSecondary,
                        fontFamily: 'Roboto',
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
    print('Opening file: ${path.basename(file.path)}');
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
        const CircleAvatar(
          backgroundColor: kEiraYellow,
          child: Icon(Icons.health_and_safety, color: Colors.white, size: 20),
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
  final String recognizedText;
  final TextEditingController textController;
  final VoidCallback onRecordToggle;
  final VoidCallback onFileAdd;
  final VoidCallback onCameraOpen;
  final VoidCallback onSendMessage;
  final bool hasPendingFiles;

  const ChatInputArea({
    super.key,
    required this.isRecordingAudio,
    required this.isRecordingVideo,
    required this.recognizedText,
    required this.textController,
    required this.onRecordToggle,
    required this.onFileAdd,
    required this.onCameraOpen,
    required this.onSendMessage,
    required this.hasPendingFiles,
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
                      hintStyle: TextStyle(color: kEiraTextSecondary, fontFamily: 'Roboto'),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                    ),
                    style: const TextStyle(fontFamily: 'Roboto'),
                    maxLines: null,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add, color: kEiraTextSecondary),
                  onPressed: () {
                    print('Add file button pressed');
                    widget.onFileAdd();
                  },
                ),
                Container(
                  margin: const EdgeInsets.only(right: 4),
                  decoration: BoxDecoration(
                    color: kEiraYellow,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: () {
                      print('Send button pressed');
                      widget.onSendMessage();
                    },
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
                icon: widget.isRecordingAudio ? Icons.stop : Icons.mic,
                label: widget.isRecordingAudio ? "Stop" : "Talk",
                onPressed: () {
                  print('Talk button pressed');
                  widget.onRecordToggle();
                },
                isActive: widget.isRecordingAudio,
              ),
              const SizedBox(width: 24),
              _buildActionButton(
                icon: widget.isRecordingVideo ? Icons.stop : Icons.videocam,
                label: widget.isRecordingVideo ? "Stop" : "Webcam",
                onPressed: () {
                  print('Webcam button pressed');
                  widget.onCameraOpen();
                },
                isActive: widget.isRecordingVideo,
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
    bool isActive = false,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? kEiraYellow.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon, 
              size: 20, 
              color: isActive ? kEiraYellow : kEiraText
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isActive ? kEiraYellow : kEiraText,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'Roboto',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class VideoRecordingPreview extends StatelessWidget {
  final CameraController cameraController;
  final VoidCallback onStopRecording;
  final VoidCallback onClose;

  const VideoRecordingPreview({
    super.key,
    required this.cameraController,
    required this.onStopRecording,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    if (!cameraController.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 240, // Fixed width for the preview
                height: 320, // Fixed height for the preview
                child: CameraPreview(cameraController),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: onStopRecording,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade400,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  child: const Text("Stop Recording", style: TextStyle(fontFamily: 'Roboto')),
                ),
                const SizedBox(width: 16),
                OutlinedButton(
                  onPressed: onClose,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kEiraText,
                    side: BorderSide(color: kEiraBorder),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  child: const Text("Close", style: TextStyle(fontFamily: 'Roboto')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
