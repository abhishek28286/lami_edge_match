import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:webview_flutter/webview_flutter.dart';

const String baseUrl = 'https://lami-edge-match.onrender.com';

// Global user profile storage for session
class UserProfile {
  static String phone = '';
  static String role = 'Contractor';
  static String city = '';
  static String state = '';
  static bool isRegistered = false;
}

void main() {
  runApp(const FlazzorMasterApp());
}

class FlazzorMasterApp extends StatelessWidget {
  const FlazzorMasterApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flazzor Master Suite',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const AuthScreen(),
    );
  }
}

// 1. SMART REGISTRATION & AUTH SCREEN (Mobile + OTP + Role + City/State)
class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  
  String _selectedRole = 'Contractor';
  bool _otpSent = false;
  bool _isLoading = false;

  void _sendOtp() {
    String phone = _phoneController.text.trim();
    String city = _cityController.text.trim();
    String state = _stateController.text.trim();

    if (phone.length < 10 || city.isEmpty || state.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Kripya Mobile, City aur State sahi se bharein.")),
      );
      return;
    }
    setState(() => _isLoading = true);
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _isLoading = false;
        _otpSent = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("OTP sent to +91 $phone (Demo OTP: 1234)")),
      );
    });
  }

  void _verifyOtp() {
    String otp = _otpController.text.trim();
    if (otp == "1234" || otp.length == 4) {
      UserProfile.phone = _phoneController.text.trim();
      UserProfile.role = _selectedRole;
      UserProfile.city = _cityController.text.trim();
      UserProfile.state = _stateController.text.trim();
      UserProfile.isRegistered = true;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MasterHomeScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid OTP! Kripya '1234' dalein.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF14233C),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 8,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Flazzor Interiors", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF14233C))),
                  const SizedBox(height: 4),
                  const Text("Pan-India B2B Furniture Suite", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    decoration: const InputDecoration(
                      labelText: "Mobile Number",
                      prefixText: "+91 ",
                      border: OutlineInputBorder(),
                      counterText: "",
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _selectedRole,
                    decoration: const InputDecoration(labelText: "Profession / Role", border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'Contractor', child: Text('ठेकेदार / कारपेंटर (Contractor)')),
                      DropdownMenuItem(value: 'Architect', child: Text('आर्किटेक्ट / डिजाइनर (Architect)')),
                      DropdownMenuItem(value: 'FactoryOwner', child: Text('फैक्ट्री ओनर (Factory Owner)')),
                    ],
                    onChanged: (val) => setState(() => _selectedRole = val!),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _cityController,
                    decoration: const InputDecoration(labelText: "City (शहर)", border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _stateController,
                    decoration: const InputDecoration(labelText: "State (राज्य)", border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),
                  if (_otpSent) ...[
                    TextField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      decoration: const InputDecoration(
                        labelText: "Enter 4-digit OTP",
                        border: OutlineInputBorder(),
                        counterText: "",
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF14233C),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: _isLoading ? null : (_otpSent ? _verifyOtp : _sendOtp),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(_otpSent ? "Verify OTP & Enter" : "Get OTP & Register", style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// 2. MASTER HOME SCREEN
class MasterHomeScreen extends StatefulWidget {
  const MasterHomeScreen({Key? key}) : super(key: key);

  @override
  State<MasterHomeScreen> createState() => _MasterHomeScreenState();
}

class _MasterHomeScreenState extends State<MasterHomeScreen> {
  int laminateCredits = 5;
  int edgeCredits = 5;
  int cutListCredits = 5;
  bool isSubscribed = false;

  void _showSubscriptionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.workspace_premium, color: Colors.amber, size: 28),
            SizedBox(width: 8),
            Text("Flazzor Pro Pass"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text("Ads dekhne ki jhanjhat hamesha ke liye khatm karein!", style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text("✅ Unlimited Laminate & Edge Matching"),
            Text("✅ Unlimited CutList Optimizer"),
            Text("✅ No Video Ads / No Credit Limits"),
            SizedBox(height: 15),
            Text("Sirf ₹199 / Month", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white),
            onPressed: () {
              setState(() => isSubscribed = true);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("🎉 Congratulations! You are now a Flazzor Pro Member.")),
              );
            },
            child: const Text("Subscribe Now (₹199)"),
          ),
        ],
      ),
    );
  }

  void _showCreditPopup(String toolName, Function onCreditsAdded) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Out of $toolName Credits!"),
        content: const Text("Aapke free credits khatam ho gaye hain. 30 sec ka reward video dekh kar free credits lein!"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade800, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(context);
              onCreditsAdded();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("🎉 Reward video watched successfully! +5 Credits added.")),
              );
            },
            child: const Text("Watch 30s Video (+5 Credits)"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF14233C),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Flazzor Interiors", style: TextStyle(color: Colors.white, fontSize: 15)),
                Text("${UserProfile.role} | ${UserProfile.city}", style: const TextStyle(color: Colors.blueAccent, fontSize: 11)),
              ],
            ),
            GestureDetector(
              onTap: _showSubscriptionDialog,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isSubscribed ? Colors.green : Colors.amber.shade700,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isSubscribed ? "PRO ⭐" : "Get Pro ₹199",
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
      body: Container(
        color: Colors.grey.shade50,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("FLAZZOR MASTER SUITE", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF14233C), letterSpacing: 1.1)),
                const SizedBox(height: 6),
                const Text("Select Tool to Start Operation", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.blueAccent)),
                const SizedBox(height: 30),
                Wrap(
                  spacing: 15,
                  runSpacing: 15,
                  alignment: WrapAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        if (isSubscribed || laminateCredits > 0) {
                          if (!isSubscribed) setState(() => laminateCredits--);
                          Navigator.push(context, MaterialPageRoute(builder: (context) => LaminateMatchingScreen(isSubscribed: isSubscribed)));
                        } else {
                          _showCreditPopup("Laminate Matching", () => setState(() => laminateCredits += 5));
                        }
                      },
                      icon: const Icon(Icons.layers, size: 22),
                      label: Text("Laminate Matching\n(Credits: ${isSubscribed ? '∞' : laminateCredits})"),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade800, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12)),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        if (isSubscribed || edgeCredits > 0) {
                          if (!isSubscribed) setState(() => edgeCredits--);
                          Navigator.push(context, MaterialPageRoute(builder: (context) => EdgeBandingScreen(isSubscribed: isSubscribed)));
                        } else {
                          _showCreditPopup("Edge Banding", () => setState(() => edgeCredits += 5));
                        }
                      },
                      icon: const Icon(Icons.border_style, size: 22),
                      label: Text("Edge Banding\n(Credits: ${isSubscribed ? '∞' : edgeCredits})"),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12)),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        if (isSubscribed || cutListCredits > 0) {
                          if (!isSubscribed) setState(() => cutListCredits--);
                          // 🚀 सीधा HTML कटलिस्ट ऑप्टिमाइज़र इन-ऐप WebView में खुलेगा
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CutListDirectScreen(url: '$baseUrl/cutlist_optimizer'),
                            ),
                          );
                        } else {
                          _showCreditPopup("CutList Optimizer", () => setState(() => cutListCredits += 5));
                        }
                      },
                      icon: const Icon(Icons.dashboard_customize, size: 22),
                      label: Text("CutList Optimizer\n(Credits: ${isSubscribed ? '∞' : cutListCredits})"),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade800, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 35),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TrainingManualScreen())),
                      icon: const Icon(Icons.menu_book, size: 18),
                      label: const Text("📚 ट्रेनिंग मैनुअल (हिंदी)"),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade700, foregroundColor: Colors.white),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CatalogRequestScreen())),
                      icon: const Icon(Icons.folder_shared, size: 18),
                      label: const Text("📂 Add Catalog (₹200)"),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.purple.shade700, foregroundColor: Colors.white),
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
}
// 2.5 CutList In-App WebView Screen (HTML कटलिस्ट टूल को ऐप के अंदर खोलेगा)
class CutListDirectScreen extends StatefulWidget {
  final String url;
  const CutListDirectScreen({Key? key, required this.url}) : super(key: key);

