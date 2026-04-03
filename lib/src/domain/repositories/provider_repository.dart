import '../models/blocked_slot.dart';
import '../models/provider_profile.dart';

abstract interface class ProviderRepository {
  Stream<ProviderProfile?> watchByUid(String uid);
  Stream<List<ProviderProfile>> watchAll();
  Future<void> upsert(ProviderProfile profile);

  // Blocked slots
  Stream<List<BlockedSlot>> watchBlockedSlots(String uid);
  Future<void> addBlockedSlot(String uid, BlockedSlot slot);
  Future<void> removeBlockedSlot(String uid, String slotId);
}
