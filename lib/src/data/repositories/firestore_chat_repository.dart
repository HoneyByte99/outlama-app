import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/chat.dart';
import '../../domain/models/chat_message.dart';
import '../../domain/repositories/chat_repository.dart';
import '../firestore/firestore_collections.dart';

class FirestoreChatRepository implements ChatRepository {
  const FirestoreChatRepository(this._db);

  final FirebaseFirestore _db;

  @override
  Stream<Chat?> watchChat(String chatId) {
    return FirestoreCollections.chats(_db)
        .doc(chatId)
        .snapshots()
        .map((snap) => snap.exists ? snap.data() : null);
  }

  @override
  Stream<List<ChatMessage>> watchMessages({
    required String chatId,
    int limit = 50,
  }) {
    return FirestoreCollections.chatMessages(db: _db, chatId: chatId)
        .orderBy('createdAt', descending: false)
        .limitToLast(limit)
        .snapshots()
        .map((qs) => qs.docs.map((d) => d.data()).toList());
  }

  @override
  Future<ChatMessage> sendMessage(ChatMessage message) async {
    final col = FirestoreCollections.chatMessages(
      db: _db,
      chatId: message.chatId,
    );
    final ref = col.doc();
    await ref.set(message);
    final snap = await ref.get();
    return snap.data()!;
  }
}
