import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/job.dart';
import '../config/app_config.dart';
import 'api_client.dart';

final jobServiceProvider = Provider<JobService>((ref) => JobService());

class JobService {
  final Dio _dio = createDio();

  Stream<List<Job>> watchMyJobs() {
    final controller = StreamController<List<Job>>();

    Future<void> fetch() async {
      if (controller.isClosed) return;
      try {
        final res = await _dio.get('/bookings');
        final list = (res.data as List)
            .map((j) => Job.fromJson(j as Map<String, dynamic>))
            .where((j) => j.status != JobStatus.cancelled && j.status != JobStatus.completed)
            .toList()
          ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
        if (!controller.isClosed) controller.add(list);
      } catch (_) {}
    }

    fetch();
    final timer = Timer.periodic(AppConfig.jobPollInterval, (_) => fetch());
    controller.onCancel = () => timer.cancel();

    return controller.stream;
  }

  Future<void> updateStatus(String jobId, JobStatus status) =>
      _dio.patch('/bookings/$jobId/status', data: {'status': status.name});
}
