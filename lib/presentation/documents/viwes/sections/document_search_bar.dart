import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DocumentSearchBar extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const DocumentSearchBar({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          hintText: "searchDocuments".tr,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
        onChanged: onChanged,
      ),
    );
  }
}
