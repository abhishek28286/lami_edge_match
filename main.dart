import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:share_plus/share_plus.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String baseUrl = 'https://lami-edge-match.onrender.com';

class UserProfile {
  static String phone = '';
  static String role = 'Contractor';
  static String city = 'Udaipur';
  static String state = 'Rajasthan';
  static bool isRegistered = false;

  static Future<void> saveSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('phone', phone);
    await prefs.setString('role', role);
    await prefs.setString('city', city);
    await prefs.setString('state', state);
    await prefs.setBool('isRegistered', true);
  }

  static Future<bool> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    bool registered = prefs.getBool('isRegistered') ?? false;
    if (registered) {
      phone = prefs.getString('phone') ?? '';
      role = prefs.getString('role') ?? 'Contractor';
      city = prefs.getString('city') ?? 'Udaipur';
      state = prefs.getString('state') ?? 'Rajasthan';
      isRegistered = true;
    }
    return registered;
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    phone = '';
    role = 'Contractor';
    city = 'Udaipur';
    state = 'Rajasthan';
    isRegistered = false;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  bool loggedIn = await UserProfile.loadSession();

  try {
    await MobileAds.instance.initialize();
  } catch (e) {
    print("AdMob initialization error: $e");
  }

  runApp(FlazzorMasterApp(isLoggedIn: loggedIn));
}

class FlazzorMasterApp extends StatelessWidget {
  final bool isLoggedIn;
  const FlazzorMasterApp({Key? key, required this.isLoggedIn}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'WoodMat',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: isLoggedIn ? const MasterHomeScreen() : const AuthScreen(),
    );
  }
}

// Reusable Google AdMob Banner Widget
class GoogleAdMobBannerWidget extends StatefulWidget {
  const GoogleAdMobBannerWidget({Key? key}) : super(key: key);

  @override
  State<GoogleAdMobBannerWidget> createState() => _GoogleAdMobBannerWidgetState();
}

class _GoogleAdMobBannerWidgetState extends State<GoogleAdMobBannerWidget> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-3940256099942544/6300978111', 
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) setState(() => _isAdLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isAdLoaded && _bannerAd != null) {
      return Container(
        alignment: Alignment.center,
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: AdWidget(ad: _bannerAd!),
      );
    }
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: Colors.grey.shade200,
      alignment: Alignment.center,
      child: const Text("Google AdMob Banner Space", style: TextStyle(fontSize: 10, color: Colors.grey)),
    );
  }
}

