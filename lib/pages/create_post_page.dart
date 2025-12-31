import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'dart:typed_data';
import '../widgets/input_field.dart';
import '../models/post_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final _formKey = GlobalKey<FormState>();
  final _itemNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _contactController = TextEditingController();

  String? _selectedType; // "Lost" or "Found"
  DateTime? _selectedDate;
  File? _selectedImage;
  Uint8List? _selectedImageBytes;
  bool _isSubmitting = false;
  
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();

  @override
  void dispose() {
    _itemNameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);

    if (image != null) {
      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImageBytes = bytes;
          _selectedImage = null;
        });
      } else {
        setState(() {
          _selectedImage = File(image.path);
          _selectedImageBytes = null;
        });
      }
    }
  }

  Future<void> _showImageSourceDialog() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Image Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      helpText: 'Select Date',
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  Future<void> _submitPost() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a post type (Lost or Found)'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a date'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Get current user
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw Exception('You must be logged in to create a post');
      }

      // Get user data
      final userData = await _authService.getUserData(currentUser.uid);
      final userName = userData?.name ?? currentUser.displayName ?? 'ReTurnHub User';
      final userAvatar = userData?.profileImage ?? currentUser.photoURL ?? '';

      // Upload image if selected using Supabase
      String? imageUrl;
      if (kIsWeb && _selectedImageBytes != null) {
        imageUrl = await _apiService.uploadImageBytesToSupabase(
          _selectedImageBytes!,
          currentUser.uid,
        );
      } else if (!kIsWeb && _selectedImage != null) {
        imageUrl = await _apiService.uploadImageToSupabase(_selectedImage!, currentUser.uid);
      }

      // Prepare post content
      final postContent = '''
Type: $_selectedType
Item: ${_itemNameController.text.trim()}
Description: ${_descriptionController.text.trim()}
Location: ${_locationController.text.trim()}
Date: ${_selectedDate!.toLocal().toString().split(' ')[0]}
Contact: ${_contactController.text.trim()}
''';

      // Create Post object
      final post = Post(
        id: '', // Will be auto-generated by Firestore
        userId: currentUser.uid,
        userName: userName,
        userAvatar: userAvatar,
        content: postContent,
        imageUrl: imageUrl,
        createdAt: DateTime.now(),
        likesCount: 0,
        commentsCount: 0,
        isLiked: false,
        type: _selectedType?.toLowerCase(),
        location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
        contact: _contactController.text.trim().isEmpty ? null : _contactController.text.trim(),
      );

      // Call submit function and capture id
      final newPostId = await _apiService.submitPost(post);
      final savedPost = post.copyWith(
        id: newPostId,
        createdAt: DateTime.now(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post created successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context, savedPost);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating post: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Create Post',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Post Type Dropdown
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: InputDecoration(
                  labelText: 'Post Type *',
                  prefixIcon: const Icon(Icons.category),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'Lost',
                    child: Text('Lost'),
                  ),
                  DropdownMenuItem(
                    value: 'Found',
                    child: Text('Found'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedType = value;
                  });
                },
                validator: (value) => _validateRequired(value, 'Post type'),
              ),
              const SizedBox(height: 20),

              // Item Name
              InputField(
                label: 'Item Name *',
                hint: 'Enter the name of the item',
                controller: _itemNameController,
                validator: (value) => _validateRequired(value, 'Item name'),
                prefixIcon: Icons.label,
                keyboardType: TextInputType.text,
              ),
              const SizedBox(height: 20),

              // Description
              InputField(
                label: 'Description *',
                hint: 'Describe the item in detail',
                controller: _descriptionController,
                validator: (value) => _validateRequired(value, 'Description'),
                prefixIcon: Icons.description,
                keyboardType: TextInputType.multiline,
                maxLines: 5,
              ),
              const SizedBox(height: 20),

              // Location
              InputField(
                label: 'Location *',
                hint: 'Where was it lost/found?',
                controller: _locationController,
                validator: (value) => _validateRequired(value, 'Location'),
                prefixIcon: Icons.location_on,
                keyboardType: TextInputType.text,
              ),
              const SizedBox(height: 20),

              // Date Picker
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[400]!),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey[50],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Colors.grey),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _selectedDate == null
                            ? 'Select Date Lost/Found *'
                            : _selectedDate!.toLocal().toString().split(' ')[0],
                        style: TextStyle(
                          fontSize: 16,
                          color: _selectedDate == null
                              ? Colors.grey[600]
                              : Colors.black87,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_drop_down),
                      onPressed: _selectDate,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Contact Information
              InputField(
                label: 'Contact Information *',
                hint: 'Phone number or email',
                controller: _contactController,
                validator: (value) =>
                    _validateRequired(value, 'Contact information'),
                prefixIcon: Icons.contact_phone,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 20),

              // Image Picker Section
              const Text(
                'Item Image',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _showImageSourceDialog,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[400]!, width: 2),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[100],
                  ),
                  child: (_selectedImage == null && _selectedImageBytes == null)
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate,
                              size: 48,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap to add image',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: kIsWeb
                              ? Image.memory(
                                  _selectedImageBytes!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: 200,
                                )
                              : Image.file(
                                  _selectedImage!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: 200,
                                ),
                        ),
                ),
              ),
              if (_selectedImage != null || _selectedImageBytes != null) ...[
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedImage = null;
                      _selectedImageBytes = null;
                    });
                  },
                  icon: const Icon(Icons.delete, color: Colors.red),
                  label: const Text(
                    'Remove Image',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
              const SizedBox(height: 32),

              // Submit Button
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitPost,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Submit Post',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

