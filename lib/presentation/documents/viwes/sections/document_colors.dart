import 'package:flutter/material.dart';

/// Returns a consistent accent color for a given document category or filter id.
Color documentCategoryColor(String category) {
  final key = category.trim().toLowerCase();
  
  // First try exact match
  if (_categoryColors.containsKey(key)) {
    return _categoryColors[key]!;
  }
  
  // Try keyword-based matching for new categories
  if (key.contains('electricity') || (key.contains('bill') && key.contains('electric'))) {
    return const Color(0xffffb020); // Electricity Bill - Orange/Warning
  }
  if (key.contains('legal') && (key.contains('administrative') || key.contains('admin'))) {
    return const Color(0xff2b7fff); // legal & administrative
  }
  if (key.contains('technical') && (key.contains('unit') || key.contains('document'))) {
    return const Color(0xffad46ff); // technical documents of the unit
  }
  if ((key.contains('certificate') || key.contains('cert')) && key.contains('declaration')) {
    return const Color(0xff00c951); // certificate & declarations
  }
  if (key.contains('post') && key.contains('delivery')) {
    return const Color(0xffff6900); // post-delivery documents
  }
  
  // Default fallback color
  return const Color(0xFF4CAF47);
}

/// Returns a color for document "type" (compliance/owner/technical) used for shadows.
Color documentTypeColor(String typeKey) {
  final key = typeKey.trim().toLowerCase();
  return _typeColors[key] ?? const Color(0xFF4CAF47);
}

const Map<String, Color> _categoryColors = {
  'all': Color(0xff388e3c),
  'all categories': Color(0xff388e3c),
  // New category mappings
  'legal & administrative': Color(0xff2b7fff),
  'legal and administrative': Color(0xff2b7fff),
  'technical documents of the unit': Color(0xffad46ff),
  'certificate & declarations': Color(0xff00c951),
  'certificate and declarations': Color(0xff00c951),
  'certificates & declarations': Color(0xff00c951),
  'certificates and declarations': Color(0xff00c951),
  'post-delivery documents': Color(0xffff6900),
  'post delivery documents': Color(0xffff6900),
  // Legacy mappings for backward compatibility
  'my documents': Color(0xff4caf47), // Brand Sage Green - distinct
  'ownership & legal': Color(0xff2b7fff),
  'ownership & leagal': Color(0xff2b7fff),
  'technical building docs': Color(0xffad46ff),
  'technical building': Color(0xffad46ff),
  'energy & environmental': Color(0xff14b8a6), // Aqua Green - distinct from My Documents
  'compliance & safety': Color(0xffff6900),
  'complience & safety': Color(0xffff6900),
  'administrative & maintenance': Color(0xff2b7fff), // Blue - distinct from others
  'administratative & maintenance': Color(0xff2b7fff),
  // Electricity Bill category (if exists as separate category)
  'electricity bill': Color(0xffffb020), // Warning/Orange - distinct
  'electricity': Color(0xffffb020),
  'bill': Color(0xffffb020),
};

const Map<String, Color> _typeColors = {
  'compliance': Color(0xff00c951), // green
  'owner': Color(0xff2b7fff), // blue
  'technical': Color(0xffff8a00), // orange
};

