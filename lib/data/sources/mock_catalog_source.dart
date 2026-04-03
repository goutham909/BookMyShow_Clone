import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/catalog_models.dart';

class MockCatalogSource {
  static const assetPath = 'assets/mock/catalog.json';

  Future<Catalog> load() async {
    final raw = await rootBundle.loadString(assetPath);
    final map = json.decode(raw) as Map<String, dynamic>;
    return Catalog.fromJson(map);
  }
}
