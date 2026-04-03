import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/catalog_models.dart';
import '../data/repositories/catalog_repository.dart';
import '../data/sources/mock_catalog_source.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden in ProviderScope');
});

final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
  return CatalogRepository(MockCatalogSource());
});

final catalogProvider = FutureProvider<Catalog>((ref) async {
  final repo = ref.watch(catalogRepositoryProvider);
  return repo.getCatalog();
});

class HomeCityLabelNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void setCity(String city) => state = city;
}

/// Home header city label override after user picks a region (demo).
final homeCityLabelProvider = NotifierProvider<HomeCityLabelNotifier, String?>(HomeCityLabelNotifier.new);

class SavedBooking {
  const SavedBooking({
    required this.id,
    required this.movieTitle,
    required this.venueName,
    required this.showLabel,
    required this.seats,
    required this.totalInr,
    required this.placedAtIso,
  });

  final String id;
  final String movieTitle;
  final String venueName;
  final String showLabel;
  final List<String> seats;
  final double totalInr;
  final String placedAtIso;

  Map<String, dynamic> toJson() => {
        'id': id,
        'movieTitle': movieTitle,
        'venueName': venueName,
        'showLabel': showLabel,
        'seats': seats,
        'totalInr': totalInr,
        'placedAtIso': placedAtIso,
      };

  factory SavedBooking.fromJson(Map<String, dynamic> j) {
    return SavedBooking(
      id: j['id'] as String,
      movieTitle: j['movieTitle'] as String,
      venueName: j['venueName'] as String,
      showLabel: j['showLabel'] as String,
      seats: (j['seats'] as List<dynamic>).cast<String>(),
      totalInr: (j['totalInr'] as num).toDouble(),
      placedAtIso: j['placedAtIso'] as String,
    );
  }
}

const _bookingsKey = 'showtickets_bookings_v1';

class BookingsNotifier extends Notifier<List<SavedBooking>> {
  @override
  List<SavedBooking> build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final raw = prefs.getString(_bookingsKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = json.decode(raw) as List<dynamic>;
      return list.map((e) => SavedBooking.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> add(SavedBooking booking) async {
    final next = [booking, ...state];
    state = next;
    await _persist(next);
  }

  Future<void> clearAll() async {
    state = const [];
    await _persist(const []);
  }

  Future<void> _persist(List<SavedBooking> list) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(
      _bookingsKey,
      json.encode(list.map((e) => e.toJson()).toList()),
    );
  }
}

final bookingsProvider = NotifierProvider<BookingsNotifier, List<SavedBooking>>(BookingsNotifier.new);
