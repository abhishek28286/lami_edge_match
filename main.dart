import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

const String baseUrl = 'https://lami-edge-match.onrender.com';

class UserProfile {
  static String phone = '';
  static String role = 'Contractor';
  static String city = 'Udaipur';
  static String state = 'Rajasthan';
  static bool isRegistered = false;
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();
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
          setState(() => _isAdLoaded = true);
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
                  const GoogleAdMobBannerWidget(),
                  const Text("Flazzor Interiors", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF14233C))),
                  const SizedBox(height: 4),
                  const Text("Pan-India B2B Furniture Suite", style: TextStyle(fontSize: 12, color: Colors.grey)),
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
                    onChanged: (val) => setState(() => _selectedRole = val!),
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
              setState(() => isSubscribed = true);
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
                const Text("Flazzor Interiors", style: TextStyle(color: Colors.white, fontSize: 15)),
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
                  onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AuthScreen())),
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
                          Navigator.push(context, MaterialPageRoute(builder: (context) => CutListDirectScreen(url: '$baseUrl/cutlist_optimizer')));
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

// 2.5 CutList WebView / Web Fallback Screen
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
          onPageFinished: (String url) => setState(() => _isLoading = false),
          onWebResourceError: (error) => setState(() => _isLoading = false),
        ))
        ..loadRequest(Uri.parse(widget.url));
    } catch (e) {
      _isLoading = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: const Color(0xFF14233C), title: const Text("Flazzor CutList Optimizer Pro", style: TextStyle(color: Colors.white, fontSize: 16))),
      body: Stack(
        children: [
          if (_controller != null)
            WebViewWidget(controller: _controller!)
          else
            Center(
              child: ElevatedButton(
                onPressed: () {
                  html.window.open(widget.url, '_blank');
                },
                child: const Text("Open CutList Optimizer in Browser"),
              ),
            ),
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
            Text("📚 Flazzor Master Suite - आधिकारिक हिंदी ट्रेनिंग मैनुअल", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF14233C))),
            Text("फर्म: Flazzor Interiors, Udaipur (उदयपुर, राजस्थान)\nअनुभव: 20+ वर्ष मॉड्यूलर फर्नीचर निर्माण और बी2बी सॉल्यूशंस", style: TextStyle(fontSize: 12, color: Colors.grey)),
            Divider(height: 30),
            
            Text("✂️ 1. कटलिस्ट ऑप्टिमाइज़र (CutList Optimizer)", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF14233C))),
            SizedBox(height: 4),
            Text("• स्टॉक मटेरियल मास्टर: स्टॉक शीट की साइज (जैसे मानक 8x4 फीट प्लाईवुड) और ब्लेड की मोटाई (Kerf) सेट करें।\n• पैनल लिस्ट: फर्नीचर डिजाइन के अनुसार हर पीस का नाम, लंबाई, चौड़ाई और आवश्यक पीस की संख्या भरें।\n• ऑप्टिमाइज़ेशन: 'Calculate / Optimize' दबाकर कम से कम शीट वेस्टेज के साथ कटिंग लेआउट प्राप्त करें।"),
            Divider(height: 30),

            Text("🎨 2. लेमिनेट मैचिंग (Laminate Matching)", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF14233C))),
            SizedBox(height: 4),
            Text("• ब्रांड सिलेक्शन: एक्सपेंशन बॉक्स से अपने मनपसंद या आवश्यक ब्रांड्स को चुनें या 'Select All' करें।\n• फोटो अपलोड: गैलरी या कैमरे से लेमिनेट की स्पष्ट फोटो अपलोड करें।\n• क्रॉस-हेयर: पीले रंग के चौकोर बॉक्स को खींचकर (Drag करके) सही शेड पर रखें।\n• मैच स्टार्ट: बटन दबाएं और विज्ञापन के बाद टॉप 5 नज़दीकी शेड कोड और मैचिंग प्रतिशत (%) देखें।\n• रिपोर्ट एक्सपोर्ट: 'Export as JPG' से सैंपल फोटो और थंबनेल वाली विजुअल रिपोर्ट डाउनलोड करें।"),
            Divider(height: 30),

            Text("📐 3. एज बैंडिंग मैचिंग (Edge Banding Matching)", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF14233C))),
            SizedBox(height: 4),
            Text("• कैटलॉग मोड: सीधे लेमिनेट ब्रांड और कोड चुनकर शेड इमेज ऑटोमैटिक लोड करें।\n• डायरेक्ट मोड: गैलरी या कैमरे से फोटो अपलोड करें।\n• एज ब्रांड्स: अपने पास उपलब्ध एज बैंडिंग ब्रांड्स (जैसे Advance Edge, E3, Pegasus, Rehau) चुनें।\n• मैचिंग: क्रॉस-हेयर सेट करके मैच शुरू करें और सटीक एज बैंड शेड व रिपोर्ट प्राप्त करें।"),
            
            SizedBox(height: 15),
            GoogleAdMobBannerWidget(),
          ],
        ),
      ),
    );
  }
}

