import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/report.dart';
import '../../domain/repositories/report_repository.dart';
import '../firestore/firestore_collections.dart';

class FirestoreReportRepository implements ReportRepository {
  const FirestoreReportRepository(this._db);

  final FirebaseFirestore _db;

  @override
  Future<void> create(Report report) async {
    final ref = FirestoreCollections.reports(_db).doc();
    await ref.set(report);
  }
}
