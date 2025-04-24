import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:id_card_generator/models/student.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class IDPreviewScreen extends StatefulWidget {
  final Student student;

  const IDPreviewScreen({super.key, required this.student});

  @override
  State<IDPreviewScreen> createState() => _IDPreviewScreenState();
}

class _IDPreviewScreenState extends State<IDPreviewScreen> {
  final GlobalKey _frontCardKey = GlobalKey();
  final GlobalKey _backCardKey = GlobalKey();
  bool _isSaving = false;
  bool _showFront = true;

  Future<void> _saveCard() async {
    setState(() {
      _isSaving = true;
    });

    try {
      // Request storage permission
      var status = await Permission.storage.request();
      if (!status.isGranted) {
        _showSnackBar('Storage permission denied');
        setState(() {
          _isSaving = false;
        });
        return;
      }

      // Save front card
      await _saveCardSide(_frontCardKey, 'front');
      
      // Save back card
      setState(() {
        _showFront = false;
      });
      
      // Wait for the widget to rebuild
      await Future.delayed(const Duration(milliseconds: 100));
      
      await _saveCardSide(_backCardKey, 'back');
      
      // Save student data
      await _saveStudentData();

      _showSnackBar('ID Card saved successfully');
    } catch (e) {
      _showSnackBar('Failed to save ID Card: $e');
    } finally {
      setState(() {
        _isSaving = false;
        _showFront = true;
      });
    }
  }

  Future<void> _saveCardSide(GlobalKey key, String side) async {
    final RenderRepaintBoundary boundary = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List pngBytes = byteData!.buffer.asUint8List();
    
    final directory = await getApplicationDocumentsDirectory();
    final String path = '${directory.path}/id_card_${widget.student.id}_$side.png';
    final File file = File(path);
    await file.writeAsBytes(pngBytes);
  }

  Future<void> _saveStudentData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Get existing saved cards
    List<String> savedCards = prefs.getStringList('saved_cards') ?? [];
    
    // Add current student ID if not already saved
    if (!savedCards.contains(widget.student.id)) {
      savedCards.add(widget.student.id);
      await prefs.setStringList('saved_cards', savedCards);
    }
    
    // Save student data
    await prefs.setString('student_${widget.student.id}', jsonEncode(widget.student.toJson()));
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ID Card Preview'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Text(
                'Preview',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _showFront = true;
                      });
                    },
                    icon: const Icon(Icons.credit_card),
                    label: const Text('Front'),
                    style: TextButton.styleFrom(
                      foregroundColor: _showFront ? Theme.of(context).colorScheme.primary : Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 20),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _showFront = false;
                      });
                    },
                    icon: const Icon(Icons.flip),
                    label: const Text('Back'),
                    style: TextButton.styleFrom(
                      foregroundColor: !_showFront ? Theme.of(context).colorScheme.primary : Colors.grey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (_showFront)
                RepaintBoundary(
                  key: _frontCardKey,
                  child: _buildFrontCard(),
                )
              else
                RepaintBoundary(
                  key: _backCardKey,
                  child: _buildBackCard(),
                ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveCard,
                  icon: _isSaving 
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save),
                  label: Text(
                    _isSaving ? 'Saving...' : 'Save ID Card',
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFrontCard() {
    return Container(
      width: 320,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background design
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF1A237E).withOpacity(0.1),
                  const Color(0xFF1A237E).withOpacity(0.05),
                ],
              ),
            ),
          ),
          
          // University logo at top
          Positioned(
            top: 10,
            left: 10,
            child: Image.asset(
              'assets/university_logo.png',
              height: 40,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.school, size: 40, color: Color(0xFF1A237E));
              },
            ),
          ),
          
          // University name
          const Positioned(
            top: 15,
            left: 60,
            child: Text(
              'UNIVERSITY NAME',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A237E),
              ),
            ),
          ),
          
          // Student photo
          Positioned(
            top: 60,
            left: 15,
            child: Container(
              width: 80,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                border: Border.all(color: Colors.grey),
              ),
              child: widget.student.photoPath != null
                  ? Image.file(
                      File(widget.student.photoPath!),
                      fit: BoxFit.cover,
                    )
                  : const Icon(
                      Icons.person,
                      size: 50,
                      color: Colors.grey,
                    ),
            ),
          ),
          
          // Student details
          Positioned(
            top: 60,
            left: 110,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.student.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ID: ${widget.student.id}',
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.student.program,
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.student.department,
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  'Batch: ${widget.student.batch}',
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  'Valid until: ${widget.student.validUntil}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          
          // Barcode at bottom
          Positioned(
            bottom: 10,
            left: 15,
            right: 15,
            child: SizedBox(
              height: 30,
              child: BarcodeWidget(
                barcode: Barcode.code128(),
                data: widget.student.id,
                drawText: false,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackCard() {
    return Container(
      width: 320,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background design
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF1A237E).withOpacity(0.05),
                  const Color(0xFF1A237E).withOpacity(0.1),
                ],
              ),
            ),
          ),
          
          // University logo watermark
          Center(
            child: Opacity(
              opacity: 0.1,
              child: Image.asset(
                'assets/university_logo.png',
                height: 100,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.school, size: 100, color: Color(0xFF1A237E));
                },
              ),
            ),
          ),
          
          // Contact information
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CONTACT INFORMATION',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A237E),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.phone, size: 14, color: Colors.grey),
                    const SizedBox(width: 5),
                    Text(
                      widget.student.contactNumber.isNotEmpty 
                          ? widget.student.contactNumber 
                          : 'Not provided',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(Icons.email, size: 14, color: Colors.grey),
                    const SizedBox(width: 5),
                    Text(
                      widget.student.email,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(Icons.bloodtype, size: 14, color: Colors.grey),
                    const SizedBox(width: 5),
                    Text(
                      'Blood Group: ${widget.student.bloodGroup.isNotEmpty ? widget.student.bloodGroup : 'Not provided'}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // University address
          const Positioned(
            bottom: 50,
            left: 20,
            right: 20,
            child: Column(
              children: [
                Text(
                  'UNIVERSITY ADDRESS',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A237E),
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  '123 University Avenue, City, Country',
                  style: TextStyle(fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 5),
                Text(
                  'www.university.edu',
                  style: TextStyle(fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          
          // If found text
          const Positioned(
            bottom: 15,
            left: 20,
            right: 20,
            child: Text(
              'If found, please return to the University Administration Office',
              style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

