import 'package:flutter/material.dart';

/// Returns a consistent accent color for a given document category or filter id.
Color documentCategoryColor(String category) {
  final key = category.trim().toLowerCase();
  return _categoryColors[key] ?? const Color(0xFF4CAF47);
}

const Map<String, Color> _categoryColors = {
  'all': Color(0xff388e3c),
  'all categories': Color(0xff388e3c),
  'my documents': Color(0xff4caf47),
  'ownership & legal': Color(0xff2b7fff),
  // common typo casing
  'ownership & leagal': Color(0xff2b7fff),
  'technical building docs': Color(0xffad46ff),
  'technical building': Color(0xffad46ff),
  'energy & environmental': Color(0xff00c951),
  'compliance & safety': Color(0xffff6900),
  // common typo casing
  'complience & safety': Color(0xffff6900),
  'administrative & maintenance': Color(0xff388e3c),
  // common misspelling safeguard
  'administratative & maintenance': Color(0xff388e3c),
};

