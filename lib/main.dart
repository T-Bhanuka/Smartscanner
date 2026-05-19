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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
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

  late AnimationController _fabController;
  late AnimationController _tabController;
  late AnimationController _modalController;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _tabController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _modalController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _loadData();
  }

  @override
  void dispose() {
    _fabController.dispose();
    _tabController.dispose();
    _modalController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final loadedReceipts = await StorageService.getAllReceipts();
    final loadedImages = await StorageService.getAllGalleryImages();
    final budget = await StorageService.getMonthlyBudget();
    setState(() {
      receipts = loadedReceipts;
      galleryImages = loadedImages
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
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
    });

    try {
      // 1. Text Recognizer eken Photo eke thiyena akuru tika mulin kiyawagannawa
      final inputImage = InputImage.fromFilePath(imagePath);
      final textRecognizer = TextRecognizer(
        script: TextRecognitionScript.latin,
      );
      final RecognizedText recognizedText = await textRecognizer.processImage(
        inputImage,
      );

      String fullText = recognizedText.text;
      List<String> lines = fullText.split('\n');
      textRecognizer.close();

      // 2. Aluth Entity Extractor Model eka start karanawa
      // Meken thama e akuru asse thiyena "Theruma" (Dates, Money) allanne
      final entityExtractor = EntityExtractor(
        language: EntityExtractorLanguage.english,
      );
      final annotations = await entityExtractor.annotateText(fullText);

      String shopName = lines.isNotEmpty ? lines.first.trim() : "Unknown Shop";
      double totalAmount = 0.0;
      String date = DateTime.now()
          .toIso8601String(); // Default date eka ada dawasa

      // AI eka hoyagaththa dewal (Annotations) asse yanawa
      for (final annotation in annotations) {
        for (final entity in annotation.entities) {
          // A. Salli Ganan (Money) model eken alluwada balanawa
          if (entity.type == EntityType.money) {
            // "Rs 1500" wage aawoth akuru tika ain karala 1500 gannawa
            String moneyText = annotation.text.replaceAll(
              RegExp(r'[^0-9.]'),
              '',
            );
            double val = double.tryParse(moneyText) ?? 0.0;

            // Receipt ekaka thiyena loku ma ganana apage "Total" eka widihata gannawa
            if (val > totalAmount) {
              totalAmount = val;
            }
          }
          // B. Dawasa (Date/Time) model eken alluwada balanawa
          else if (entity.type == EntityType.dateTime) {
            date =
                annotation.text; // AI eka extract karapu dawasa ehemma gannawa
          }
        }
      }

      entityExtractor.close();

      // 3. Database ekata save karanawa
      await FirebaseFirestore.instance.collection('receipts').add({
        'storeName': shopName,
        'totalAmount': totalAmount,
        'date': date,
        'category': 'Other',
        'rawText': fullText,
      });

      // 4. App eke UI eka update karanawa
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

  Widget _buildOptionBtn({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
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
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
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
        title: const Text(
          "Delete Target",
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          "Are you sure?",
          style: TextStyle(color: Colors.white70),
        ),
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
        content: const Text(
          "Delete this bill?",
          style: TextStyle(color: Colors.white70),
        ),
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
                    border: Border(
                      bottom: BorderSide(color: Color(0xFF334155)),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.qr_code_scanner,
                            color: Colors.white,
                            size: 28,
                          ),
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
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
                          icon: const Icon(
                            Icons.close,
                            color: Color(0xFF818CF8),
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    transitionBuilder: (child, animation) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                    child: IndexedStack(
                      key: ValueKey<int>(activeTab),
                      index: activeTab,
                      children: [
                        Dashboard(
                          receipts: receipts,
                          monthlyBudget: monthlyBudget,
                        ),
                        _buildGalleryTab(),
                        _buildHistoryTab(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // FAB
            Positioned(
              bottom: 100,
              right: 16,
              child: RotationTransition(
                turns: Tween<double>(
                  begin: 0,
                  end: 0.125,
                ).animate(_fabController),
                child: FloatingActionButton(
                  onPressed: () {
                    _showImageSourceOptions();
                    if (isFabOpen) {
                      _fabController.reverse();
                    } else {
                      _fabController.forward();
                    }
                  },
                  backgroundColor: const Color(0xFF8B5CF6),
                  child: Icon(
                    isFabOpen ? Icons.close : Icons.add,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            // Bottom nav
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 16,
                ),
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
      onTap: () {
        setState(() => activeTab = index);
        _tabController.forward(from: 0);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isActive
                  ? const Color(0xFF8B5CF6).withValues(alpha: 0.2)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: isActive
                  ? const Color(0xFF818CF8)
                  : const Color(0xFF64748B),
              size: 24,
            ),
          ),
          const SizedBox(height: 4),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 300),
            style: TextStyle(
              color: isActive
                  ? const Color(0xFF818CF8)
                  : const Color(0xFF64748B),
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
            child: Text(label),
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
            return ScaleTransition(
              scale: Tween<double>(begin: 0.8, end: 1).animate(
                CurvedAnimation(
                  parent: _tabController,
                  curve: Interval(
                    index * 0.1,
                    (index * 0.1) + 0.4,
                    curve: Curves.easeOut,
                  ),
                ),
              ),
              child: FadeTransition(
                opacity: Tween<double>(begin: 0, end: 1).animate(
                  CurvedAnimation(
                    parent: _tabController,
                    curve: Interval(
                      index * 0.1,
                      (index * 0.1) + 0.4,
                      curve: Curves.easeOut,
                    ),
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    border: Border.all(color: const Color(0xFF334155)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Stack(
                    children: [
                      Container(
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.image,
                          color: Color(0xFF64748B),
                          size: 48,
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: IconButton(
                          onPressed: () => _deleteGalleryItem(img.id),
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.red,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildHistoryTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: receipts.length,
      itemBuilder: (context, index) {
        final receipt = receipts[index];
        return SlideTransition(
          position:
              Tween<Offset>(
                begin: const Offset(-0.5, 0),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(
                  parent: _tabController,
                  curve: Interval(
                    index * 0.08,
                    (index * 0.08) + 0.4,
                    curve: Curves.easeOut,
                  ),
                ),
              ),
          child: FadeTransition(
            opacity: Tween<double>(begin: 0, end: 1).animate(
              CurvedAnimation(
                parent: _tabController,
                curve: Interval(
                  index * 0.08,
                  (index * 0.08) + 0.4,
                  curve: Curves.easeOut,
                ),
              ),
            ),
            child: Container(
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
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      const Text(
                        'Rs.',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        receipt.total.toStringAsFixed(2),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => _deleteReceipt(receipt.id),
                    icon: const Icon(
                      Icons.close,
                      color: Color(0xFFEF4444),
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
                        onPressed: () =>
                            setState(() => showBudgetModal = false),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: Color(0xFF64748B)),
                        ),
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
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8B5CF6),
                        ),
                        child: const Text(
                          'Save',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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