// 1. SMART REGISTRATION & AUTH SCREEN
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
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _otpSent = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("OTP sent to +91 $phone (Demo OTP: 1234)")),
      );
    });
  }

  void _verifyOtp() async {
    String otp = _otpController.text.trim();
    if (otp == "1234" || otp.length == 4) {
      UserProfile.phone = _phoneController.text.trim();
      UserProfile.role = _selectedRole;
      UserProfile.city = _cityController.text.trim();
      UserProfile.state = _stateController.text.trim();
      UserProfile.isRegistered = true;

      await UserProfile.saveSession();

      if (!mounted) return;
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
                  const GoogleAdMobBannerWidget(),
                  const Text("WoodMat", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF14233C))),
                  const SizedBox(height: 4),
                  const Text("Pan-India B2B Furniture Suite (Flazzor)", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    decoration: const InputDecoration(labelText: "Mobile Number", prefixText: "+91 ", border: OutlineInputBorder(), counterText: ""),
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
                    onChanged: (val) => setState(() => _selectedRole = val ?? 'Contractor'),
                  ),
                  const SizedBox(height: 12),
                  TextField(controller: _cityController, decoration: const InputDecoration(labelText: "City (शहर)", border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(controller: _stateController, decoration: const InputDecoration(labelText: "State (राज्य)", border: OutlineInputBorder())),
                  const SizedBox(height: 16),
                  if (_otpSent) ...[
                    TextField(controller: _otpController, keyboardType: TextInputType.number, maxLength: 4, decoration: const InputDecoration(labelText: "Enter 4-digit OTP", border: OutlineInputBorder(), counterText: "")),
                    const SizedBox(height: 16),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF14233C), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
                      onPressed: _isLoading ? null : (_otpSent ? _verifyOtp : _sendOtp),
                      child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : Text(_otpSent ? "Verify OTP & Enter" : "Get OTP & Register", style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
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
        title: const Row(children: [Icon(Icons.workspace_premium, color: Colors.amber, size: 28), SizedBox(width: 8), Text("Flazzor Pro Pass")]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text("Ads dekhne ki jhanjhat hamesha ke liye khatm karein!", style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text("✅ Unlimited Laminate & Edge Matching"),
            Text("✅ Unlimited CutList Optimizer"),
            Text("✅ No Google Ads / No Credit Limits"),
            SizedBox(height: 15),
            Text("Sirf ₹199 / Month", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white),
            onPressed: () {
              if (mounted) setState(() => isSubscribed = true);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("🎉 Congratulations! You are now a Flazzor Pro Member.")));
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
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("🎉 Reward video watched! +5 Credits added.")));
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
                const Text("WoodMat", style: TextStyle(color: Colors.white, fontSize: 15)),
                Text("${UserProfile.role} | ${UserProfile.city}", style: const TextStyle(color: Colors.blueAccent, fontSize: 11)),
              ],
            ),
            Row(
              children: [
                GestureDetector(
                  onTap: _showSubscriptionDialog,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: isSubscribed ? Colors.green : Colors.amber.shade700, borderRadius: BorderRadius.circular(15)),
                    child: Text(isSubscribed ? "PRO ⭐" : "Pro ₹199", style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.white, size: 18),
                  onPressed: () async {
                    await UserProfile.clearSession();
                    if (!mounted) return;
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AuthScreen()));
                  },
                ),
              ],
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
                const GoogleAdMobBannerWidget(),
                const Text("WOODMAT MASTER SUITE", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF14233C), letterSpacing: 1.1)),
                const SizedBox(height: 6),
                const Text("Flazzor Interiors B2B Solution", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.blueAccent)),
                const SizedBox(height: 30),
                Wrap(
                  spacing: 15,
                  runSpacing: 15,
                  alignment: WrapAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        if (isSubscribed || laminateCredits > 0) {
                          if (!isSubscribed && mounted) setState(() => laminateCredits--);
                          Navigator.push(context, MaterialPageRoute(builder: (context) => LaminateMatchingScreen(isSubscribed: isSubscribed)));
                        } else {
                          _showCreditPopup("Laminate Matching", () => { if (mounted) setState(() => laminateCredits += 5) });
                        }
                      },
                      icon: const Icon(Icons.layers, size: 22),
                      label: Text("Laminate Matching\n(Credits: ${isSubscribed ? '∞' : laminateCredits})"),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade800, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12)),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        if (isSubscribed || edgeCredits > 0) {
                          if (!isSubscribed && mounted) setState(() => edgeCredits--);
                          Navigator.push(context, MaterialPageRoute(builder: (context) => EdgeBandingScreen(isSubscribed: isSubscribed)));
                        } else {
                          _showCreditPopup("Edge Banding", () => { if (mounted) setState(() => edgeCredits += 5) });
                        }
                      },
                      icon: const Icon(Icons.border_style, size: 22),
                      label: Text("Edge Banding\n(Credits: ${isSubscribed ? '∞' : edgeCredits})"),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12)),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        if (isSubscribed || cutListCredits > 0) {
                          if (!isSubscribed && mounted) setState(() => cutListCredits--);
                          Navigator.push(context, MaterialPageRoute(builder: (context) => CutListDirectScreen(url: '$baseUrl/cutlist_optimizer')));
                        } else {
                          _showCreditPopup("CutList Optimizer", () => { if (mounted) setState(() => cutListCredits += 5) });
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
                const SizedBox(height: 15),
                const GoogleAdMobBannerWidget(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// 2.5 CutList WebView Screen with Built-in Share Action Button
class CutListDirectScreen extends StatefulWidget {
  final String url;
  const CutListDirectScreen({Key? key, required this.url}) : super(key: key);

  @override
  State<CutListDirectScreen> createState() => _CutListDirectScreenState();
}

class _CutListDirectScreenState extends State<CutListDirectScreen> {
  WebViewController? _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    try {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0xFF14233C))
        ..setNavigationDelegate(NavigationDelegate(
          onPageFinished: (String url) { if (mounted) setState(() => _isLoading = false); },
          onWebResourceError: (error) { if (mounted) setState(() => _isLoading = false); },
        ))
        ..loadRequest(Uri.parse(widget.url));
    } catch (e) {
      _isLoading = false;
    }
  }

  void _shareCutListReport() {
    Share.share(
      "Check out WoodMat CutList Optimizer Report from Flazzor Interiors, Udaipur!\nAccess the tool here: ${widget.url}",
      subject: "WoodMat CutList Optimizer Report",
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF14233C),
        title: const Text("WoodMat CutList Optimizer Pro", style: TextStyle(color: Colors.white, fontSize: 16)),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            tooltip: "Share CutList Report",
            onPressed: _shareCutListReport,
          ),
        ],
      ),
      body: Stack(
        children: [
          if (_controller != null)
            WebViewWidget(controller: _controller!),
          if (_isLoading) const Center(child: CircularProgressIndicator(color: Color(0xFF14233C))),
        ],
      ),
    );
  }
}

