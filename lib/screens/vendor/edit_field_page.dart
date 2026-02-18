import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class EditFieldPage extends StatefulWidget {
  final String title;
  final List<FieldConfig> fields;
  final String collectionName;

  const EditFieldPage({
    super.key,
    required this.title,
    required this.fields,
    this.collectionName = 'users',
  });

  @override
  State<EditFieldPage> createState() => _EditFieldPageState();
}

class FieldConfig {
  final String key;
  final String label;
  final String currentValue;
  final TextInputType inputType;
  final int maxLines;

  FieldConfig({
    required this.key,
    required this.label,
    required this.currentValue,
    this.inputType = TextInputType.text,
    this.maxLines = 1,
  });
}

class _EditFieldPageState extends State<EditFieldPage> {
  final _formKey = GlobalKey<FormState>();
  late Map<String, TextEditingController> _controllers;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controllers = {
      for (var field in widget.fields)
        field.key: TextEditingController(text: field.currentValue)
    };
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final Map<String, dynamic> updates = {
            for (var entry in _controllers.entries) entry.key: entry.value.text.trim()
          };

          await FirebaseFirestore.instance
              .collection(widget.collectionName)
              .doc(user.uid)
              .set(updates, SetOptions(merge: true));

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Updated successfully!'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context);
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update: $e'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final hintColor = isDark ? Colors.white10 : Colors.black26;
    final surfaceColor = isDark ? const Color(0xFF1E1E1E) : Colors.grey[100]!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Edit ${widget.title}',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: textColor),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).iconTheme.color),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFA5211)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...widget.fields.map((field) => Padding(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                field.label,
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _controllers[field.key],
                                keyboardType: field.inputType,
                                maxLines: field.maxLines,
                                style: TextStyle(color: textColor),
                                decoration: InputDecoration(
                                  hintText: 'Enter ${field.label}',
                                  hintStyle: TextStyle(color: hintColor),
                                  filled: true,
                                  fillColor: surfaceColor,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFFA5211),
                                      width: 1.5,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 18,
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter ${field.label}';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        )),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        onPressed: _saveChanges,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFA5211),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          'Save Changes',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
