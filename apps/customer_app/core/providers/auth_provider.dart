import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_profile.dart';
import '../services/auth_service.dart';

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

final userProfileProvider = FutureProvider.family<UserProfile?, String>(
  (ref, uid) => ref.watch(authServiceProvider).getUserProfile(uid),
);

final currentProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) {
      if (user == null) return null;
      return ref.watch(authServiceProvider).getUserProfile(user.uid);
    },
    loading: () => null,
    error: (_, __) => null,
  );
});