// 2.6 Training Manual Screen
class TrainingManualScreen extends StatelessWidget {
  const TrainingManualScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: const Color(0xFF14233C), title: const Text("📚 Flazzor हिंदी ट्रेनिंग मैनुअल")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            GoogleAdMobBannerWidget(),
            SizedBox(height: 10),
            Text("📚 WoodMat / Flazzor Master Suite - आधिकारिक हिंदी ट्रेनिंग मैनुअल", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF14233C))),
            Text("फर्म: Flazzor Interiors, Udaipur (उदयपुर, राजस्थान)\nअनुभव: 20+ वर्ष मॉड्यूलर फर्नीचर निर्माण और बी2बी सॉल्यूशंस", style: TextStyle(fontSize: 12, color: Colors.grey)),
            Divider(height: 30),
            
            Text("✂️ 1. कटलिस्ट ऑप्टिमाइज़र (CutList Optimizer)", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF14233C))),
            SizedBox(height: 4),
            Text("• स्टॉक मटेरियल मास्टर: स्टॉक शीट की साइज (जैसे मानक 8x4 फीट प्लाईवुड) और ब्लेड की मोटाई (Kerf) सेट करें。\n• पैनल लिस्ट: फर्नीचर डिजाइन के अनुसार हर पीस का नाम, लंबाई, चौड़ाई और आवश्यक पीस की संख्या भरें。\n• ऑप्टिमाइज़ेशन: 'Calculate / Optimize' दबाकर कम से कम शीट वेस्टेज के साथ कटिंग लेआउट प्राप्त करें।"),
            Divider(height: 30),

            Text("🎨 2. लेमिनेट मैचिंग (Laminate Matching)", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF14233C))),
            SizedBox(height: 4),
            Text("• ब्रांड सिलेक्शन: एक्सपेंशन बॉक्स से अपने मनपसंद या आवश्यक ब्रांड्स को चुनें या 'Select All' करें。\n• फोटो अपलोड: गैलरी या कैमरे से लेमिनेट की स्पष्ट फोटो अपलोड करें。\n• क्रॉस-हेयर: पीले रंग के चौकोर बॉक्स को खींचकर (Drag करके) सही शेड पर रखें。\n• मैच स्टार्ट: बटन दबाएं और विज्ञापन के बाद टॉप 5 नज़दीकी शेड कोड और मैचिंग प्रतिशत (%) देखें।"),
            Divider(height: 30),

            Text("📐 3. एज बैंडिंग मैचिंग (Edge Banding Matching)", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF14233C))),
            SizedBox(height: 4),
            Text("• कैटलॉग मोड: सीधे लेमिनेट ब्रांड और कोड चुनकर शेड इमेज ऑटोमैटिक लोड करें。\n• डायरेक्ट मोड: गैलरी या कैमरे से फोटो अपलोड करें。\n• एज ब्रांड्स: अपने पास उपलब्ध एज बैंडिंग ब्रांड्स (जैसे Advance Edge, E3, Pegasus, Rehau) चुनें。\n• मैचिंग: क्रॉस-हेयर सेट करके मैच शुरू करें और सटीक एज बैंड शेड व रिपोर्ट प्राप्त करें।"),
            
            SizedBox(height: 15),
            GoogleAdMobBannerWidget(),
          ],
        ),
      ),
    );
  }
}

// 2.7 Catalog Request Screen
class CatalogRequestScreen extends StatefulWidget {
  const CatalogRequestScreen({Key? key}) : super(key: key);

  @override
  State<CatalogRequestScreen> createState() => _CatalogRequestScreenState();
}

class _CatalogRequestScreenState extends State<CatalogRequestScreen> {
  final _firmController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _detailsController = TextEditingController();
  
  String _pdfFileName = '';
  bool _isPdfUploaded = false;

  Future<void> _pickPdfFile() async {
    try {
      final XFile? file = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (file != null && mounted) {
        setState(() {
          _pdfFileName = file.name;
          _isPdfUploaded = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("📁 Catalog File Uploaded: $_pdfFileName"))
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error uploading file!"))
        );
      }
    }
  }

  void _submitCatalogRequest() {
    String firm = _firmController.text.trim();
    String name = _nameController.text.trim();
    String phone = _phoneController.text.trim();

    if (firm.isEmpty || name.isEmpty || phone.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Kripya Firm Name, Contact Name aur Valid Mobile Number bharein!"))
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("✅ Catalog request submitted successfully! Abhishek (@abhishek28286) will contact you."))
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: const Color(0xFF14233C), title: const Text("📂 Custom Catalog Request (₹200)")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const GoogleAdMobBannerWidget(),
            const SizedBox(height: 10),
            
            const Text("Add Your Brand Catalog", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF14233C))),
            const Text("Reach thousands of B2B furniture professionals across India.", style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 15),

            TextField(
              controller: _firmController, 
              decoration: const InputDecoration(labelText: "Firm / Company Name", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _nameController, 
              decoration: const InputDecoration(labelText: "Contact Person Name", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              decoration: const InputDecoration(labelText: "Contact Mobile Number", prefixText: "+91 ", border: OutlineInputBorder(), counterText: ""),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _detailsController, 
              maxLines: 3, 
              decoration: const InputDecoration(labelText: "Catalog Description / Notes", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 15),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(6)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      _isPdfUploaded ? "Selected File: $_pdfFileName" : "Upload Catalog PDF / Images",
                      style: TextStyle(fontSize: 13, color: _isPdfUploaded ? Colors.green.shade700 : Colors.grey.shade700, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _pickPdfFile,
                    icon: const Icon(Icons.upload_file, size: 16),
                    label: const Text("Browse PDF"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade800, foregroundColor: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),

            const Text("⚠️ शुल्क: वेरिफिकेशन मात्र ₹200 प्रति कैटलॉग।", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),

            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700, 
                foregroundColor: Colors.white, 
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _submitCatalogRequest,
              icon: const Icon(Icons.chat),
              label: const Text("Submit Catalog Request", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 15),

            const GoogleAdMobBannerWidget(),
          ],
        ),
      ),
    );
  }
}

// 3. LAMINATE MATCHING SCREEN
class LaminateMatchingScreen extends StatefulWidget {
  final bool isSubscribed;
  const LaminateMatchingScreen({Key? key, this.isSubscribed = false}) : super(key: key);

  @override
  _LaminateMatchingScreenState createState() => _LaminateMatchingScreenState();
}

