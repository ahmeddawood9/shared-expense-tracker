import 'package:flutter/material.dart';

// ════════════════════════════════════════════════════════════
//  PALETTE
// ════════════════════════════════════════════════════════════
class C {
  static const cream = Color(0xFFFDF8F2);
  static const cardWhite = Color(0xFFFFFFFF);
  static const softGray = Color(0xFFF2EFE9);
  static const mango = Color(0xFFFF6B35);
  static const mangoLight = Color(0xFFFF8C55);
  static const sage = Color(0xFF52B788);
  static const rose = Color(0xFFE05780);
  static const ink = Color(0xFF1A1207);
  static const subtext = Color(0xFF7A6E63);
  static const muted = Color(0xFFBBB1A5);

  static const currency = 'Rs.';
  static const roomName = 'Room 42';
}

// ════════════════════════════════════════════════════════════
//  CATEGORIES
// ════════════════════════════════════════════════════════════
class Cat {
  final String label, short;
  final IconData icon;
  final Color color, bg;
  const Cat(this.label, this.short, this.icon, this.color, this.bg);
}

const cats = [
  Cat(
    'General',
    'General',
    Icons.home_rounded,
    Color(0xFF7B61FF),
    Color(0xFFF0EEFF),
  ),
  Cat(
    'Utilities',
    'Utility',
    Icons.bolt_rounded,
    Color(0xFFF4A261),
    Color(0xFFFFF3E8),
  ),
  Cat(
    'Groceries',
    'Grocery',
    Icons.shopping_bag_rounded,
    Color(0xFF52B788),
    Color(0xFFEBF7F1),
  ),
  Cat(
    'Internet',
    'Internet',
    Icons.wifi_rounded,
    Color(0xFF3A86FF),
    Color(0xFFEBF3FF),
  ),
  Cat(
    'Food',
    'Food',
    Icons.restaurant_rounded,
    Color(0xFFE05780),
    Color(0xFFFFEBF1),
  ),
  Cat(
    'Transport',
    'Transport',
    Icons.directions_bus_rounded,
    Color(0xFF8338EC),
    Color(0xFFF3EBFF),
  ),
  Cat(
    'Maintenance',
    'Maint.',
    Icons.build_rounded,
    Color(0xFF607D8B),
    Color(0xFFECEFF1),
  ),
];
