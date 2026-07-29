import 'dart:typed_data';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';

class AvatarCropScreen extends StatefulWidget {
  final Uint8List imageData;

  const AvatarCropScreen({super.key, required this.imageData});

  @override
  State<AvatarCropScreen> createState() => _AvatarCropScreenState();
}

class _AvatarCropScreenState extends State<AvatarCropScreen> {
  final CropController cropController = CropController();
  bool isCropping = false;

  void cropImage() {
    if (isCropping) return;
    setState(() => isCropping = true);
    cropController.crop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Crop profile photo'),
        actions: [
          TextButton(
            onPressed: isCropping ? null : cropImage,
            child: const Text(
              'Done',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            Crop(
              image: widget.imageData,
              controller: cropController,
              onCropped: (result) {
                switch (result) {
                  case CropSuccess(:final croppedImage):
                    Navigator.of(context).pop(croppedImage);
                  case CropFailure(:final cause):
                    setState(() => isCropping = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Unable to crop photo: $cause')),
                    );
                }
              },
              withCircleUi: true,
              aspectRatio: 1,
              interactive: true,
              fixCropRect: true,
              initialRectBuilder: InitialRectBuilder.withSizeAndRatio(
                size: 0.82,
                aspectRatio: 1,
              ),
              baseColor: Colors.black,
              maskColor: Colors.black.withValues(alpha: 0.62),
              progressIndicator: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
            Positioned(
              left: 24,
              right: 24,
              bottom: 24,
              child: IgnorePointer(
                child: Text(
                  'Drag to reposition • Pinch or scroll to zoom',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            if (isCropping)
              const ColoredBox(
                color: Color(0x55000000),
                child: Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
