import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/remote/review_remote.dart';
import '../services/review_service.dart';

// Provider ini akan menyimpan angka antrian
final pendingCountProvider = FutureProvider<int>((ref) async {
  return await ReviewRemote().countPendingQuestions();
});

// Provider daftar antrian (bisa di-refresh)
final reviewQueueProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  return await ReviewService.instance.getAntrianReview();
});