  @override
  State<CutListDirectScreen> createState() => _CutListDirectScreenState();
}

class _CutListDirectScreenState extends State<CutListDirectScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF14233C))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            setState(() => _isLoading = false);
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF14233C),
        title: const Text("Flazzor CutList Optimizer Pro", style: TextStyle(color: Colors.white, fontSize: 16)),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: Color(0xFF14233C))),
        ],
      ),
    );
  }
}

// 2.6 Training Manual Screen (हिंदी गाइड)
class TrainingManualScreen extends StatelessWidget {
  const TrainingManualScreen({Key? key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: const Color(0xFF14233C), title: const Text("📚 हिंदी ट्रेनिंग मैनुअल")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text("✂️ कटलिस्ट ऑप्टिमाइज़र कैसे चलाएं?", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF14233C))),
            SizedBox(height: 8),
            Text("1. सबसे पहले स्टॉक मटेरियल मास्टर में अपनी प्लाई का साइज जांच लें।\n2. नीचे पैनल लिस्ट में पार्ट का नाम, लंबाई, चौड़ाई और मात्रा भरें।\n3. आखिरी कॉलम में Tab दबाते ही नई लाइन अपने आप आ जाएगी।\n4. RUN OPTIMIZATION दबाएं, 5 सेकंड का शॉर्ट ऐड देखने के बाद सुंदर लेआउट और मास्टर समरी सामने आ जाएगी।"),
            Divider(height: 30),
            Text("📂 अपना खुद का कैटलॉग कैसे जुड़वाएं?", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF14233C))),
            SizedBox(height: 8),
            Text("यदि आपके पास कोई लेमिनेट या प्लाईवुड कैटलॉग है, तो होमपेज पर 'Add Catalog (₹200)' बटन दबाकर फॉर्म भरें। हमारी टीम वेरिफिकेशन के बाद उसे मात्र ₹200 शुल्क में जोड़ देगी।"),
          ],
        ),
      ),
    );
  }
}

