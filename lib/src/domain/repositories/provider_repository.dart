import '../models/provider_profile.dart';

abstract interface class ProviderRepository {
  Stream<ProviderProfile?> watchByUid(String uid);
  Stream<List<ProviderProfile>> watchAll();

  Future<void> upsert(ProviderProfile profile);
}
