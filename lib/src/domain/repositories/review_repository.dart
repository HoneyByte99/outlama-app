import '../models/review.dart';

abstract interface class ReviewRepository {
  Stream<List<Review>> watchForBooking(String bookingId);
  Stream<List<Review>> watchForUser(String userId);

  Future<Review> create(Review review);
}
