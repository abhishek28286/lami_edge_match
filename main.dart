import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;

// कंडीशनल इम्पोर्ट ताकि एंड्रॉइड APK बनाते वक्त एरर न आए
import 'package:flutter/foundation.dart' if (dart.library.html) 'dart:ui_web' as ui_web;
import 'package:flutter/foundation.dart' if (dart.library.html) 'dart:html' as html;

const String baseUrl = 'https://lami-edge-match.onrender.com';
void main() {
  runApp(const FlazzorMasterApp());
}

class MasterHomeScreen extends StatefulWidget {
  const MasterHomeScreen({Key? key}) : super(key: key);

  @override
  State<MasterHomeScreen> createState() => _MasterHomeScreenState();
}

class _MasterHomeScreenState extends State<MasterHomeScreen> {
  int laminateCredits = 10;
  int cutListCredits = 5;
  int edgeBandingCredits = 5;

  void _openCutListOptimizer() {
    if (cutListCredits > 0) {
      setState(() {
        cutListCredits--;
      });
      try {
        if (kIsWeb) {
          String htmlViewId = 'cutlist-html-view';
          
          ui_web.platformViewRegistry.registerViewFactory(
            htmlViewId,
            (int viewId) => html.IFrameElement()
              ..src = 'cutlist_tool/index.html'
              ..style.border = 'none'
              ..style.width = '100%'
              ..style.height = '100%',
          );

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Scaffold(
                appBar: AppBar(
                  title: const Text("CutList Optimizer - Flazzor Interior"),
                  backgroundColor: Colors.orange.shade800,
                ),
                body: const SizedBox.expand(
                  child: HtmlElementView(viewType: 'cutlist-html-view'),
                ),
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("CutList Optimizer is available on Web version.")),
          );
        }
      } catch (e) {
        print("Error opening optimizer: $e");
      }
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Out of Credits!"),
          content: const Text("Your free credits for CutList Optimizer are finished. Watch an ad to get 2 new credits!"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade800, foregroundColor: Colors.white),
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  cutListCredits += 2;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Ad watched successfully! +2 Credits added.")),
                );
              },
              child: const Text("Watch Ad (+2 Credits)"),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF14233C),
        title: Row(
          children: [
            Image.asset('assets/flazzor_logo.png', height: 40, width: 40, fit: BoxFit.contain, errorBuilder: (c, e, s) => const Icon(Icons.home, color: Colors.white)),
            const SizedBox(width: 10),
            const Text("Flazzor Interior - Master Tool", style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
      body: Container(
        color: Colors.grey.shade50,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/flazzor_logo.png', height: 130, width: 130, fit: BoxFit.contain, errorBuilder: (c, e, s) => const Icon(Icons.business, size: 80, color: Colors.blue)),
                  const SizedBox(width: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text("FLAZZOR INTERIOR", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF14233C), letterSpacing: 1.5)),
                      SizedBox(height: 6),
                      Text("AI-Powered Laminate & Edge Banding Matcher", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.blueAccent)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 50),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Wrap(
                  spacing: 20,
                  runSpacing: 20,
                  alignment: WrapAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        if (laminateCredits > 0) {
                          setState(() {
                            laminateCredits--;
                          });
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const LaminateMatchingScreen()),
                          );
                        } else {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text("Out of Credits!"),
                              content: const Text("Your free credits for Laminate Matching are finished. Watch an ad to get 2 new credits!"),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text("Cancel"),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade800, foregroundColor: Colors.white),
                                  onPressed: () {
                                    Navigator.pop(context);
                                    setState(() {
                                      laminateCredits += 2;
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("Ad watched successfully! +2 Credits added.")),
                                    );
                                  },
                                  child: const Text("Watch Ad (+2 Credits)"),
                                ),
                              ],
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.layers, size: 28),
                      label: const Text("Laminate / Mica Matching", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade800,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        if (edgeBandingCredits > 0) {
                          setState(() {
                            edgeBandingCredits--;
                          });
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const EdgeBandingScreen()),
                          );
                        } else {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text("Out of Credits!"),
                              content: const Text("Your free credits for Edge Banding Matching are finished. Watch an ad to get 2 new credits!"),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text("Cancel"),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white),
                                  onPressed: () {
                                    Navigator.pop(context);
                                    setState(() {
                                      edgeBandingCredits += 2;
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("Ad watched successfully! +2 Credits added.")),
                                    );
                                  },
                                  child: const Text("Watch Ad (+2 Credits)"),
                                ),
                              ],
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.border_style, size: 28),
                      label: const Text("Edge Banding Matching", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _openCutListOptimizer,
                      icon: const Icon(Icons.dashboard_customize, size: 28),
                      label: const Text("CutList Optimizer", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade800,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              Container(
                height: 50,
                width: 650,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  border: Border.all(color: Colors.grey.shade400, width: 1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text(
                    "Advertisement Banner Space",
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              Container(
                width: 650,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.blue.shade900,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('assets/flazzor_logo.png', height: 22, width: 22, fit: BoxFit.contain, errorBuilder: (c, e, s) => const Icon(Icons.star, color: Colors.amber, size: 18)),
                    const SizedBox(width: 10),
                    const Text("Flazzor Interior | Premium Modular Kitchen, Wardrobes & Factory Solutions - Udaipur", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LaminateMatchingScreen extends StatefulWidget {
  const LaminateMatchingScreen({Key? key}) : super(key: key);

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

  double _cropX = 0.5;
  double _cropY = 0.5;

  int laminateCredits = 10;

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
        List<String> brands = [];
        
        if (data is Map && data.containsKey('laminate_brands')) {
          var rawList = data['laminate_brands'] ?? [];
          brands = List<String>.from(rawList.map((e) => e.toString()));
        } else if (data is List) {
          brands = List<String>.from(data.map((e) => e.toString()));
        }

        setState(() {
          _allBrands = brands;
          for (var b in brands) {
            _selectedBrandsMap[b] = true;
          }
        });
      }
    } catch (e) {
      print("Error fetching laminate brands: $e");
    }
  }

  void _showBrandSelectionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            bool allSelected = _selectedBrandsMap.values.every((v) => v);
            return AlertDialog(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Select Target Brands", style: TextStyle(fontSize: 16)),
                  TextButton(
                    onPressed: () {
                      setDialogState(() {
                        bool newState = !allSelected;
                        for (var b in _allBrands) {
                          _selectedBrandsMap[b] = newState;
                        }
                      });
                      setState(() {});
                    },
                    child: Text(allSelected ? "Deselect All" : "Select All", style: const TextStyle(fontSize: 13)),
                  ),
                ],
              ),
              content: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 350, maxHeight: 400),
                child: SizedBox(
                  width: 350,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _allBrands.length,
                    itemBuilder: (context, index) {
                      String brand = _allBrands[index];
                      bool isChecked = _selectedBrandsMap[brand] ?? false;
                      return CheckboxListTile(
                        title: Text(brand, style: const TextStyle(fontSize: 13)),
                        value: isChecked,
                        onChanged: (bool? value) {
                          setDialogState(() {
                            _selectedBrandsMap[brand] = value ?? false;
                          });
                          setState(() {});
                        },
                      );
                    },
                  ),
                ),
              ),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Done"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showCreditPopup() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Out of Laminate Matching Credits!"),
        content: const Text("Aage matching karne ke liye 30 second ka video dekhein. Ek video dekhne par 2 free credits milenge!"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                laminateCredits += 2;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("🎉 Video watched successfully! +2 Laminate Credits added.")),
              );
            },
            child: const Text("Watch Ad (30s)"),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await ImagePicker().pickImage(source: source);
      if (pickedFile == null) return;
      var bytes = await pickedFile.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        _fileName = pickedFile.name;
        _matchResults = [];
        _cropX = 0.5;
        _cropY = 0.5;
      });
    } catch (e) {
      print("Error picking image: $e");
    }
  }

  Future<void> _matchLaminateImage() async {
    if (_imageBytes == null) return;

    if (laminateCredits <= 0) {
      _showCreditPopup();
      return;
    }
    
    List<String> activeBrands = _selectedBrandsMap.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    if (activeBrands.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Kripya kam se kam ek company chunein!")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      var uri = Uri.parse('$baseUrl/match_laminate');
      var request = http.MultipartRequest('POST', uri);

      request.fields['brands'] = activeBrands.join(',');
      request.fields['crop_x'] = _cropX.toString();
      request.fields['crop_y'] = _cropY.toString();
      request.files.add(http.MultipartFile.fromBytes('image', _imageBytes!, filename: _fileName.isNotEmpty ? _fileName : 'upload.jpg'));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        setState(() {
          _matchResults = data['matches'] ?? [];
          _isLoading = false;
          laminateCredits--;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _exportReport() async {
    if (_matchResults.isEmpty) return;
    try {
      var response = await http.post(
        Uri.parse('$baseUrl/export_report'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'matches': _matchResults,
          'tool_type': 'Laminate Matching Report'
        }),
      );

      if (response.statusCode == 200) {
        if (kIsWeb) {
          final blob = html.Blob([response.bodyBytes], 'image/jpeg');
          final url = html.Url.createObjectUrlFromBlob(blob);
          final anchor = html.AnchorElement(href: url)
            ..setAttribute("download", "Flazzor_Laminate_Match_Report.jpg")
            ..click();
          html.Url.revokeObjectUrl(url);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Report downloaded successfully as JPG!")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to download report.")),
        );
      }
    } catch (e) {
      print("Export error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    int selectedCount = _selectedBrandsMap.values.where((v) => v).length;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF14233C),
        title: Row(
          children: [
            Image.asset('assets/flazzor_logo.png', height: 40, width: 40, fit: BoxFit.contain, errorBuilder: (c, e, s) => const Icon(Icons.layers, color: Colors.white)),
            const SizedBox(width: 12),
            const Text("Laminate / Mica Matching Tool", style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
        actions: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: Colors.amber.shade700, borderRadius: BorderRadius.circular(12)),
              child: Text("Credits: $laminateCredits ⚡", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.blue.shade50, border: Border.all(color: Colors.blue.shade200), borderRadius: BorderRadius.circular(6)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Target Brands: $selectedCount / ${_allBrands.length} Selected", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF14233C))),
                  ElevatedButton.icon(
                    onPressed: _showBrandSelectionDialog,
                    icon: const Icon(Icons.list, size: 18),
                    label: const Text("Select Brands"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade800,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 260,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.grey.shade100, border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(8)),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : () => _pickImage(ImageSource.gallery),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF14233C),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.all(8),
                                ),
                                child: const Text("Gallery", style: TextStyle(fontSize: 11)),
                              ),
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : () => _pickImage(ImageSource.camera),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green.shade700,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.all(8),
                                ),
                                child: const Text("Camera", style: TextStyle(fontSize: 11)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(color: Colors.amber.shade50, border: Border.all(color: Colors.amber.shade300), borderRadius: BorderRadius.circular(4)),
                          child: const Text(
                            "💡 बेहतर रिजल्ट के लिए: फोटो साफ रोशनी (Bright Light) में लें।",
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.brown),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text("Target Preview & Color Picker", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(border: Border.all(color: Colors.blue, width: 2), borderRadius: BorderRadius.circular(6)),
                            child: _imageBytes == null
                                ? const Center(child: Text("No Photo Uploaded", style: TextStyle(fontSize: 11, color: Colors.grey), textAlign: TextAlign.center))
                                : LayoutBuilder(
                                    builder: (BuildContext context, BoxConstraints constraints) {
                                      return GestureDetector(
                                        onTapDown: (TapDownDetails details) {
                                          setState(() {
                                            _cropX = details.localPosition.dx / constraints.maxWidth;
                                            _cropY = details.localPosition.dy / constraints.maxHeight;
                                            if (_cropX < 0) _cropX = 0; if (_cropX > 1) _cropX = 1;
                                            if (_cropY < 0) _cropY = 0; if (_cropY > 1) _cropY = 1;
                                          });
                                        },
                                        onPanUpdate: (DragUpdateDetails details) {
                                          setState(() {
                                            _cropX = details.localPosition.dx / constraints.maxWidth;
                                            _cropY = details.localPosition.dy / constraints.maxHeight;
                                            if (_cropX < 0) _cropX = 0; if (_cropX > 1) _cropX = 1;
                                            if (_cropY < 0) _cropY = 0; if (_cropY > 1) _cropY = 1;
                                          });
                                        },
                                        child: Stack(
                                          fit: StackFit.expand,
                                          children: [
                                            Image.memory(_imageBytes!, fit: BoxFit.cover),
                                            Positioned(
                                              left: (_cropX * constraints.maxWidth) - 30,
                                              top: (_cropY * constraints.maxHeight) - 30,
                                              child: Container(
                                                width: 60,
                                                height: 60,
                                                decoration: BoxDecoration(
                                                  border: Border.all(color: Colors.yellow, width: 2.5),
                                                  color: Colors.black.withOpacity(0.2),
                                                ),
                                                child: const Center(
                                                  child: Icon(Icons.add, color: Colors.yellow, size: 18),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: (_imageBytes == null || _isLoading) ? null : _matchLaminateImage,
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade800, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 10)),
                            child: _isLoading ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text("MATCH START", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.grey.shade100, border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(8)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Top 5 Matching Laminates:", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF14233C))),
                              if (_matchResults.isNotEmpty)
                                ElevatedButton.icon(
                                  onPressed: _exportReport,
                                  icon: const Icon(Icons.download, size: 16),
                                  label: const Text("Export as JPG", style: TextStyle(fontSize: 11)),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.purple.shade700, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6)),
                                ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Expanded(
                            child: _matchResults.isEmpty
                                ? const Center(child: Text("Gallery se photo upload karein, box se color select karein aur MATCH START dabayein...", style: TextStyle(fontSize: 12, color: Colors.grey), textAlign: TextAlign.center))
                                : ListView.builder(
                                    itemCount: _matchResults.length,
                                    itemBuilder: (context, index) {
                                      var item = _matchResults[index];
                                      String brand = item['brand'] ?? '';
                                      String name = item['name'] ?? '';
                                      String filename = item['filename'] ?? '';
                                      double score = (item['score'] ?? 0) * 100;
                                      String imgUrl = '$baseUrl/laminate/$filename';

                                      return Container(
                                        margin: const EdgeInsets.only(bottom: 8),
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          border: Border.all(color: index == 0 ? Colors.green.shade600 : Colors.grey.shade300, width: index == 0 ? 2 : 1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 80,
                                              height: 80,
                                              decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(6)),
                                              child: Image.network(imgUrl, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.broken_image, size: 25)),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Text("Rank ${index + 1} - $brand", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                                                      Text("${score.toStringAsFixed(1)}% Match", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: index == 0 ? Colors.green.shade700 : Colors.black54)),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text("Code/Name: $name", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Container(
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                border: Border.all(color: Colors.grey.shade400, width: 1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Center(
                child: Text("Advertisement Banner Space", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class EdgeBandingScreen extends StatefulWidget {
  const EdgeBandingScreen({Key? key}) : super(key: key);

  @override
  _EdgeBandingScreenState createState() => _EdgeBandingScreenState();
}

class _EdgeBandingScreenState extends State<EdgeBandingScreen> {
  bool advanceEdge = false;
  bool squareOne = false;
  bool pegasus = false;
  bool e3 = false;
  bool rehau = false;

  Uint8List? _imageBytes;
  String _fileName = '';
  bool _isLoading = false;
  List<dynamic> _matchResults = [];

  double _cropX = 0.5;
  double _cropY = 0.5;

  List<String> _laminateBrands = [];
  String? _selectedLaminateBrand;
  List<dynamic> _laminateItems = [];
  String? _selectedFilename;

  int edgeCredits = 10;

  @override
  void initState() {
    super.initState();
    _fetchLaminateBrands();
  }

  Future<void> _fetchLaminateBrands() async {
    try {
      var response = await http.get(Uri.parse('$baseUrl/get_brands'));
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        List<String> loadedBrands = [];
        
        if (data is Map && data.containsKey('laminate_brands')) {
          var rawList = data['laminate_brands'] ?? [];
          loadedBrands = List<String>.from(rawList.map((e) => e.toString()));
        } else if (data is List) {
          loadedBrands = List<String>.from(data.map((e) => e.toString()));
        }

        setState(() {
          _laminateBrands = loadedBrands;
        });
      }
    } catch (e) {
      print("Error fetching laminate brands: $e");
    }
  }

  void _showCreditPopup() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Out of Edge Banding Credits!"),
        content: const Text("Aage matching karne ke liye 30 second ka video dekhein. Ek video dekhne par 2 free credits milenge!"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                edgeCredits += 2;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("🎉 Video watched successfully! +2 Edge Credits added.")),
              );
            },
            child: const Text("Watch Ad (30s)"),
          ),
        ],
      ),
    );
  }

  Future<void> _fetchLaminateList(String brand) async {
    try {
      var response = await http.get(Uri.parse('$baseUrl/get_laminate_list?brand=${Uri.encodeComponent(brand)}'));
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        List<dynamic> loadedItems = [];
        if (data is List) {
          loadedItems = data;
        } else if (data is Map) {
          loadedItems = data['items'] ?? data['data'] ?? [];
        }
        setState(() {
          _laminateItems = loadedItems;
          _selectedFilename = null;
        });
      }
    } catch (e) {
      print("Error fetching items: $e");
    }
  }

  Future<void> _onCatalogItemSelected(String? filename) async {
    if (filename == null || _selectedLaminateBrand == null) return;

    var selectedItem = _laminateItems.firstWhere(
      (item) => item['filename'].toString() == filename.toString(),
      orElse: () => null,
    );
    if (selectedItem == null) return;
    String itemCategory = selectedItem['category'] ?? 'solid';

    setState(() {
      _selectedFilename = filename;
      _isLoading = true;
    });

    try {
      var imgRes = await http.get(Uri.parse('$baseUrl/get_laminate_image?brand=${Uri.encodeComponent(_selectedLaminateBrand!)}&category=${Uri.encodeComponent(itemCategory)}&filename=${Uri.encodeComponent(filename)}'));
      if (imgRes.statusCode == 200) {
        setState(() {
          _imageBytes = imgRes.bodyBytes;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await ImagePicker().pickImage(source: source);
      if (pickedFile == null) return;
      var bytes = await pickedFile.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        _fileName = pickedFile.name;
        _matchResults = [];
        _cropX = 0.5;
        _cropY = 0.5;
        _selectedLaminateBrand = null;
        _selectedFilename = null;
        _laminateItems = [];
      });
    } catch (e) {
      print("Error picking image: $e");
    }
  }

  Future<void> _matchUploadedImage() async {
    if (_imageBytes == null) return;

    if (edgeCredits <= 0) {
      _showCreditPopup();
      return;
    }

    setState(() => _isLoading = true);

    try {
      var uri = Uri.parse('$baseUrl/match');
      var request = http.MultipartRequest('POST', uri);

      List<String> activeBrands = [];
      if (advanceEdge) activeBrands.add("advance_edge");
      if (squareOne) activeBrands.add("square_one");
      if (pegasus) activeBrands.add("pegasus");
      if (e3) activeBrands.add("E3");
      if (rehau) activeBrands.add("rehau");

      request.fields['brands'] = activeBrands.join(',');
      request.fields['crop_x'] = _cropX.toString();
      request.fields['crop_y'] = _cropY.toString();
      request.files.add(http.MultipartFile.fromBytes('image', _imageBytes!, filename: _fileName.isNotEmpty ? _fileName : 'upload.jpg'));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        setState(() {
          _matchResults = data['matches'] ?? [];
          _isLoading = false;
          edgeCredits--;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _matchCatalog() async {
    if (_imageBytes == null || _selectedFilename == null || _selectedLaminateBrand == null) return;

    if (edgeCredits <= 0) {
      _showCreditPopup();
      return;
    }

    var selectedItem = _laminateItems.firstWhere(
      (item) => item['filename'].toString() == _selectedFilename.toString(),
      orElse: () => null,
    );
    if (selectedItem == null) return;
    String itemCategory = selectedItem['category'] ?? 'solid';

    setState(() => _isLoading = true);

    try {
      var uri = Uri.parse('$baseUrl/match_catalog');
      var request = http.MultipartRequest('POST', uri);

      List<String> activeBrands = [];
      if (advanceEdge) activeBrands.add("advance_edge");
      if (squareOne) activeBrands.add("square_one");
      if (pegasus) activeBrands.add("pegasus");
      if (e3) activeBrands.add("E3");
      if (rehau) activeBrands.add("rehau");

      request.fields['brands'] = activeBrands.join(',');
      request.fields['brand'] = _selectedLaminateBrand!;
      request.fields['category'] = itemCategory;
      request.fields['filename'] = _selectedFilename!;

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        setState(() {
          _matchResults = data['matches'] ?? [];
          _isLoading = false;
          edgeCredits--;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _exportReport() async {
    if (_matchResults.isEmpty) return;
    try {
      var response = await http.post(
        Uri.parse('$baseUrl/export_report'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'matches': _matchResults,
          'tool_type': 'Edge Banding Matching Report'
        }),
      );

      if (response.statusCode == 200) {
        if (kIsWeb) {
          final blob = html.Blob([response.bodyBytes], 'image/jpeg');
          final url = html.Url.createObjectUrlFromBlob(blob);
          final anchor = html.AnchorElement(href: url)
            ..setAttribute("download", "Flazzor_Edge_Match_Report.jpg")
            ..click();
          html.Url.revokeObjectUrl(url);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Report downloaded successfully as JPG!")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to download report.")),
        );
      }
    } catch (e) {
      print("Export error: $e");
    }
  }

  Widget _buildBrandCheckbox(String title, bool value, Function(bool?) onChanged) {
    return SizedBox(
      width: 130,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Checkbox(value: value, onChanged: onChanged, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
          const SizedBox(width: 4),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String? currentBrand = _laminateBrands.contains(_selectedLaminateBrand) ? _selectedLaminateBrand : null;
    List<String> validFilenames = _laminateItems.map((item) => item['filename'].toString()).toList();
    String? currentFilename = validFilenames.contains(_selectedFilename) ? _selectedFilename : null;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF14233C),
        title: Row(
          children: [
            Image.asset('assets/flazzor_logo.png', height: 40, width: 40, fit: BoxFit.contain, errorBuilder: (c, e, s) => const Icon(Icons.border_style, color: Colors.white)),
            const SizedBox(width: 12),
            const Text("Edge Banding Matching", style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
        actions: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: Colors.amber.shade700, borderRadius: BorderRadius.circular(12)),
              child: Text("Credits: $edgeCredits ⚡", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.blue.shade50, border: Border.all(color: Colors.blue.shade200), borderRadius: BorderRadius.circular(6)),
              child: Row(
                children: [
                  const Text("Catalog Mode:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(width: 15),
                  Expanded(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      hint: const Text("Select Brand"),
                      value: currentBrand,
                      items: _laminateBrands.map((brand) => DropdownMenuItem(value: brand, child: Text(brand, style: const TextStyle(fontSize: 13)))).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedLaminateBrand = val;
                          _laminateItems = [];
                          _selectedFilename = null;
                        });
                        if (val != null) {
                          _fetchLaminateList(val);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      hint: const Text("Select Code/Name"),
                      value: currentFilename,
                      items: _laminateItems.map<DropdownMenuItem<String>>((item) {
                        String fName = item['filename'].toString();
                        String displayName = item['name']?.toString() ?? fName;
                        return DropdownMenuItem<String>(
                          value: fName,
                          child: Text(displayName, style: const TextStyle(fontSize: 13)),
                        );
                      }).toList(),
                      onChanged: _onCatalogItemSelected,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(6)),
              child: Wrap(
                spacing: 10,
                runSpacing: 4,
                children: [
                  _buildBrandCheckbox("advance_edge", advanceEdge, (val) => setState(() => advanceEdge = val!)),
                  _buildBrandCheckbox("square_one", squareOne, (val) => setState(() => squareOne = val!)),
                  _buildBrandCheckbox("pegasus", pegasus, (val) => setState(() => pegasus = val!)),
                  _buildBrandCheckbox("E3", e3, (val) => setState(() => e3 = val!)),
                  _buildBrandCheckbox("rehau", rehau, (val) => setState(() => rehau = val!)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 250,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.grey.shade100, border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(8)),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : () => _pickImage(ImageSource.gallery),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF14233C),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.all(8),
                                ),
                                child: const Text("Gallery", style: TextStyle(fontSize: 11)),
                              ),
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : () => _pickImage(ImageSource.camera),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green.shade700,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.all(8),
                                ),
                                child: const Text("Camera", style: TextStyle(fontSize: 11)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(color: Colors.amber.shade100, border: Border.all(color: Colors.amber.shade400), borderRadius: BorderRadius.circular(4)),
                          child: const Text(
                            "💡 बेहतर रिजल्ट के लिए: फोटो साफ रोशनी (Bright Light) में लें।",
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.brown),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text("Target Preview & Color Picker", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(border: Border.all(color: Colors.blue, width: 2), borderRadius: BorderRadius.circular(6)),
                            child: _imageBytes == null
                                ? const Center(child: Text("No Photo / Catalog", style: TextStyle(fontSize: 11, color: Colors.grey), textAlign: TextAlign.center))
                                : LayoutBuilder(
                                    builder: (BuildContext context, BoxConstraints constraints) {
                                      return GestureDetector(
                                        onTapDown: (TapDownDetails details) {
                                          setState(() {
                                            _cropX = details.localPosition.dx / constraints.maxWidth;
                                            _cropY = details.localPosition.dy / constraints.maxHeight;
                                            if (_cropX < 0) _cropX = 0; if (_cropX > 1) _cropX = 1;
                                            if (_cropY < 0) _cropY = 0; if (_cropY > 1) _cropY = 1;
                                          });
                                        },
                                        onPanUpdate: (DragUpdateDetails details) {
                                          setState(() {
                                            _cropX = details.localPosition.dx / constraints.maxWidth;
                                            _cropY = details.localPosition.dy / constraints.maxHeight;
                                            if (_cropX < 0) _cropX = 0; if (_cropX > 1) _cropX = 1;
                                            if (_cropY < 0) _cropY = 0; if (_cropY > 1) _cropY = 1;
                                          });
                                        },
                                        child: Stack(
                                          fit: StackFit.expand,
                                          children: [
                                            Image.memory(_imageBytes!, fit: BoxFit.cover),
                                            Positioned(
                                              left: (_cropX * constraints.maxWidth) - 30,
                                              top: (_cropY * constraints.maxHeight) - 30,
                                              child: Container(
                                                width: 60,
                                                height: 60,
                                                decoration: BoxDecoration(
                                                  border: Border.all(color: Colors.yellow, width: 2.5),
                                                  color: Colors.black.withOpacity(0.2),
                                                ),
                                                child: const Center(
                                                  child: Icon(Icons.add, color: Colors.yellow, size: 18),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        if (_imageBytes != null)
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : () {
                                if (_selectedFilename != null) {
                                  _matchCatalog();
                                } else {
                                  _matchUploadedImage();
                                }
                              },
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade800, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 10)),
                              child: _isLoading ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text("MATCH START", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.grey.shade100, border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(8)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Top 5 Matching Results:", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF14233C))),
                              if (_matchResults.isNotEmpty)
                                ElevatedButton.icon(
                                  onPressed: _exportReport,
                                  icon: const Icon(Icons.download, size: 16),
                                  label: const Text("Export as JPG", style: TextStyle(fontSize: 11)),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.purple.shade700, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6)),
                                ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Expanded(
                            child: _matchResults.isEmpty
                                ? const Center(child: Text("Catalog se laminate chunein ya photo upload karke box se color select karein...", style: TextStyle(fontSize: 12, color: Colors.grey)))
                                : ListView.builder(
                                    itemCount: _matchResults.length,
                                    itemBuilder: (context, index) {
                                      var item = _matchResults.length > index ? _matchResults[index] : null;
                                      if (item == null) return const SizedBox.shrink();
                                      String brand = item['brand'] ?? '';
                                      String name = item['name'] ?? '';
                                      String filename = item['filename'] ?? '';
                                      double score = (item['score'] ?? 0) * 100;
                                      String imgUrl = '$baseUrl/edge/$filename';

                                      return Container(
                                        margin: const EdgeInsets.only(bottom: 8),
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          border: Border.all(color: index == 0 ? Colors.green.shade600 : Colors.grey.shade300, width: index == 0 ? 2 : 1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 80,
                                              height: 80,
                                              decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(6)),
                                              child: Image.network(imgUrl, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.broken_image, size: 25)),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Text("Rank ${index + 1} - $brand", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                                                      Text("${score.toStringAsFixed(1)}% Match", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: index == 0 ? Colors.green.shade700 : Colors.black54)),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text("Code/Name: $name", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Container(
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                border: Border.all(color: Colors.grey.shade400, width: 1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Center(
                child: Text("Advertisement Banner Space", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FlazzorMasterApp extends StatelessWidget {
  const FlazzorMasterApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flazzor - Interior Master Tool',
      home: MasterHomeScreen(),
    );
  }
}