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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Material(
        elevation: 4,
        shadowColor: const Color(0x22388E3C),
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withOpacity(0.9),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFFF7FAF7),
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: TextField(
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.transparent,
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              hintText: "searchDocuments".tr,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }
}
