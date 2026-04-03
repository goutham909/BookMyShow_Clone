import '../models/catalog_models.dart';
import '../sources/mock_catalog_source.dart';

class CatalogRepository {
  CatalogRepository(this._source);

  final MockCatalogSource _source;
  Catalog? _cache;

  Future<Catalog> getCatalog({bool forceRefresh = false}) async {
    if (_cache != null && !forceRefresh) return _cache!;
    _cache = await _source.load();
    return _cache!;
  }
}
