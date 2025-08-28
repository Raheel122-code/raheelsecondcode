import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../auth/models/user_model.dart';

class ProfileHeader extends StatelessWidget {
  final UserModel user;
  final Function(File) onUpdateProfilePic;

  const ProfileHeader({
    Key? key,
    required this.user,
    required this.onUpdateProfilePic,
  }) : super(key: key);

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );

    if (pickedFile != null) {
      onUpdateProfilePic(File(pickedFile.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundImage:
                    user.profilePic.isNotEmpty
                        ? NetworkImage(user.profilePic) as ImageProvider
                        : const AssetImage('assets/default_avatar.jpg'),
                onBackgroundImageError: (exception, stackTrace) {
                  debugPrint('Error loading profile image: $exception');
                },
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.edit, color: Colors.white),
                    onPressed: _pickImage,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(user.username, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(user.email, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}
