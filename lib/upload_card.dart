
import 'dart:typed_data';

import 'package:flutter/material.dart';

class UploadCard extends StatelessWidget {
  final String title;
  final Uint8List? bytes;
  final bool primary;
  final VoidCallback onPick;

  const UploadCard({super.key,
    required this.title,
    required this.bytes,
    required this.primary,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0E1B2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: primary ? cs.primary : const Color(0xFF1E3558),
          width: primary ? 1.4 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 10),
          Expanded(
            child: InkWell(
              onTap: onPick,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: primary ? cs.primary : const Color(0xFF1E3558),
                    style: BorderStyle.solid,
                  ),
                ),
                child: bytes == null
                    ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.upload,
                          size: 34,
                          color: primary ? cs.primary : Colors.white54),
                      const SizedBox(height: 10),
                      const Text('Drop image here',
                          style: TextStyle(color: Colors.white70)),
                      const SizedBox(height: 4),
                      const Text('or click to browse',
                          style: TextStyle(color: Colors.white38)),
                    ],
                  ),
                )
                    : ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.memory(
                    bytes!,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

