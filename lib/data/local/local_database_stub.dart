import '../../models/user_profile.dart';

/// Web stub for LocalDatabase: no-op persistence to avoid sqlite/FFI on web builds.
class LocalDatabase {
  Future<UserProfile?> fetchProfile(String userId) async => null;
  Future<void> upsertProfile(UserProfile profile) async {}
  Future<void> enqueueProfileSync(UserProfile profile) async {}
  Future<void> removePending(String id) async {}
  Future<void> clearProfile(String userId) async {}
  Future<List<PendingMutationStub>> pendingMutations() async => [];
}

class PendingMutationStub {
  PendingMutationStub(this.id, this.payload);
  final String id;
  final String payload;
}
