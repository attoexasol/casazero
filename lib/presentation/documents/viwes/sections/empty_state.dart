import 'package:flutter/material.dart';

class EmptyState extends StatelessWidget {
  final String title;
  final String description;

  const EmptyState({
    super.key,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.insert_drive_file_outlined,
                size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            )
          ],
        ),
      ),
    );
  }
}
