import 'package:flutter/material.dart';

class ProfilePhotoViewer extends StatelessWidget {
  final String imageUrl;
  final String displayName;

  const ProfilePhotoViewer({
    super.key,
    required this.imageUrl,
    required this.displayName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(displayName),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.8,
          maxScale: 4,
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return const CircularProgressIndicator(color: Colors.white);
            },
            errorBuilder: (_, error, stackTrace) => const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.broken_image_outlined,
                  color: Colors.white70,
                  size: 52,
                ),
                SizedBox(height: 12),
                Text(
                  'Unable to load this photo.',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
