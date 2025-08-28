import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import '../../../../core/storage/shared_prefs.dart';
import '../../../../providers/creator_provider.dart';
import '../../theme/creator_theme.dart';

class UploadVideoScreen extends StatefulWidget {
  const UploadVideoScreen({Key? key}) : super(key: key);

  @override
  _UploadVideoScreenState createState() => _UploadVideoScreenState();
}

class _UploadVideoScreenState extends State<UploadVideoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _captionController = TextEditingController();
  String _selectedAgeRating = 'below 18';
  dynamic _videoFile; // File for mobile, XFile for web
  dynamic _thumbnailFile; // File for mobile, XFile for web
  Uint8List? _webImageBytes; // For displaying images on web
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _generateThumbnail(String videoPath) async {
    try {
      // Only try to generate thumbnail on non-web platforms
      if (!kIsWeb) {
        final thumbnailPath = await VideoThumbnail.thumbnailFile(
          video: videoPath,
          imageFormat: ImageFormat.JPEG,
          quality: 75,
        );

        if (thumbnailPath != null) {
          setState(() {
            _thumbnailFile = File(thumbnailPath);
          });
        }
      }
    } catch (e) {
      print('Thumbnail generation failed: $e');
      // Show a message to user that they need to upload a thumbnail manually
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please upload a thumbnail manually'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _pickVideo() async {
    final pickedFile = await ImagePicker().pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(minutes: 10),
    );

    if (pickedFile != null) {
      if (kIsWeb) {
        setState(() {
          _videoFile = pickedFile;
          _thumbnailFile = null;
          _webImageBytes = null;
        });
        // On web, we can't generate thumbnail automatically
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please upload a thumbnail for your video'),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        setState(() {
          _videoFile = File(pickedFile.path);
          _thumbnailFile = null;
        });
        // Try to generate thumbnail on mobile
        await _generateThumbnail(pickedFile.path);
      }
    }
  }

  Future<void> _pickThumbnail() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );

    if (pickedFile != null) {
      if (kIsWeb) {
        // For web, read the image as bytes
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _thumbnailFile = pickedFile;
          _webImageBytes = bytes;
        });
      } else {
        // For mobile, use File
        setState(() {
          _thumbnailFile = File(pickedFile.path);
        });
      }
    }
  }

  Future<void> _uploadVideo() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_videoFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a video to upload'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_thumbnailFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please upload a thumbnail for your video'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'Upload',
            textColor: Colors.white,
            onPressed: _pickThumbnail,
          ),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Print auth token status
      final token = await SharedPreferencesHelper().getToken();
      print(
        'Auth token before upload: ${token != null ? 'Present' : 'Missing'}',
      );

      // Show upload starting message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Starting upload...'),
          duration: Duration(seconds: 1),
        ),
      );

      await context.read<CreatorProvider>().uploadVideo(
        title: _titleController.text,
        caption: _captionController.text,
        ageRating: _selectedAgeRating,
        video: _videoFile!,
        thumbnail: _thumbnailFile!,
      );

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Video uploaded successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }

      Navigator.pop(context, true); // Pass true to indicate successful upload
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: CreatorTheme.theme,
      child: Scaffold(
        backgroundColor: CreatorTheme.backgroundRed,
        appBar: AppBar(
          title: const Text('Upload Video'),
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [CreatorTheme.primaryRed, CreatorTheme.darkRed],
              ),
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
                if (_videoFile == null)
                  InkWell(
                    onTap: _pickVideo,
                    child: Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.video_call, size: 48),
                          SizedBox(height: 8),
                          Text('Tap to select video'),
                        ],
                      ),
                    ),
                  )
                else
                  Column(
                    children: [
                      Stack(
                        children: [
                          if (_thumbnailFile != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child:
                                  kIsWeb
                                      ? Image.memory(
                                        _webImageBytes!,
                                        height: 200,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      )
                                      : Image.file(
                                        _thumbnailFile!,
                                        height: 200,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                            )
                          else
                            Container(
                              height: 200,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color:
                                    Theme.of(
                                      context,
                                    ).colorScheme.surfaceVariant,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Center(
                                child: Text('No thumbnail selected'),
                              ),
                            ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.change_circle),
                                  onPressed: _pickVideo,
                                  color: Theme.of(context).primaryColor,
                                  tooltip: 'Change video',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.image),
                                  onPressed: _pickThumbnail,
                                  color: Theme.of(context).primaryColor,
                                  tooltip: 'Custom thumbnail',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Thumbnail:',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          TextButton(
                            onPressed: _pickThumbnail,
                            child: Text(
                              _thumbnailFile == null
                                  ? 'Add custom thumbnail'
                                  : 'Change thumbnail',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _captionController,
                  decoration: const InputDecoration(
                    labelText: 'Caption',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Please enter a caption';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedAgeRating,
                  decoration: const InputDecoration(
                    labelText: 'Age Rating',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'below 18',
                      child: const Text('Below 18'),
                    ),
                    DropdownMenuItem(
                      value: '18 plus',
                      child: const Text('18+'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedAgeRating = value!;
                    });
                  },
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _uploadVideo,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                  child:
                      _isLoading
                          ? const CircularProgressIndicator()
                          : const Text('Upload Video'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
