import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/auth_service.dart';

final adminAuthStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(adminAuthServiceProvider).authStateChanges;
});
