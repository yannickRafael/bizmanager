import '../../core/database/database_service.dart';
import '../../core/models/partner.dart';
import '../../core/repositories/base_repository.dart';

class PartnerRepository implements BaseRepository<Partner> {
  final _db = DatabaseService.instance;
  static const _table = 'partners';

  @override
  Future<void> insert(Partner item) => _db.insert(_table, item.toMap());

  @override
  Future<List<Partner>> getAll() async {
    final maps = await _db.queryAll(_table);
    return maps.map((m) => Partner.fromMap(m)).toList();
  }

  @override
  Future<void> update(Partner item) => _db.update(_table, item.toMap(), item.id);

  @override
  Future<void> delete(String id) => _db.delete(_table, id);

  @override
  Future<void> deleteByBatchId(String batchId) async {
    // Partners don't belong to batches — no-op
  }
}