class _LaminateMatchingScreenState extends State<LaminateMatchingScreen> {
  List<String> _allBrands = [];
  final Map<String, bool> _selectedBrandsMap = {};
  Uint8List? _imageBytes;
  String _fileName = '';
  bool _isLoading = false;
  bool _isBrandsLoading = true;
  List<dynamic> _matchResults = [];
  double _cropX = 0.5, _cropY = 0.5;

  final ScreenshotController _screenshotController = ScreenshotController();

  @override
  void initState() {
    super.initState();
    _fetchBrands();
  }

  Future<void> _fetchBrands() async {
    if (!mounted) return;
    setState(() => _isBrandsLoading = true);
    try {
      var response = await http.get(Uri.parse('$baseUrl/get_brands'));
      if (response.statusCode == 200 && mounted) {
        var data = json.decode(response.body);
        if (data is Map && data['laminate_brands'] != null) {
          List<String> brands = List<String>.from((data['laminate_brands'] as List).map((e) => e.toString()));
          setState(() {
            _allBrands = brands;
            _selectedBrandsMap.clear();
            for (var b in brands) {
              _selectedBrandsMap[b] = true;
            }
          });
        }
      }
    } catch (e) {
      print("Error fetching brands: $e");
    } finally {
      if (mounted) {
        setState(() => _isBrandsLoading = false);
      }
    }
  }

