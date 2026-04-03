import '../models/report.dart';

abstract interface class ReportRepository {
  Future<void> create(Report report);
}
