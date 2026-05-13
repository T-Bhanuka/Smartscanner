import 'dart:convert';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_mlkit_entity_extraction/google_mlkit_entity_extraction.dart'; // Aluth AI Model eka
import 'package:image_picker/image_picker.dart';

import 'firebase_options.dart';
import 'components/dashboard.dart';
import 'components/camera_scanner.dart';
import 'services/storage_service.dart';
import 'types.dart';
import 'services/gemini_service.dart';

void main() async { 
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp(cameras: cameras));
}

class MyApp extends StatelessWidget {
  final List<CameraDescription> cameras;

  const MyApp({super.key, required this.cameras});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartScan Pro',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF8B5CF6),
          secondary: Color(0xFF818CF8),
        ),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Receipt> receipts = [];
  List<GalleryImage> galleryImages = [];
  bool showScanner = false;
  bool isAnalyzing = false;
  bool isFabOpen = false;
  String? analysisError;
  double monthlyBudget = 20000;
  int activeTab = 0;
  bool showBudgetModal = false;
  String tempBudget = '20000';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final loadedReceipts = await StorageService.getAllReceipts();
    final loadedImages = await StorageService.getAllGalleryImages();
    final budget = await StorageService.getMonthlyBudget();
    setState(() {
      receipts = loadedReceipts;
      galleryImages = loadedImages..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      monthlyBudget = budget;
    });
  }

  Future<void> _saveData() async {
    await StorageService.saveReceipts(receipts, monthlyBudget);
  }

  // ==========================================================
  // MEKA THAMAI ALUTH "PRO AI BRAIN" EKA 🔥
  // ==========================================================
  Future<void> _processReceipt(String imagePath) async {
  setState(() {
    showScanner = false;
    isAnalyzing = true;
    analysisError = null;
  });

  try {
    final extractedData = await GeminiService.analyzeReceipt(imagePath);

    // Check if receipt is readable
    if (extractedData['isReadable'] != true) {
      setState(() => analysisError = "Receipt is not readable. Please try again with a clearer image.");
      return;
    }

    // Parse category
    Category category;
    try {
      category = Category.values.firstWhere(
        (e) => e.name == (extractedData['category'] ?? 'Other'),
        orElse: () => Category.Other,
      );
    } catch (_) {
      category = Category.Other;
    }

    // Parse items
    final List<ReceiptItem> items = [];
    if (extractedData['items'] != null) {
      for (final item in extractedData['items']) {
        Category itemCategory;
        try {
          itemCategory = Category.values.firstWhere(
            (e) => e.name == (item['category'] ?? 'Other'),
            orElse: () => Category.Other,
          );
        } catch (_) {
          itemCategory = Category.Other;
        }
        items.add(ReceiptItem(
          name: item['name'] ?? 'Unknown Item',
          price: (item['price'] as num?)?.toDouble() ?? 0.0,
          category: itemCategory,
        ));
      }
    }

    // Build Receipt object
    final now = DateTime.now();
    final newReceipt = Receipt(
      id: now.millisecondsSinceEpoch.toString(),
      storeName: extractedData['storeName'] ?? 'Unknown Store',
      date: extractedData['date'] ?? now.toIso8601String().split('T')[0],
      time: extractedData['time'] ?? now.toIso8601String().split('T')[1].substring(0, 5),
      items: items,
      total: (extractedData['total'] as num?)?.toDouble() ?? 0.0,
      category: category,
      timestamp: now.millisecondsSinceEpoch,
    );

    // Save to local storage
    setState(() {
      receipts.add(newReceipt);
    });
    await _saveData();

    // Also save to Firebase (optional, non-blocking)
    try {
      await FirebaseFirestore.instance.collection('receipts').add({
        'storeName': newReceipt.storeName,
        'totalAmount': newReceipt.total,
        'date': newReceipt.date,
        'category': newReceipt.category.name,
        'items': items.map((i) => {'name': i.name, 'price': i.price, 'category': i.category.name}).toList(),
      });
    } catch (firebaseError) {
      debugPrint('Firebase save failed (non-critical): $firebaseError');
    }

    await _loadData();

  } catch (e) {
    setState(() => analysisError = "Error scanning: $e");
  } finally {
    setState(() => isAnalyzing = false);
  }
}
  // ==========================================================

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      setState(() => isFabOpen = false); 
      await _processReceipt(pickedFile.path); 
    }
  }

  void _showImageSourceOptions() {
    setState(() => isFabOpen = true);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildOptionBtn(
                  icon: Icons.camera_alt,
                  label: 'Camera',
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      isFabOpen = false;
                      showScanner = true;
                    });
                  },
                ),
                _buildOptionBtn(
                  icon: Icons.photo_library,
                  label: 'Gallery',
                  onTap: () {
                    Navigator.pop(context);
                    _pickFromGallery();
                  },
                ),
              ],
            ),
          ),
        );
      },
    ).whenComplete(() {
      if (mounted) setState(() => isFabOpen = false);
    });
  }

  Widget _buildOptionBtn({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF334155),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFF8B5CF6), size: 32),
          ),
          const SizedBox(height: 8),
          Text(
            label, 
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
          ),
        ],
      ),
    );
  }

  void _changeBudget() {
    setState(() {
      tempBudget = monthlyBudget.toString();
      showBudgetModal = true;
    });
  }

  void _deleteGalleryItem(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text("Delete Target", style: TextStyle(color: Colors.white)),
        content: const Text("Are you sure?", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                galleryImages.removeWhere((img) => img.id == id);
              });
              StorageService.deleteGalleryImage(id);
              Navigator.pop(context);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _deleteReceipt(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text("Delete Bill", style: TextStyle(color: Colors.white)),
        content: const Text("Delete this bill?", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                receipts.removeWhere((r) => r.id == id);
              });
              _saveData();
              Navigator.pop(context);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFF1E293B),
                    border: Border(bottom: BorderSide(color: Color(0xFF334155))),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.qr_code_scanner, color: Colors.white, size: 28),
                          SizedBox(width: 12),
                          Text(
                            'SmartScan Pro',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: _changeBudget,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF334155),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Budget: Rs. ${monthlyBudget.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (analysisError != null)
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B).withValues(alpha: 0.6),
                      border: Border.all(color: const Color(0xFF818CF8)),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            analysisError!,
                            style: const TextStyle(
                              color: Color(0xFF818CF8),
                              fontSize: 14,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => setState(() => analysisError = null),
                          icon: const Icon(Icons.close, color: Color(0xFF818CF8), size: 20),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: IndexedStack(
                    index: activeTab,
                    children: [
                      Dashboard(receipts: receipts, monthlyBudget: monthlyBudget),
                      _buildGalleryTab(),
                      _buildHistoryTab(),
                    ],
                  ),
                ),
              ],
            ),
            // FAB
            Positioned(
              bottom: 100,
              right: 16,
              child: FloatingActionButton(
                onPressed: _showImageSourceOptions,
                backgroundColor: const Color(0xFF8B5CF6),
                child: Icon(isFabOpen ? Icons.close : Icons.add, color: Colors.white),
              ),
            ),
            // Bottom nav
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                decoration: const BoxDecoration(
                  color: Color(0xFF1E293B),
                  border: Border(top: BorderSide(color: Color(0xFF334155))),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildNavItem(0, Icons.bar_chart, 'Analytics'),
                    _buildNavItem(1, Icons.image, 'Vault'),
                    _buildNavItem(2, Icons.history, 'Archive'),
                  ],
                ),
              ),
            ),
            if (showBudgetModal) _buildBudgetModal(),
            if (showScanner)
              Positioned.fill(
                child: CameraScanner(
                  onCapture: _processReceipt, 
                  onClose: () => setState(() => showScanner = false),
                ),
              ),
            if (isAnalyzing) _buildAnalyzingOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isActive = activeTab == index;
    return GestureDetector(
      onTap: () => setState(() => activeTab = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isActive ? const Color(0xFF818CF8) : const Color(0xFF64748B),
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isActive ? const Color(0xFF818CF8) : const Color(0xFF64748B),
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGalleryTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B).withValues(alpha: 0.4),
            border: Border.all(color: const Color(0xFF334155)),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              const Row(
                children: [
                  Icon(Icons.image, color: Color(0xFF818CF8), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Image Vault',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${galleryImages.length} Photos total',
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: galleryImages.length,
          itemBuilder: (context, index) {
            final img = galleryImages[index];
            return Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                border: Border.all(color: const Color(0xFF334155)),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                children: [
                  Container(
                    alignment: Alignment.center,
                    child: const Icon(Icons.image, color: Color(0xFF64748B), size: 48),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      onPressed: () => _deleteGalleryItem(img.id),
                      icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildHistoryTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: receipts.map((receipt) => Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B).withValues(alpha: 0.8),
          border: Border.all(color: const Color(0xFF334155)),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    receipt.storeName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    receipt.date,
                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                const Text(
                  'Rs.',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                ),
                Text(
                  receipt.total.toStringAsFixed(2),
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            IconButton(
              onPressed: () => _deleteReceipt(receipt.id),
              icon: const Icon(Icons.close, color: Color(0xFFEF4444), size: 20),
            ),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildBudgetModal() {
    return Positioned.fill(
      child: Container(
        color: const Color(0xFF0F172A).withValues(alpha: 0.9),
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Set Budget',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: TextEditingController(text: tempBudget),
                  onChanged: (value) => tempBudget = value,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    prefixText: 'Rs. ',
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFF334155)),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => setState(() => showBudgetModal = false),
                        child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          final num? value = num.tryParse(tempBudget);
                          if (value != null && value > 0) {
                            setState(() {
                              monthlyBudget = value.toDouble();
                              showBudgetModal = false;
                            });
                            _saveData();
                          }
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6)),
                        child: const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyzingOverlay() {
    return Positioned.fill(
      child: Container(
        color: const Color(0xFF0F172A).withValues(alpha: 0.8),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Color(0xFF8B5CF6)),
              SizedBox(height: 16),
              Text(
                'Scanning...',
                style: TextStyle(
                  color: Color(0xFF818CF8),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Extracting data using Entity Extractor AI',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}