  void _selectAllBrands(bool select) {
    setState(() {
      for (var b in _allBrands) {
        _selectedBrandsMap[b] = select;
      }
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? file = await ImagePicker().pickImage(source: source);
    if (file == null || !mounted) return;
    var bytes = await file.readAsBytes();
    setState(() {
      _imageBytes = bytes;
      _fileName = file.name;
      _matchResults = [];
    });
  }

  void _showAdBeforeMatch(Function onAdFinished) {
    if (widget.isSubscribed) {
      onAdFinished();
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        int secondsLeft = 6;
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            Future.delayed(const Duration(seconds: 1), () {
              if (secondsLeft > 1) {
                if (mounted && setStateDialog != null) {
                  try {
                    setStateDialog(() {
                      if (secondsLeft > 0) {
                        secondsLeft--;
                      }
                    });
                  } catch (e) {}
                }
              } else {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                  onAdFinished();
                }
              }
            });

            return AlertDialog(
              backgroundColor: const Color(0xFF14233C),
              title: const Text("Google AdMob Interstitial Ad", style: TextStyle(color: Colors.amber, fontSize: 16)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Sponsored Advertisement\nUpgrade to Pro (@ ₹199) to remove all ads!", style: TextStyle(color: Colors.white, fontSize: 13), textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  Text("Ad closing in ${secondsLeft}s...", style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  const LinearProgressIndicator(color: Colors.amber),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    onAdFinished();
                  },
                  child: const Text("Skip Ad", style: TextStyle(color: Colors.white70)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _matchLaminateImage() async {
    if (_imageBytes == null) return;
    List<String> activeBrands = _selectedBrandsMap.entries.where((e) => e.value).map((e) => e.key).toList();
    if (activeBrands.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Kripya kam se kam ek brand chunein!")));
      return;
    }

    _showAdBeforeMatch(() async {
      if (!mounted) return;
      setState(() => _isLoading = true);
      try {
        var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/match_laminate'));
        request.fields['brands'] = activeBrands.join(',');
        request.fields['crop_x'] = _cropX.toString();
        request.fields['crop_y'] = _cropY.toString();
        request.files.add(http.MultipartFile.fromBytes('image', _imageBytes!, filename: _fileName.isNotEmpty ? _fileName : 'upload.jpg'));

        var res = await http.Response.fromStream(await request.send());
        if (res.statusCode == 200 && mounted) {
          var decodedBody = json.decode(res.body);
          setState(() {
            _matchResults = (decodedBody is Map && decodedBody['matches'] != null) ? decodedBody['matches'] : [];
            _isLoading = false;
          });
        } else if (mounted) {
          setState(() => _isLoading = false);
        }
      } catch (e) {
        if (mounted) setState(() => _isLoading = false);
      }
    });
  }

  Widget _buildReportCardWidget() {
    return Container(
      width: 400,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade900, width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(6)),
            child: const Text(
              "✨ This card is made by WoodMat, a perfect laminate & edge banding matching app present on Google Play Store.",
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF14233C)),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 12),
          const Text("🏆 Flazzor WoodMat - Laminate Report", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF14233C)), textAlign: TextAlign.center),
          const SizedBox(height: 10),

          if (_imageBytes != null) ...[
            const Text("Uploaded Photo:", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(_imageBytes!, height: 90, width: 90, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 10),
          ],

          const Text("Top Matching Results:", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),

          ..._matchResults.asMap().entries.map((entry) {
            int index = entry.key;
            var item = entry.value;
            double score = ((item is Map ? item['score'] : 0) ?? 0) * 100;
            String brand = (item is Map ? item['brand'] : '') ?? '';
            String category = (item is Map ? item['category'] : 'solid') ?? 'solid';
            String filename = (item is Map ? item['filename'] : '') ?? '';
            String itemName = (item is Map ? item['name'] : '') ?? '';
            String thumbUrl = '$baseUrl/laminate/$brand/$category/$filename';

            return Container(
              margin: const EdgeInsets.symmetric(vertical: 3),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(6)),
              child: Row(
                children: [
                  Image.network(thumbUrl, width: 35, height: 35, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.broken_image, size: 30)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Rank ${index + 1} - $brand", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        Text("Code: $itemName", style: const TextStyle(fontSize: 10, color: Colors.grey)),
                      ],
                    ),
                  ),
                  Text("${score.toStringAsFixed(1)}%", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green)),
                ],
              ),
            );
          }).toList(),

          const SizedBox(height: 10),
          const Divider(),
          const Text("📍 Flazzor Interiors, Udaipur | 20+ Years Experience", style: TextStyle(fontSize: 9, color: Colors.grey), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Future<void> _exportAndShareJpg() async {
    if (_matchResults.isEmpty) return;

    try {
      final Uint8List imageBytes = await _screenshotController.captureFromWidget(
        Material(child: _buildReportCardWidget()),
        delay: const Duration(milliseconds: 100),
      );

      final directory = await getTemporaryDirectory();
      final imagePath = await File('${directory.path}/woodmat_laminate_report.jpg').create();
      await imagePath.writeAsBytes(imageBytes);

      if (mounted) {
        await Share.shareXFiles([XFile(imagePath.path)], text: "Flazzor WoodMat Laminate Matching Report");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error exporting JPG: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool allSelected = _allBrands.isNotEmpty && _allBrands.every((b) => _selectedBrandsMap[b] == true);
    int selectedCount = _selectedBrandsMap.values.where((v) => v).length;

    return Scaffold(
      appBar: AppBar(backgroundColor: const Color(0xFF14233C), title: const Text("WoodMat Laminate Matching")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const GoogleAdMobBannerWidget(),
            
            if (_isBrandsLoading) ...[
              Container(
                padding: const EdgeInsets.all(20),
                alignment: Alignment.center,
                child: Column(
                  children: const [
                    CircularProgressIndicator(color: Color(0xFF14233C)),
                    SizedBox(height: 10),
                    Text("Loading Brands & Colors, Please Wait...", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                  ],
                ),
              ),
            ] else ...[
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                child: ExpansionTile(
                  title: Text("Select Brands ($selectedCount / ${_allBrands.length} Selected)", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: () => _selectAllBrands(!allSelected),
                        child: Text(allSelected ? "Deselect All" : "Select All", style: const TextStyle(fontSize: 11)),
                      ),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: SingleChildScrollView(
                        child: Wrap(
                          spacing: 6.0,
                          runSpacing: 4.0,
                          children: _allBrands.map((brand) {
                            return FilterChip(
                              label: Text(brand, style: const TextStyle(fontSize: 11)),
                              selected: _selectedBrandsMap[brand] ?? true,
                              onSelected: (bool selected) {
                                setState(() {
                                  _selectedBrandsMap[brand] = selected;
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 6),
            const GoogleAdMobBannerWidget(),
            const SizedBox(height: 6),
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
                height: 250,
                width: double.infinity,
                decoration: BoxDecoration(border: Border.all(color: Colors.blue, width: 2), color: Colors.black),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return GestureDetector(
                      onPanStart: (d) {
                        setState(() {
                          _cropX = (d.localPosition.dx / constraints.maxWidth).clamp(0.0, 1.0);
                          _cropY = (d.localPosition.dy / constraints.maxHeight).clamp(0.0, 1.0);
                        });
                      },
                      onPanUpdate: (d) {
                        setState(() {
                          _cropX = (d.localPosition.dx / constraints.maxWidth).clamp(0.0, 1.0);
                          _cropY = (d.localPosition.dy / constraints.maxHeight).clamp(0.0, 1.0);
                        });
                      },
                      onTapDown: (d) {
                        setState(() {
                          _cropX = (d.localPosition.dx / constraints.maxWidth).clamp(0.0, 1.0);
                          _cropY = (d.localPosition.dy / constraints.maxHeight).clamp(0.0, 1.0);
                        });
                      },
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.memory(_imageBytes!, fit: BoxFit.contain),
                          Positioned(
                            left: (_cropX * constraints.maxWidth) - 20,
                            top: (_cropY * constraints.maxHeight) - 20,
                            child: Container(
                              width: 40, 
                              height: 40, 
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.yellow, width: 3), 
                                color: Colors.yellow.withOpacity(0.3),
                              ),
                            ),
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
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("MATCH START", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
            const SizedBox(height: 15),
            const GoogleAdMobBannerWidget(),
            const SizedBox(height: 10),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _matchResults.length,
              itemBuilder: (context, index) {
                var item = _matchResults[index];
                double score = ((item is Map ? item['score'] : 0) ?? 0) * 100;
                String brand = (item is Map ? item['brand'] : '') ?? '';
                String category = (item is Map ? item['category'] : 'solid') ?? 'solid';
                String filename = (item is Map ? item['filename'] : '') ?? '';
                String itemName = (item is Map ? item['name'] : '') ?? '';
                String thumbUrl = '$baseUrl/laminate/$brand/$category/$filename';
                return Card(
                  child: ListTile(
                    leading: Image.network(thumbUrl, width: 45, height: 45, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.broken_image, color: Colors.grey)),
                    title: Text("Rank ${index + 1} - $brand", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    subtitle: Text("Code: $itemName"),
                    trailing: Text("${score.toStringAsFixed(1)}%", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                  ),
                );
              },
            ),
            
            if (_matchResults.isNotEmpty) ...[
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: _exportAndShareJpg,
                icon: const Icon(Icons.download, size: 18),
                label: const Text("Export Report as JPG Image", style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700, 
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ],

            const SizedBox(height: 15),
            const GoogleAdMobBannerWidget(),
          ],
        ),
      ),
    );
  }
}

// 4. EDGE BANDING SCREEN
class EdgeBandingScreen extends StatefulWidget {
  final bool isSubscribed;
  const EdgeBandingScreen({Key? key, this.isSubscribed = false}) : super(key: key);

  @override
  _EdgeBandingScreenState createState() => _EdgeBandingScreenState();
}

class _EdgeBandingScreenState extends State<EdgeBandingScreen> {
  Uint8List? _imageBytes;
  String _fileName = '';
  bool _isLoading = false;
  bool _isBrandsLoading = true;
  List<dynamic> _matchResults = [];
  double _cropX = 0.5, _cropY = 0.5;

  List<String> _laminateBrands = [];
  String? _selectedLaminateBrand;
  List<dynamic> _laminateItems = [];
  String? _selectedFilename;

  List<String> _edgeBrands = [];
  final Map<String, bool> _selectedEdgeBrandsMap = {};

  final ScreenshotController _screenshotController = ScreenshotController();

  @override
  void initState() {
    super.initState();
    _fetchBrandsForEdgeScreen();
  }

  Future<void> _fetchBrandsForEdgeScreen() async {
    if (!mounted) return;
    setState(() => _isBrandsLoading = true);
    try {
      var res = await http.get(Uri.parse('$baseUrl/get_brands'));
      if (res.statusCode == 200 && mounted) {
        var data = json.decode(res.body);
        if (data is Map) {
          List<String> lamBrands = data['laminate_brands'] != null 
              ? List<String>.from((data['laminate_brands'] as List).map((e) => e.toString())) 
              : [];
          List<String> edgeBrands = data['edge_brands'] != null 
              ? List<String>.from((data['edge_brands'] as List).map((e) => e.toString())) 
              : [];
          
          setState(() {
            _laminateBrands = lamBrands;
            _edgeBrands = edgeBrands;
            _selectedEdgeBrandsMap.clear();
            for (var b in edgeBrands) {
              _selectedEdgeBrandsMap[b] = true;
            }
          });
        }
      }
    } catch (e) {
      print("Error fetching brands for edge screen: $e");
    } finally {
      if (mounted) {
        setState(() => _isBrandsLoading = false);
      }
    }
  }

  void _selectAllEdgeBrands(bool select) {
    setState(() {
      for (var b in _edgeBrands) {
        _selectedEdgeBrandsMap[b] = select;
      }
    });
  }

  Future<void> _fetchLaminateList(String brand) async {
    try {
      var res = await http.get(Uri.parse('$baseUrl/get_laminate_list?brand=${Uri.encodeComponent(brand)}'));
      if (res.statusCode == 200 && mounted) {
        var decodedData = json.decode(res.body);
        setState(() {
          _laminateItems = decodedData is List ? decodedData : ((decodedData is Map && decodedData['items'] != null) ? decodedData['items'] : []);
          _selectedFilename = null;
        });
      }
    } catch (e) {
      print("Error fetching laminate list: $e");
    }
  }

  Future<void> _onCatalogItemSelected(String? filename) async {
    if (filename == null || _selectedLaminateBrand == null || _laminateItems.isEmpty) return;
    var selectedItem = _laminateItems.firstWhere(
      (item) => item is Map && item['filename']?.toString() == filename.toString(),
      orElse: () => null,
    );
    if (selectedItem == null || !mounted) return;
    String itemCategory = selectedItem['category']?.toString() ?? 'solid';

    setState(() {
      _selectedFilename = filename;
      _isLoading = true;
    });

    try {
      var imgUrl = '$baseUrl/laminate/${Uri.encodeComponent(_selectedLaminateBrand!)}/${Uri.encodeComponent(itemCategory)}/${Uri.encodeComponent(filename)}';
      var imgRes = await http.get(Uri.parse(imgUrl));
      if (imgRes.statusCode == 200 && mounted) {
        setState(() {
          _imageBytes = imgRes.bodyBytes;
        });
      }
    } catch (e) {
      print("Error loading image from catalog: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? file = await ImagePicker().pickImage(source: source);
    if (file == null || !mounted) return;
    var bytes = await file.readAsBytes();
    setState(() {
      _imageBytes = bytes;
      _fileName = file.name;
      _matchResults = [];
      _selectedLaminateBrand = null;
      _selectedFilename = null;
      _laminateItems = [];
    });
  }

  void _showAdBeforeMatch(Function onAdFinished) {
    if (widget.isSubscribed) {
      onAdFinished();
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        int secondsLeft = 6;
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            Future.delayed(const Duration(seconds: 1), () {
              if (secondsLeft > 1) {
                if (mounted && setStateDialog != null) {
                  try {
                    setStateDialog(() {
                      if (secondsLeft > 0) {
                        secondsLeft--;
                      }
                    });
                  } catch (e) {}
                }
              } else {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                  onAdFinished();
                }
              }
            });

            return AlertDialog(
              backgroundColor: const Color(0xFF14233C),
              title: const Text("Google AdMob Interstitial Ad", style: TextStyle(color: Colors.amber, fontSize: 16)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Sponsored Advertisement\nUpgrade to Pro (@ ₹199) to remove all ads!", style: TextStyle(color: Colors.white, fontSize: 13), textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  Text("Ad closing in ${secondsLeft}s...", style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  const LinearProgressIndicator(color: Colors.amber),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    onAdFinished();
                  },
                  child: const Text("Skip Ad", style: TextStyle(color: Colors.white70)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _matchEdge() async {
    if (_imageBytes == null) return;
    List<String> activeEdgeBrands = _selectedEdgeBrandsMap.entries.where((e) => e.value).map((e) => e.key).toList();
    if (activeEdgeBrands.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Kripya kam se kam ek Edge Brand chunein!")));
      return;
    }

    _showAdBeforeMatch(() async {
      if (!mounted) return;
      setState(() => _isLoading = true);
      try {
        var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/match'));
        request.fields['brands'] = activeEdgeBrands.join(',');
        request.fields['crop_x'] = _cropX.toString();
        request.fields['crop_y'] = _cropY.toString();
        request.files.add(http.MultipartFile.fromBytes('image', _imageBytes!, filename: _fileName.isNotEmpty ? _fileName : 'upload.jpg'));

        var res = await http.Response.fromStream(await request.send());
        if (res.statusCode == 200 && mounted) {
          var decodedBody = json.decode(res.body);
          setState(() {
            _matchResults = (decodedBody is Map && decodedBody['matches'] != null) ? decodedBody['matches'] : [];
          });
        }
      } catch (e) {
        print("Error matching edge: $e");
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    });
  }

  Widget _buildEdgeReportCardWidget() {
    return Container(
      width: 400,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade900, width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(6)),
            child: const Text(
              "✨ This card is made by WoodMat, a perfect laminate & edge banding matching app present on Google Play Store.",
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF14233C)),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 12),
          const Text("🏆 Flazzor WoodMat - Edge Report", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF14233C)), textAlign: TextAlign.center),
          const SizedBox(height: 10),

          if (_imageBytes != null) ...[
            const Text("Uploaded Photo:", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(_imageBytes!, height: 90, width: 90, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 10),
          ],

          const Text("Top Matching Results:", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),

          ..._matchResults.asMap().entries.map((entry) {
            int index = entry.key;
            var item = entry.value;
            double score = ((item is Map ? item['score'] : 0) ?? 0) * 100;
            String brand = (item is Map ? item['brand'] : '') ?? '';
            String category = (item is Map ? item['category'] : 'solid') ?? 'solid';
            String filename = (item is Map ? item['filename'] : '') ?? '';
            String itemName = (item is Map ? item['name'] : '') ?? '';
            String edgeThumbUrl = '$baseUrl/edge/$brand/$category/$filename';

            return Container(
              margin: const EdgeInsets.symmetric(vertical: 3),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(6)),
              child: Row(
                children: [
                  Image.network(edgeThumbUrl, width: 35, height: 35, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.broken_image, size: 30)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Rank ${index + 1} - $brand", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        Text("Code: $itemName", style: const TextStyle(fontSize: 10, color: Colors.grey)),
                      ],
                    ),
                  ),
                  Text("${score.toStringAsFixed(1)}%", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green)),
                ],
              ),
            );
          }).toList(),

          const SizedBox(height: 10),
          const Divider(),
          const Text("📍 Flazzor Interiors, Udaipur | 20+ Years Experience", style: TextStyle(fontSize: 9, color: Colors.grey), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  // 👉 एज बेंडिंग स्क्रीन का वह गायब हुआ JPG एक्सपोर्ट बटन फंक्शन यहाँ वापस जोड़ दिया गया है
  Future<void> _exportAndShareEdgeJpg() async {
    if (_matchResults.isEmpty) return;

    try {
      final Uint8List imageBytes = await _screenshotController.captureFromWidget(
        Material(child: _buildEdgeReportCardWidget()),
        delay: const Duration(milliseconds: 100),
      );

      final directory = await getTemporaryDirectory();
      final imagePath = await File('${directory.path}/woodmat_edge_report.jpg').create();
      await imagePath.writeAsBytes(imageBytes);

      if (mounted) {
        await Share.shareXFiles([XFile(imagePath.path)], text: "Flazzor WoodMat Edge Banding Report");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error exporting JPG: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool allEdgeSelected = _edgeBrands.isNotEmpty && _edgeBrands.every((b) => _selectedEdgeBrandsMap[b] == true);
    int selectedEdgeCount = _selectedEdgeBrandsMap.values.where((v) => v).length;

    return Scaffold(
      appBar: AppBar(backgroundColor: const Color(0xFF14233C), title: const Text("WoodMat Edge Banding Matching")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const GoogleAdMobBannerWidget(),
            
            if (_isBrandsLoading) ...[
              Container(
                padding: const EdgeInsets.all(20),
                alignment: Alignment.center,
                child: Column(
                  children: const [
                    CircularProgressIndicator(color: Color(0xFF14233C)),
                    SizedBox(height: 10),
                    Text("Loading Colors & Brands, Please Wait...", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                  ],
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.blue.shade50, border: Border.all(color: Colors.blue.shade200), borderRadius: BorderRadius.circular(6)),
                child: Column(
                  children: [
                    const Text("Catalog Mode (Select Laminate to Test Edge):", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 6),
                    DropdownButton<String>(
                      isExpanded: true,
                      hint: const Text("Select Laminate Brand (22 Brands)"),
                      value: _laminateBrands.contains(_selectedLaminateBrand) ? _selectedLaminateBrand : null,
                      items: _laminateBrands.map((b) => DropdownMenuItem(value: b, child: Text(b, style: const TextStyle(fontSize: 13)))).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() { 
                            _selectedLaminateBrand = val; 
                            _laminateItems = []; 
                            _selectedFilename = null; 
                          });
                          _fetchLaminateList(val);
                        }
                      },
                    ),
                    const SizedBox(height: 6),
                    DropdownButton<String>(
                      isExpanded: true,
                      hint: const Text("Select Code / Name"),
                      value: _laminateItems.any((item) => item is Map && item['filename']?.toString() == _selectedFilename) ? _selectedFilename : null,
                      items: _laminateItems.map<DropdownMenuItem<String>>((item) {
                        String fName = (item is Map && item['filename'] != null) ? item['filename'].toString() : '';
                        String displayName = (item is Map && item['name'] != null) ? item['name'].toString() : fName;
                        return DropdownMenuItem<String>(
                          value: fName, 
                          child: Text(displayName, style: const TextStyle(fontSize: 13)),
                        );
                      }).toList(),
                      onChanged: _selectedLaminateBrand == null ? null : _onCatalogItemSelected,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              const GoogleAdMobBannerWidget(),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Select Edge Brands ($selectedEdgeCount / ${_edgeBrands.length} Selected):", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  TextButton.icon(
                    onPressed: () => _selectAllEdgeBrands(!allEdgeSelected),
                    icon: Icon(allEdgeSelected ? Icons.deselect : Icons.select_all, size: 16),
                    label: Text(allEdgeSelected ? "Deselect All" : "Select All", style: const TextStyle(fontSize: 12)),
                  ),
                ],
              ),
              Wrap(
                spacing: 8.0,
                children: _edgeBrands.map((brand) {
                  return FilterChip(
                    label: Text(brand, style: const TextStyle(fontSize: 11)),
                    selected: _selectedEdgeBrandsMap[brand] ?? true,
                    onSelected: (bool selected) {
                      setState(() {
                        _selectedEdgeBrandsMap[brand] = selected;
                      });
                    },
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 12),
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
                height: 250,
                width: double.infinity,
                decoration: BoxDecoration(border: Border.all(color: Colors.blue, width: 2), color: Colors.black),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return GestureDetector(
                      onPanStart: (d) {
                        setState(() {
                          _cropX = (d.localPosition.dx / constraints.maxWidth).clamp(0.0, 1.0);
                          _cropY = (d.localPosition.dy / constraints.maxHeight).clamp(0.0, 1.0);
                        });
                      },
                      onPanUpdate: (d) {
                        setState(() {
                          _cropX = (d.localPosition.dx / constraints.maxWidth).clamp(0.0, 1.0);
                          _cropY = (d.localPosition.dy / constraints.maxHeight).clamp(0.0, 1.0);
                        });
                      },
                      onTapDown: (d) {
                        setState(() {
                          _cropX = (d.localPosition.dx / constraints.maxWidth).clamp(0.0, 1.0);
                          _cropY = (d.localPosition.dy / constraints.maxHeight).clamp(0.0, 1.0);
                        });
                      },
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.memory(_imageBytes!, fit: BoxFit.contain),
                          Positioned(
                            left: (_cropX * constraints.maxWidth) - 20,
                            top: (_cropY * constraints.maxHeight) - 20,
                            child: Container(
                              width: 40, 
                              height: 40, 
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.yellow, width: 3), 
                                color: Colors.yellow.withOpacity(0.3),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _isLoading ? null : _matchEdge,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade800, foregroundColor: Colors.white),
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("MATCH START", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
            const SizedBox(height: 15),
            const GoogleAdMobBannerWidget(),
            const SizedBox(height: 10),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _matchResults.length,
              itemBuilder: (context, index) {
                var item = _matchResults[index];
                double score = ((item is Map ? item['score'] : 0) ?? 0) * 100;
                String brand = (item is Map ? item['brand'] : '') ?? '';
                String category = (item is Map ? item['category'] : 'solid') ?? 'solid';
                String filename = (item is Map ? item['filename'] : '') ?? '';
                String itemName = (item is Map ? item['name'] : '') ?? '';
                String edgeThumbUrl = '$baseUrl/edge/$brand/$category/$filename';
                return Card(
                  child: ListTile(
                    leading: Image.network(edgeThumbUrl, width: 45, height: 45, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.broken_image, color: Colors.grey)),
                    title: Text("Rank ${index + 1} - $brand", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    subtitle: Text("Code: $itemName"),
                    trailing: Text("${score.toStringAsFixed(1)}%", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                  ),
                );
              },
            ),

            // 👉 एज बेंडिंग रिजल्ट के नीचे JPG एक्सपोर्ट बटन यहाँ वापस आ गया है
            if (_matchResults.isNotEmpty) ...[
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: _exportAndShareEdgeJpg,
                icon: const Icon(Icons.download, size: 18),
                label: const Text("Export Report as JPG Image", style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700, 
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ],

            const SizedBox(height: 15),
            const GoogleAdMobBannerWidget(),
          ],
        ),
      ),
    );
  }
}