// 2.7 Catalog Request Screen (₹200 Paid Service)
class CatalogRequestScreen extends StatefulWidget {
  const CatalogRequestScreen({Key? key});

  @override
  State<CatalogRequestScreen> createState() => _CatalogRequestScreenState();
}

class _CatalogRequestScreenState extends State<CatalogRequestScreen> {
  final _firmController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _detailsController = TextEditingController();

  void _submitRequest() {
    if (_firmController.text.isEmpty || _phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Kripya Firm Name aur Phone number bharein!")));
      return;
    }
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Request Submitted!"),
        content: const Text("آپ کی کیٹلاگ ریکوئسٹ Flazzor ٹیم کو بھیج دی گئی ہے۔ ₹200 پیمنٹ کی جانچ کے بعد آپ کا کیٹلاگ لائیو کر دیا جائے گا۔"),
        actions: [
          ElevatedButton(onPressed: () { Navigator.pop(context); Navigator.pop(context); }, child: const Text("OK"))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: const Color(0xFF14233C), title: const Text("📂 Custom Catalog Request (₹200)")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _firmController, decoration: const InputDecoration(labelText: "Firm / Company Name", border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: "Contact Person Name", border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _phoneController, keyboardType: TextInputType.phone, maxLength: 10, decoration: const InputDecoration(labelText: "WhatsApp Number", border: OutlineInputBorder(), counterText: "")),
            const SizedBox(height: 12),
            TextField(controller: _detailsController, maxLines: 3, decoration: const InputDecoration(labelText: "Catalog Details / PDF Link", border: OutlineInputBorder())),
            const SizedBox(height: 15),
            const Text("⚠️ शुल्क: वेरिफिकेशन और डेटा एंट्री मात्र ₹200 प्रति कैटलॉग।", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purple.shade700, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
              onPressed: _submitRequest,
              child: const Center(child: Text("Send Catalog Request", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold))),
            ),
          ],
        ),
      ),
    );
  }
}

// 3. LAMINATE MATCHING SCREEN (Existing Backend Connected)
class LaminateMatchingScreen extends StatefulWidget {
  final bool isSubscribed;
  const LaminateMatchingScreen({Key? key, required this.isSubscribed}) : super(key: key);

  @override
  _LaminateMatchingScreenState createState() => _LaminateMatchingScreenState();
}

class _LaminateMatchingScreenState extends State<LaminateMatchingScreen> {
  List<String> _allBrands = [];
  final Map<String, bool> _selectedBrandsMap = {};
  Uint8List? _imageBytes;
  String _fileName = '';
  bool _isLoading = false;
  List<dynamic> _matchResults = [];
  double _cropX = 0.5, _cropY = 0.5;

  @override
  void initState() {
    super.initState();
    _fetchBrands();
  }

  Future<void> _fetchBrands() async {
    try {
      var response = await http.get(Uri.parse('$baseUrl/get_brands'));
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        List<String> brands = List<String>.from((data['laminate_brands'] ?? []).map((e) => e.toString()));
        setState(() {
          _allBrands = brands;
          for (var b in brands) _selectedBrandsMap[b] = true;
        });
      }
    } catch (e) {
      print("Error fetching brands: $e");
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? file = await ImagePicker().pickImage(source: source);
    if (file == null) return;
    var bytes = await file.readAsBytes();
    setState(() {
      _imageBytes = bytes;
      _fileName = file.name;
      _matchResults = [];
    });
  }

