import '../../core/database/database_service.dart';
import '../../core/models/farm.dart';
import '../../core/repositories/base_repository.dart';

class FarmRepository implements BaseRepository<Farm> {
  final _db = DatabaseService.instance;
  static const _table = 'farms';

  @override
  Future<void> insert(Farm item) => _db.insert(_table, item.toMap());

  @override
  Future<List<Farm>> getAll() async {
    final maps = await _db.queryAll(_table);
    return maps.map((m) => Farm.fromMap(m)).toList();
  }

  @override
  Future<void> update(Farm item) => _db.update(_table, item.toMap(), item.id);

  @override
  Future<void> delete(String id) => _db.delete(_table, id);

  @override
  Future<void> deleteByBatchId(String batchId) async {
    // Farms don't belong to batches — no-op
  }
}
