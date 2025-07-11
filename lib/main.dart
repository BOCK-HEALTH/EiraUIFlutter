import 'package:flutter/material.dart';

// Define the app's primary colors for easy reuse
const Color kPrimaryYellow = Color(0xFFFDB813);
const Color kScaffoldBackground = Color(0xFFF9F9F9);
const Color kCardBackground = Colors.white;
const Color kTextColor = Color(0xFF333333);
const Color kIconColor = Color(0xFF6C63FF); // A vibrant purple from the new UI

void main() {
  runApp(const EiraApp());
}

class EiraApp extends StatelessWidget {
  const EiraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Eira - Your AI Health Assistant',
      theme: ThemeData(
        primarySwatch: Colors.yellow,
        scaffoldBackgroundColor: kScaffoldBackground,
        fontFamily: 'Roboto', // A clean, modern font
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: const AppBarTheme(
          backgroundColor: kScaffoldBackground,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.black),
          titleTextStyle: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Eira'),
        centerTitle: true,
      ),
      drawer: const AppDrawer(),
      body: Stack(
        children: [
          Column(
            children: [
              const SizedBox(height: 20),
              // Make sure 'assets/eira_logo.png' exists and is in pubspec.yaml
              Image.asset('assets/eira_logo.png', height: 80),
              const SizedBox(height: 20),
              const Text(
                'Eira - Your AI Health Assistant',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: kTextColor),
              ),
              const SizedBox(height: 30),
              Expanded(
                child: GridView.count(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.85, // Adjust aspect ratio for better fit
                  children: const [
                    InfoCard(
                      icon: Icons.medical_services_outlined,
                      title: 'Medical Assistance',
                      description: 'Get reliable medical information and health guidance',
                    ),
                    InfoCard(
                      icon: Icons.medication_liquid_outlined,
                      title: 'Medication Info',
                      description: 'Learn about medications, dosages, and interactions',
                    ),
                     // Add other cards if needed
                  ],
                ),
              ),
              const SizedBox(height: 150), // Space for the floating input bar
            ],
          ),
          const Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: PromptInputArea(),
          ),
        ],
      ),
    );
  }
}

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                const UserAccountsDrawerHeader(
                  accountName: Text('Add your name', style: TextStyle(color: kTextColor)),
                  accountEmail: Text('123@gmail.com', style: TextStyle(color: Colors.grey)),
                  currentAccountPicture: CircleAvatar(
                    backgroundColor: kPrimaryYellow,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  decoration: BoxDecoration(color: Colors.white),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.add),
                    label: const Text('New Session'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryYellow,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('Recent Sessions', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                ListTile(
                  title: const Text('test2'),
                  subtitle: const Text('4 days ago'),
                  onTap: () {},
                ),
                ListTile(
                  title: const Text('test'),
                  subtitle: const Text('6/5/2025'),
                  onTap: () {},
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryYellow,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48), // Make button wider
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const InfoCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      color: kCardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Icon(icon, size: 40, color: kIconColor),
            const SizedBox(height: 15),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kTextColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Text(
                description,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PromptInputArea extends StatelessWidget {
  const PromptInputArea({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0).copyWith(top: 24),
      color: kScaffoldBackground,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Start typing a prompt',
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send, color: kPrimaryYellow),
                  onPressed: () {},
                ),
              ),
            ),
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.mic, color: kTextColor),
                label: const Text('Talk', style: TextStyle(color: kTextColor)),
              ),
              const SizedBox(width: 20),
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.videocam, color: kTextColor),
                label: const Text('Webcam', style: TextStyle(color: kTextColor)),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}