  Future<void> _matchLaminateImage() async {
    if (_imageBytes == null) return;
    List<String> activeBrands = _selectedBrandsMap.entries.where((e) => e.value).map((e) => e.key).toList();
    if (activeBrands.isEmpty) return;
    setState(() => _isLoading = true);

    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/match_laminate'));
      request.fields['brands'] = activeBrands.join(',');
      request.fields['crop_x'] = _cropX.toString();
      request.fields['crop_y'] = _cropY.toString();
      request.files.add(http.MultipartFile.fromBytes('image', _imageBytes!, filename: _fileName.isNotEmpty ? _fileName : 'upload.jpg'));

      var res = await http.Response.fromStream(await request.send());
      if (res.statusCode == 200) {
        setState(() {
          _matchResults = json.decode(res.body)['matches'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: const Color(0xFF14233C), title: const Text("Flazzor Laminate Matching")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(onPressed: () => _pickImage(ImageSource.gallery), icon: const Icon(Icons.image), label: const Text("Gallery")),
                ElevatedButton.icon(onPressed: () => _pickImage(ImageSource.camera), icon: const Icon(Icons.camera_alt), label: const Text("Camera"), style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white)),
              ],
            ),
            const SizedBox(height: 12),
            if (_imageBytes != null) ...[
              Container(
                height: 180,
                decoration: BoxDecoration(border: Border.all(color: Colors.blue, width: 2)),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return GestureDetector(
                      onTapDown: (d) => setState(() {
                        _cropX = d.localPosition.dx / constraints.maxWidth;
                        _cropY = d.localPosition.dy / constraints.maxHeight;
                      }),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.memory(_imageBytes!, fit: BoxFit.cover),
                          Positioned(
                            left: (_cropX * constraints.maxWidth) - 20,
                            top: (_cropY * constraints.maxHeight) - 20,
                            child: Container(width: 40, height: 40, decoration: BoxDecoration(border: Border.all(color: Colors.yellow, width: 2), color: Colors.black26)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _isLoading ? null : _matchLaminateImage,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade800, foregroundColor: Colors.white),
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("MATCH START (5s Ad Sim)"),
              ),
            ],
            const SizedBox(height: 15),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _matchResults.length,
              itemBuilder: (context, index) {
                var item = _matchResults[index];
                double score = (item['score'] ?? 0) * 100;
                return Card(
                  child: ListTile(
                    leading: Image.network('$baseUrl/laminate/${item['filename']}', width: 45, height: 45, fit: BoxFit.cover, errorBuilder: (c,e,s) => const Icon(Icons.image)),
                    title: Text("Rank ${index + 1} - ${item['brand']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("Code: ${item['name']}"),
                    trailing: Text("${score.toStringAsFixed(1)}%", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// 4. EDGE BANDING SCREEN
class EdgeBandingScreen extends StatefulWidget {
  final bool isSubscribed;
  const EdgeBandingScreen({Key? key, required this.isSubscribed}) : super(key: key);

  @override
  _EdgeBandingScreenState createState() => _EdgeBandingScreenState();
}

class _EdgeBandingScreenState extends State<EdgeBandingScreen> {
  bool advanceEdge = true, squareOne = true;
  Uint8List? _imageBytes;
  String _fileName = '';
  bool _isLoading = false;
  List<dynamic> _matchResults = [];

  Future<void> _pickImage(ImageSource source) async {
    final XFile? file = await ImagePicker().pickImage(source: source);
    if (file == null) return;
    var bytes = await file.readAsBytes();
    setState(() { _imageBytes = bytes; _fileName = file.name; _matchResults = []; });
  }

  Future<void> _matchEdge() async {
    if (_imageBytes == null) return;
    setState(() => _isLoading = true);
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/match'));
      request.fields['brands'] = "advance_edge,square_one";
      request.files.add(http.MultipartFile.fromBytes('image', _imageBytes!, filename: _fileName.isNotEmpty ? _fileName : 'upload.jpg'));
      var res = await http.Response.fromStream(await request.send());
      if (res.statusCode == 200) {
        setState(() { _matchResults = json.decode(res.body)['matches'] ?? []; _isLoading = false; });
      } else { setState(() => _isLoading = false); }
    } catch (e) { setState(() => _isLoading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: const Color(0xFF14233C), title: const Text("Flazzor Edge Banding Matching")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(onPressed: () => _pickImage(ImageSource.gallery), icon: const Icon(Icons.image), label: const Text("Gallery")),
                ElevatedButton.icon(onPressed: () => _pickImage(ImageSource.camera), icon: const Icon(Icons.camera_alt), label: const Text("Camera"), style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white)),
              ],
            ),
            const SizedBox(height: 10),
            if (_imageBytes != null) ...[
              SizedBox(height: 180, child: Image.memory(_imageBytes!, fit: BoxFit.cover)),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _isLoading ? null : _matchEdge,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade800, foregroundColor: Colors.white),
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("MATCH START"),
              ),
            ],
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _matchResults.length,
              itemBuilder: (context, index) {
                var item = _matchResults[index];
                return ListTile(
                  title: Text("Rank ${index + 1} - ${item['brand']} (${item['name']})"),
                  trailing: Text("${((item['score'] ?? 0) * 100).toStringAsFixed(1)}%"),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}