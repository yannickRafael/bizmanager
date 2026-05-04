/// Generic CRUD interface for all repositories.
///
/// Each animal module and shared feature implements this for its entities.
abstract class BaseRepository<T> {
  Future<void> insert(T item);
  Future<List<T>> getAll();
  Future<void> update(T item);
  Future<void> delete(String id);

  /// Delete all records linked to a batch (cascading support).
  Future<void> deleteByBatchId(String batchId);
}
