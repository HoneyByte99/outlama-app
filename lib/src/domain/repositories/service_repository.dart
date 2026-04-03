import '../models/service.dart';

abstract interface class ServiceRepository {
  Stream<Service?> watchById(String serviceId);
  Stream<List<Service>> watchAllPublished();
  Stream<List<Service>> watchForProvider(String providerId);

  Future<Service> create(Service service);
  Future<void> update(Service service);
}
