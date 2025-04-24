import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:id_card_generator/models/student.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SavedCardsScreen extends StatefulWidget {
  const SavedCardsScreen({super.key});

  @override
  State<SavedCardsScreen> createState() => _SavedCardsScreenState();
}

class _SavedCardsScreenState extends State<SavedCardsScreen> {
  List<Student> _savedStudents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedCards();
  }

  Future<void> _loadSavedCards() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> savedCardIds = prefs.getStringList('saved_cards') ?? [];
      
      List<Student> students = [];
      
      for (String id in savedCardIds) {
        final String? studentJson = prefs.getString('student_$id');
        if (studentJson != null) {
          try {
            final Map<String, dynamic> studentMap = jsonDecode(studentJson);
            students.add(Student.fromJson(studentMap));
          } catch (e) {
            debugPrint('Error parsing student data: $e');
          }
        }
      }
      
      setState(() {
        _savedStudents = students;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading saved cards: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteCard(String studentId) async {
    try {
      // Show confirmation dialog
      final bool confirm = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete ID Card'),
          content: const Text('Are you sure you want to delete this ID card?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ) ?? false;
      
      if (!confirm) return;
      
      final prefs = await SharedPreferences.getInstance();
      
      // Remove from saved cards list
      final List<String> savedCardIds = prefs.getStringList('saved_cards') ?? [];
      savedCardIds.remove(studentId);
      await prefs.setStringList('saved_cards', savedCardIds);
      
      // Remove student data
      await prefs.remove('student_$studentId');
      
      // Delete image files
      final directory = await getApplicationDocumentsDirectory();
      final frontFile = File('${directory.path}/id_card_${studentId}_front.png');
      final backFile = File('${directory.path}/id_card_${studentId}_back.png');
      
      if (await frontFile.exists()) {
        await frontFile.delete();
      }
      
      if (await backFile.exists()) {
        await backFile.delete();
      }
      
      // Refresh list
      _loadSavedCards();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ID Card deleted successfully')),
        );
      }
    } catch (e) {
      debugPrint('Error deleting card: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete ID Card: $e')),
        );
      }
    }
  }

  Future<void> _viewCard(Student student) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final frontFilePath = '${directory.path}/id_card_${student.id}_front.png';
      final backFilePath = '${directory.path}/id_card_${student.id}_back.png';
      
      final frontFile = File(frontFilePath);
      final backFile = File(backFilePath);
      
      if (await frontFile.exists() && await backFile.exists()) {
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SavedCardViewScreen(
                student: student,
                frontImagePath: frontFilePath,
                backImagePath: backFilePath,
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ID Card images not found')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error viewing card: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to view ID Card: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved ID Cards'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _savedStudents.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.folder_off,
                        size: 80,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No saved ID cards',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Create New ID Card'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _savedStudents.length,
                  itemBuilder: (context, index) {
                    final student = _savedStudents[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          child: Text(
                            student.name.isNotEmpty ? student.name[0] : '?',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(student.name),
                        subtitle: Text('ID: ${student.id} • ${student.program}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.visibility),
                              onPressed: () => _viewCard(student),
                              tooltip: 'View',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteCard(student.id),
                              tooltip: 'Delete',
                            ),
                          ],
                        ),
                        onTap: () => _viewCard(student),
                      ),
                    );
                  },
                ),
    );
  }
}

class SavedCardViewScreen extends StatefulWidget {
  final Student student;
  final String frontImagePath;
  final String backImagePath;

  const SavedCardViewScreen({
    super.key,
    required this.student,
    required this.frontImagePath,
    required this.backImagePath,
  });

  @override
  State<SavedCardViewScreen> createState() => _SavedCardViewScreenState();
}

class _SavedCardViewScreenState extends State<SavedCardViewScreen> {
  bool _showFront = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.student.name}\'s ID Card'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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
            GestureDetector(
              onTap: () {
                setState(() {
                  _showFront = !_showFront;
                });
              },
              child: Container(
                width: 320,
                height: 200,
                decoration: BoxDecoration(
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
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(
                    File(_showFront ? widget.frontImagePath : widget.backImagePath),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Tap card to flip',
              style: TextStyle(
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

