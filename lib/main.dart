import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img_lib;

import 'components/dashboard.dart';
import 'components/camera_scanner.dart';
import 'services/storage_service.dart';
import 'screens/auth/login_screen.dart'; // login screen
import 'screens/auth/register_screen.dart'; // register screen
import 'types.dart';
import 'services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
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

      home: const LoginScreen(),

      routes: {
        '/dashboard': (context) => const HomePage(),
        '/register': (context) => const RegisterScreen(),
        '/login': (context) => const LoginScreen(),
      },
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
    try {
      debugPrint('SmartScan: Loading data...');
      final token = await StorageService.getToken();
      if (token == null || token.isEmpty) {
        debugPrint('SmartScan: No token found. Performing silent auth...');
        await _performSilentAuth();
      }

      await _fetchData();
      debugPrint('SmartScan: Data loaded successfully.');
    } catch (e, stack) {
      debugPrint('SmartScan: Error loading data: $e');
      debugPrint('SmartScan: Stacktrace: $stack');
      if (e.toString().contains('401')) {
        try {
          debugPrint(
            'SmartScan: 401 error. Clearing token and retrying silent auth...',
          );
          await StorageService.clearToken();
          await _performSilentAuth();
          await _fetchData();
          debugPrint('SmartScan: Retry after silent auth successful.');
          return;
        } catch (authError) {
          debugPrint('SmartScan: Silent auth retry failed: $authError');
          setState(() {
            analysisError = 'Authentication failed: $authError';
          });
          return;
        }
      }
      setState(() {
        analysisError = 'Failed to load data: $e';
      });
    }
  }

  Future<void> _performSilentAuth() async {
    try {
      debugPrint('SmartScan: Registering user...');
      await ApiService.register('User', 'user@example.com', 'password123');
      debugPrint('SmartScan: Registration successful.');
    } catch (e) {
      debugPrint('SmartScan: Registration failed ($e). Trying to log in...');
      await ApiService.login('user@example.com', 'password123');
      debugPrint('SmartScan: Login successful.');
    }
  }

  Future<void> _fetchData() async {
    final receiptsData = await ApiService.getAllReceipts();
    final loadedReceipts = (receiptsData)
        .map((r) => Receipt.fromJson(r))
        .toList();

    final galleryData = await ApiService.getGalleryImages();
    final loadedImages = (galleryData)
        .map((r) => GalleryImage.fromJson(r))
        .toList();

    final currentMonth = DateTime.now().toIso8601String().substring(0, 7);
    final budgetData = await ApiService.getBudget(currentMonth);

    setState(() {
      receipts = loadedReceipts;
      galleryImages = loadedImages
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      monthlyBudget = (budgetData['budget'] as num?)?.toDouble() ?? 20000.0;
    });
  }

  Future<void> _saveData() async {
    try {
      final currentMonth = DateTime.now().toIso8601String().substring(0, 7);
      await ApiService.updateBudget(currentMonth, monthlyBudget);
    } catch (e) {
      debugPrint('Error saving data: $e');
    }
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
      // Read and compress image file, then convert to base64
      final base64ImageStr = await _compressAndEncodeImage(imagePath);
      final base64Image = 'data:image/jpeg;base64,$base64ImageStr';

      // 1. Send image to Gemini API for translation and extraction
      final response = await ApiService.analyzeReceipt(base64Image);

      // 2. Upload image to backend gallery linked to receiptId
      final String? receiptId =
          (response['receipt']?['_id'] ??
                  response['receipt']?['id'] ??
                  response['_id'] ??
                  response['id'])
              ?.toString();
      debugPrint(
        'SmartScan: Uploading gallery image linked to receiptId: $receiptId',
      );

      await ApiService.uploadImage(base64Image, receiptId: receiptId);

      // 3. App eke UI eka update karanawa
      await _loadData();
    } catch (e) {
      debugPrint('SmartScan: Error processing receipt: $e');
      setState(() => analysisError = "Error scanning: $e");
    } finally {
      setState(() => isAnalyzing = false);
    }
  }

  Future<String> _compressAndEncodeImage(String filePath) async {
    try {
      final bytes = await File(filePath).readAsBytes();
      final image = img_lib.decodeImage(bytes);
      if (image == null) {
        return base64Encode(bytes);
      }
      // Resize to max width 800px for speed and compactness
      final resized = image.width > 800
          ? img_lib.copyResize(image, width: 800)
          : image;
      final compressed = img_lib.encodeJpg(resized, quality: 75);
      return base64Encode(compressed);
    } catch (e) {
      debugPrint('SmartScan: Compression error, fallback: $e');
      final bytes = await File(filePath).readAsBytes();
      return base64Encode(bytes);
    }
  }
  // ==========================================================

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 75,
    );

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
              try {
                ApiService.deleteGalleryImage(id);
              } catch (e) {
                debugPrint('Failed to delete image on backend: $e');
              }
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
              try {
                ApiService.deleteReceipt(id);
              } catch (e) {
                debugPrint('Failed to delete receipt on backend: $e');
              }
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
                  child: IndexedStack(
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
              ],
            ),
            // FAB
            Positioned(
              bottom: 100,
              right: 16,
              child: FloatingActionButton(
                onPressed: _showImageSourceOptions,
                backgroundColor: const Color(0xFF8B5CF6),
                child: Icon(
                  isFabOpen ? Icons.close : Icons.add,
                  color: Colors.white,
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
                    child: _buildGalleryImage(img.base64),
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
            );
          },
        ),
      ],
    );
  }

  Widget _buildGalleryImage(String base64Str) {
    if (base64Str.isEmpty) {
      return const Center(
        child: Icon(Icons.image, color: Color(0xFF64748B), size: 48),
      );
    }
    try {
      final cleanBase64 = base64Str.replaceFirst(
        RegExp(r'data:image/\w+;base64,'),
        '',
      );
      final decodedBytes = base64Decode(cleanBase64.trim());
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.memory(
          decodedBytes,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
      );
    } catch (e) {
      debugPrint('Error decoding base64 image: $e');
      return const Center(
        child: Icon(Icons.broken_image, color: Colors.red, size: 48),
      );
    }
  }

  Widget _buildHistoryTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: receipts
          .map(
            (receipt) => Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B).withValues(alpha: 0.8),
                border: Border.all(color: const Color(0xFF334155)),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
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
                            const SizedBox(height: 4),
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
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'Total',
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Rs. ${receipt.total.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Color(0xFF818CF8),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
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
                  if (receipt.items.isNotEmpty) ...[
                    const Divider(
                      color: Color(0xFF334155),
                      height: 24,
                      thickness: 1,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        'ITEMS',
                        style: TextStyle(
                          color: const Color(0xFF8B5CF6).withValues(alpha: 0.8),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    ...receipt.items.map(
                      (item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              item.name,
                              style: const TextStyle(
                                color: Color(0xFFCBD5E1),
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              'Rs. ${item.price.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          )
          .toList(),
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
