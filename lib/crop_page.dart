
import 'dart:typed_data';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';
class CropPage extends StatefulWidget {
  final Uint8List imageBytes;

  const CropPage({super.key, required this.imageBytes});

  @override
  State<CropPage> createState() => _CropPageState();
}

class _CropPageState extends State<CropPage> {
  final controller = CropController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          Expanded(
            child: Crop(
              image: widget.imageBytes,
              controller: controller,

              onCropped: (result) {
                if (result is CropSuccess) {
                  Navigator.pop(context, result.croppedImage);
                }
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(10),
            child: ElevatedButton(
              onPressed: () {
                controller.crop(); // trigger crop
              },
              child: const Text("Crop & Done"),
            ),
          ),
        ],
      ),
    );
  }
}