// 2.7 Catalog Request Screen (With Mobile Number & PDF Upload & Secure WhatsApp ID)
class CatalogRequestScreen extends StatefulWidget {
  const CatalogRequestScreen({Key? key}) : super(key: key);

  @override
  State<CatalogRequestScreen> createState() => _CatalogRequestScreenState();
}

class _CatalogRequestScreenState extends State<CatalogRequestScreen> {
  final _firmController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController(); // Added Mobile Number Controller
  final _detailsController = TextEditingController();
  
  String _pdfFileName = '';
  bool _isPdfUploaded = false;

  Future<void> _pickPdfFile() async {
    try {
      final XFile? file = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (file != null) {
        setState(() {
          _pdfFileName = file.name;
          _isPdfUploaded = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("📁 Catalog File Uploaded: $_pdfFileName"))
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error uploading file!"))
      );
    }
  }

  void _submitCatalogRequest() {
    String firm = _firmController.text.trim();
    String name = _nameController.text.trim();
    String phone = _phoneController.text.trim();
    String details = _detailsController.text.trim();

    if (firm.isEmpty || name.isEmpty || phone.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Kripya Firm Name, Contact Name aur Valid Mobile Number bharein!"))
      );
      return;
    }

    String message = "Hello Abhishek (@abhishek28286),\n\nI want to submit my brand catalog for Flazzor Master Suite.\n\n*Firm Name:* $firm\n*Contact Person:* $name\n*Mobile Number:* +91 $phone\n*Details:* $details\n*Catalog File:* ${_isPdfUploaded ? _pdfFileName : 'Attached'}\n\nVerification Fee: ₹200";
    String encodedMessage = Uri.encodeComponent(message);
    String whatsappUrl = "https://wa.me/?text=$encodedMessage";

    try {
      html.window.open(whatsappUrl, '_blank');
    } catch (_) {}

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Request Ready for WhatsApp!"),
        content: const Text("Aapka catalog request message taiyar hai. WhatsApp khulne par 'Send' button dabayein (Aapka personal number secure rakha gaya hai)."),
        actions: [
          ElevatedButton(
            onPressed: () { 
              Navigator.pop(context); 
              Navigator.pop(context); 
            }, 
            child: const Text("OK"),
          ),
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
              label: const Text("Send Catalog Request via WhatsApp", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
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
          for (var b in brands) {
            _selectedBrandsMap[b] = true;
          }
        });
      }
    } catch (e) {
      print("Error fetching brands: $e");
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
    if (file == null) return;
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
                if (mounted) setStateDialog(() => secondsLeft--);
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
    });
  }

  void _exportAsJpg() async {
    try {
      final html.CanvasElement canvas = html.CanvasElement(width: 800, height: 1100);
      final ctx = canvas.context2D;

      ctx.fillStyle = '#FFFFFF';
      ctx.fillRect(0, 0, 800, 1100);

      ctx.fillStyle = '#14233C';
      ctx.font = 'bold 26px Arial';
      ctx.fillText("FLAZZOR INTERIORS - B2B SUITE", 40, 50);

      ctx.fillStyle = '#00C853';
      ctx.font = 'bold 18px Arial';
      ctx.fillText("Laminate Color Matching Report", 40, 80);

      ctx.fillStyle = '#666666';
      ctx.font = '14px Arial';
      ctx.fillText("Location: Udaipur, Rajasthan | Professional Report", 40, 105);

      ctx.strokeStyle = '#DDDDDD';
      ctx.lineWidth = 2;
      ctx.beginPath();
      ctx.moveTo(40, 125);
      ctx.lineTo(760, 125);
      ctx.stroke();

      ctx.fillStyle = '#333333';
      ctx.font = 'bold 15px Arial';
      ctx.fillText("Tested Sample Image:", 40, 155);

      if (_imageBytes != null) {
        final base64Image = base64Encode(_imageBytes!);
        final img = html.ImageElement();
        img.src = 'data:image/jpeg;base64,$base64Image';
        await img.onLoad.first;
        ctx.drawImageScaled(img, 40, 175, 120, 120);
        ctx.strokeStyle = '#CCCCCC';
        ctx.strokeRect(40, 175, 120, 120);
      }

      double startY = 320;
      ctx.fillStyle = '#333333';
      ctx.font = 'bold 16px Arial';
      ctx.fillText("Top Matched Laminate Shades:", 40, startY);

      startY += 20;
      for (int i = 0; i < _matchResults.length; i++) {
        var m = _matchResults[i];
        double score = (m['score'] ?? 0) * 100;
        String brand = m['brand'] ?? '';
        String category = m['category'] ?? 'solid';
        String filename = m['filename'] ?? '';
        String thumbUrl = '$baseUrl/laminate/$brand/$category/$filename';

        ctx.fillStyle = '#F5F5F5';
        ctx.fillRect(40, startY, 720, 85);
        ctx.strokeStyle = '#E0E0E0';
        ctx.strokeRect(40, startY, 720, 85);

        try {
          final img = html.ImageElement();
          img.crossOrigin = "anonymous";
          img.src = thumbUrl;
          await img.onLoad.first;
          ctx.drawImageScaled(img, 55, startY + 10, 65, 65);
          ctx.strokeStyle = '#999999';
          ctx.strokeRect(55, startY + 10, 65, 65);
        } catch (_) {
          ctx.fillStyle = '#DDDDDD';
          ctx.fillRect(55, startY + 10, 65, 65);
        }

        ctx.fillStyle = '#14233C';
        ctx.font = 'bold 16px Arial';
        ctx.fillText("Rank ${i + 1} - ${m['brand']}", 145, startY + 32);

        ctx.fillStyle = '#555555';
        ctx.font = '14px Arial';
        ctx.fillText("Code / Shade: ${m['name']}", 145, startY + 58);

        ctx.fillStyle = '#00C853';
        ctx.font = 'bold 20px Arial';
        ctx.fillText("${score.toStringAsFixed(1)}%", 640, startY + 50);

        startY += 100;
        if (startY > 980) break;
      }

      final dataUrl = canvas.toDataUrl('image/jpeg', 0.95);
      final anchor = html.AnchorElement(href: dataUrl)
        ..setAttribute("download", "Flazzor_Laminate_Match_Report.jpg")
        ..click();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("📥 Real Visual JPG Report downloaded successfully!"))
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error generating visual JPG image!"))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    bool allSelected = _allBrands.isNotEmpty && _allBrands.every((b) => _selectedBrandsMap[b] == true);
    int selectedCount = _selectedBrandsMap.values.where((v) => v).length;

    return Scaffold(
      appBar: AppBar(backgroundColor: const Color(0xFF14233C), title: const Text("Flazzor Laminate Matching")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const GoogleAdMobBannerWidget(),
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
                height: 180,
                decoration: BoxDecoration(border: Border.all(color: Colors.blue, width: 2)),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return GestureDetector(
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
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("MATCH START", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
            const SizedBox(height: 15),
            const GoogleAdMobBannerWidget(),
            const SizedBox(height: 10),
            if (_matchResults.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Top Matches:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ElevatedButton.icon(
                    onPressed: _exportAsJpg,
                    icon: const Icon(Icons.download, size: 16),
                    label: const Text("Export as JPG", style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _matchResults.length,
              itemBuilder: (context, index) {
                var item = _matchResults[index];
                double score = (item['score'] ?? 0) * 100;
                String brand = item['brand'] ?? '';
                String category = item['category'] ?? 'solid';
                String filename = item['filename'] ?? '';
                String thumbUrl = '$baseUrl/laminate/$brand/$category/$filename';
                return Card(
                  child: ListTile(
                    leading: Image.network(thumbUrl, width: 45, height: 45, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.broken_image, color: Colors.grey)),
                    title: Text("Rank ${index + 1} - $brand", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    subtitle: Text("Code: ${item['name']}"),
                    trailing: Text("${score.toStringAsFixed(1)}%", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                  ),
                );
              },
            ),
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
  List<dynamic> _matchResults = [];
  double _cropX = 0.5, _cropY = 0.5;

  List<String> _laminateBrands = [];
  String? _selectedLaminateBrand;
  List<dynamic> _laminateItems = [];
  String? _selectedFilename;

  List<String> _edgeBrands = [];
  final Map<String, bool> _selectedEdgeBrandsMap = {};

  @override
  void initState() {
    super.initState();
    _fetchBrandsForEdgeScreen();
  }

  Future<void> _fetchBrandsForEdgeScreen() async {
    try {
      var res = await http.get(Uri.parse('$baseUrl/get_brands'));
      if (res.statusCode == 200) {
        var data = json.decode(res.body);
        List<String> lamBrands = List<String>.from((data['laminate_brands'] ?? []).map((e) => e.toString()));
        List<String> edgeBrands = List<String>.from((data['edge_brands'] ?? []).map((e) => e.toString()));
        
        setState(() {
          _laminateBrands = lamBrands;
          _edgeBrands = edgeBrands;
          for (var b in edgeBrands) {
            _selectedEdgeBrandsMap[b] = true;
          }
        });
      }
    } catch (e) {
      print("Error fetching brands for edge screen: $e");
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
      if (res.statusCode == 200) {
        var decodedData = json.decode(res.body);
        setState(() {
          _laminateItems = decodedData is List ? decodedData : (decodedData['items'] ?? []);
          _selectedFilename = null;
        });
      }
    } catch (e) {
      print("Error fetching laminate list: $e");
    }
  }

  Future<void> _onCatalogItemSelected(String? filename) async {
    if (filename == null || _selectedLaminateBrand == null) return;
    var selectedItem = _laminateItems.firstWhere(
      (item) => item['filename']?.toString() == filename.toString(),
      orElse: () => null,
    );
    if (selectedItem == null) return;
    String itemCategory = selectedItem['category']?.toString() ?? 'solid';

    setState(() {
      _selectedFilename = filename;
      _isLoading = true;
    });

    try {
      var imgUrl = '$baseUrl/laminate/${Uri.encodeComponent(_selectedLaminateBrand!)}/${Uri.encodeComponent(itemCategory)}/${Uri.encodeComponent(filename)}';
      var imgRes = await http.get(Uri.parse(imgUrl));
      if (imgRes.statusCode == 200) {
        setState(() {
          _imageBytes = imgRes.bodyBytes;
        });
      }
    } catch (e) {
      print("Error loading image from catalog: $e");
    } finally {
      setState(() => _isLoading = false);
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
                if (mounted) setStateDialog(() => secondsLeft--);
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
      setState(() => _isLoading = true);
      try {
        var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/match'));
        request.fields['brands'] = activeEdgeBrands.join(',');
        request.fields['crop_x'] = _cropX.toString();
        request.fields['crop_y'] = _cropY.toString();
        request.files.add(http.MultipartFile.fromBytes('image', _imageBytes!, filename: _fileName.isNotEmpty ? _fileName : 'upload.jpg'));

        var res = await http.Response.fromStream(await request.send());
        if (res.statusCode == 200) {
          setState(() {
            _matchResults = json.decode(res.body)['matches'] ?? [];
          });
        }
      } catch (e) {
        print("Error matching edge: $e");
      } finally {
        setState(() => _isLoading = false);
      }
    });
  }

  void _exportAsJpg() async {
    try {
      final html.CanvasElement canvas = html.CanvasElement(width: 800, height: 1100);
      final ctx = canvas.context2D;

      ctx.fillStyle = '#FFFFFF';
      ctx.fillRect(0, 0, 800, 1100);

      ctx.fillStyle = '#14233C';
      ctx.font = 'bold 26px Arial';
      ctx.fillText("FLAZZOR INTERIORS - B2B SUITE", 40, 50);

      ctx.fillStyle = '#00C853';
      ctx.font = 'bold 18px Arial';
      ctx.fillText("Edge Banding Matching Report", 40, 80);

      ctx.fillStyle = '#666666';
      ctx.font = '14px Arial';
      ctx.fillText("Location: Udaipur, Rajasthan | Professional Report", 40, 105);

      ctx.strokeStyle = '#DDDDDD';
      ctx.lineWidth = 2;
      ctx.beginPath();
      ctx.moveTo(40, 125);
      ctx.lineTo(760, 125);
      ctx.stroke();

      ctx.fillStyle = '#333333';
      ctx.font = 'bold 15px Arial';
      ctx.fillText("Tested Sample Image:", 40, 155);

      if (_imageBytes != null) {
        final base64Image = base64Encode(_imageBytes!);
        final img = html.ImageElement();
        img.src = 'data:image/jpeg;base64,$base64Image';
        await img.onLoad.first;
        ctx.drawImageScaled(img, 40, 175, 120, 120);
        ctx.strokeStyle = '#CCCCCC';
        ctx.strokeRect(40, 175, 120, 120);
      }

      double startY = 320;
      ctx.fillStyle = '#333333';
      ctx.font = 'bold 16px Arial';
      ctx.fillText("Top Matched Edge Banding Shades:", 40, startY);

      startY += 20;
      for (int i = 0; i < _matchResults.length; i++) {
        var m = _matchResults[i];
        double score = (m['score'] ?? 0) * 100;
        String brand = m['brand'] ?? '';
        String category = m['category'] ?? 'solid';
        String filename = m['filename'] ?? '';
        String edgeThumbUrl = '$baseUrl/edge/$brand/$category/$filename';

        ctx.fillStyle = '#F5F5F5';
        ctx.fillRect(40, startY, 720, 85);
        ctx.strokeStyle = '#E0E0E0';
        ctx.strokeRect(40, startY, 720, 85);

        try {
          final img = html.ImageElement();
          img.crossOrigin = "anonymous";
          img.src = edgeThumbUrl;
          await img.onLoad.first;
          ctx.drawImageScaled(img, 55, startY + 10, 65, 65);
          ctx.strokeStyle = '#999999';
          ctx.strokeRect(55, startY + 10, 65, 65);
        } catch (_) {
          ctx.fillStyle = '#DDDDDD';
          ctx.fillRect(55, startY + 10, 65, 65);
        }

        ctx.fillStyle = '#14233C';
        ctx.font = 'bold 16px Arial';
        ctx.fillText("Rank ${i + 1} - ${m['brand']}", 145, startY + 32);

        ctx.fillStyle = '#555555';
        ctx.font = '14px Arial';
        ctx.fillText("Code / Shade: ${m['name']}", 145, startY + 58);

        ctx.fillStyle = '#00C853';
        ctx.font = 'bold 20px Arial';
        ctx.fillText("${score.toStringAsFixed(1)}%", 640, startY + 50);

        startY += 100;
        if (startY > 980) break;
      }

      final dataUrl = canvas.toDataUrl('image/jpeg', 0.95);
      final anchor = html.AnchorElement(href: dataUrl)
        ..setAttribute("download", "Flazzor_Edge_Match_Report.jpg")
        ..click();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("📥 Real Visual JPG Report downloaded successfully!"))
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error generating visual JPG image!"))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    bool allEdgeSelected = _edgeBrands.isNotEmpty && _edgeBrands.every((b) => _selectedEdgeBrandsMap[b] == true);
    int selectedEdgeCount = _selectedEdgeBrandsMap.values.where((v) => v).length;

    return Scaffold(
      appBar: AppBar(backgroundColor: const Color(0xFF14233C), title: const Text("Flazzor Edge Banding Matching")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const GoogleAdMobBannerWidget(),
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
                    value: _laminateItems.any((item) => item['filename']?.toString() == _selectedFilename) ? _selectedFilename : null,
                    items: _laminateItems.map<DropdownMenuItem<String>>((item) {
                      String fName = item['filename']?.toString() ?? '';
                      String displayName = item['name']?.toString() ?? fName;
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
                height: 180,
                decoration: BoxDecoration(border: Border.all(color: Colors.blue, width: 2)),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return GestureDetector(
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
                onPressed: _isLoading ? null : _matchEdge,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade800, foregroundColor: Colors.white),
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("MATCH START", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
            const SizedBox(height: 15),
            const GoogleAdMobBannerWidget(),
            const SizedBox(height: 10),
            if (_matchResults.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Top Edge Matches:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ElevatedButton.icon(
                    onPressed: _exportAsJpg,
                    icon: const Icon(Icons.download, size: 16),
                    label: const Text("Export as JPG", style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _matchResults.length,
              itemBuilder: (context, index) {
                var item = _matchResults[index];
                double score = (item['score'] ?? 0) * 100;
                String brand = item['brand'] ?? '';
                String category = item['category'] ?? 'solid';
                String filename = item['filename'] ?? '';
                String edgeThumbUrl = '$baseUrl/edge/$brand/$category/$filename';
                return Card(
                  child: ListTile(
                    leading: Image.network(edgeThumbUrl, width: 45, height: 45, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.broken_image, color: Colors.grey)),
                    title: Text("Rank ${index + 1} - $brand", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    subtitle: Text("Code: ${item['name']}"),
                    trailing: Text("${score.toStringAsFixed(1)}%", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                  ),
                );
              },
            ),
            const SizedBox(height: 15),
            const GoogleAdMobBannerWidget(),
          ],
        ),
      ),
    );
  }
}