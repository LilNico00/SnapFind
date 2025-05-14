import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_selector/file_selector.dart';
import 'image_matcher.dart';
import 'prenotazioni_screen.dart';
import 'risultato_prodotto.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const SnapFindApp());
}

class SnapFindApp extends StatelessWidget {
  const SnapFindApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SnapFind',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.black,
        scaffoldBackgroundColor: const Color(0xFF1C1C1C),
        textTheme: const TextTheme(
          titleLarge: TextStyle(color: Colors.white),
          bodyLarge: TextStyle(color: Colors.white),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
        ),
      ),
      home: const ImageCaptureScreen(),
    );
  }
}

class ImageCaptureScreen extends StatefulWidget {
  const ImageCaptureScreen({super.key});

  @override
  State<ImageCaptureScreen> createState() => _ImageCaptureScreenState();
}

class _ImageCaptureScreenState extends State<ImageCaptureScreen> {
  final ImagePicker picker = ImagePicker();
  String welcomeText = "Tap to scan";
  bool inventoryLoaded = false;

  Future<void> _getImageAndSearch() async {
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile == null) return;

    final imageFile = File(pickedFile.path);
    final result = await matchImageWithInventory(imageFile);

    if (!mounted) return; // Evita errori se il widget non è più montato

    if (result != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RisultatoProdotto(matchResult: result),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Nessun prodotto riconosciuto.")),
      );
    }
  }

  Future<void> _loadInventoryFromFile() async {
    try {
      final typeGroup = XTypeGroup(label: 'json', extensions: ['json']);
      final file = await openFile(acceptedTypeGroups: [typeGroup]);
      if (file == null) return;

      final content = await file.readAsString();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('inventory_data', content);

      if (!mounted) return;

      setState(() {
        inventoryLoaded = true;
        welcomeText = "Inventory loaded successfully! Tap to scan.";
      });

      Future.delayed(const Duration(seconds: 4), () {
        if (!mounted) return;
        setState(() {
          welcomeText = "Tap to scan";
        });
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Errore nel caricamento: $e")),
      );
    }
  }

  void _showSupportDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text("Support", style: TextStyle(color: Colors.white)),
        content: const Text(
          "For support, contact: snapfind.support@email.com",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  void _vaiAllePrenotazioni() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PrenotazioniScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SnapFind'),
        actions: [
          IconButton(
            icon: const Icon(Icons.list),
            tooltip: 'Prenotazioni',
            onPressed: _vaiAllePrenotazioni,
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'upload') {
                _loadInventoryFromFile();
              } else if (value == 'support') {
                _showSupportDialog();
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'upload', child: Text('Upload Inventory')),
              const PopupMenuItem(value: 'support', child: Text('Support')),
            ],
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search, size: 100, color: Colors.white),
            const SizedBox(height: 20),
            Text(
              welcomeText,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: _getImageAndSearch,
              icon: const Icon(Icons.camera_alt, color: Colors.white),
              label: const Text('Tap to scan', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
