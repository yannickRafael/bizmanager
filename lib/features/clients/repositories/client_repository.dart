import '../../core/database/database_service.dart';
import '../../core/models/client.dart';
import '../../core/repositories/base_repository.dart';

class ClientRepository implements BaseRepository<Client> {
  final _db = DatabaseService.instance;
  static const _table = 'clients';

  @override
  Future<void> insert(Client item) => _db.insert(_table, item.toMap());

  @override
  Future<List<Client>> getAll() async {
    final maps = await _db.queryAll(_table);
    return maps.map((m) => Client.fromMap(m)).toList();
  }

  @override
  Future<void> update(Client item) => _db.update(_table, item.toMap(), item.id);

  @override
  Future<void> delete(String id) => _db.delete(_table, id);

  @override
  Future<void> deleteByBatchId(String batchId) async {
    // Clients don't belong to batches — no-op
  }
}
