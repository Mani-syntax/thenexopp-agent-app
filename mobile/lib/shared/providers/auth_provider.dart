import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_constants.dart';
import '../../core/storage/secure_storage_service.dart';
import 'dio_provider.dart';

enum AuthStatus { unauthenticated, authenticating, authenticated }

class AuthState {
  final AuthStatus status;
  final String? agentState; // NEW, PROFILE_INCOMPLETE, KYC_INCOMPLETE, BANK_DETAILS_INCOMPLETE, PENDING_APPROVAL, APPROVED, REJECTED, SUSPENDED
  final String? mobileNumber;
  final String? rejectionReason;
  final String? errorMessage;

  AuthState({
    required this.status,
    this.agentState,
    this.mobileNumber,
    this.rejectionReason,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? agentState,
    String? mobileNumber,
    String? rejectionReason,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      agentState: agentState ?? this.agentState,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final SecureStorageService _storage;
  final Ref _ref;

  AuthNotifier(this._storage, this._ref)
      : super(AuthState(status: AuthStatus.authenticating)) {
    checkInitialAuth();
  }

  Future<void> checkInitialAuth() async {
    final token = await _storage.getAccessToken();
    final savedState = await _storage.getAgentState();
    if (token != null && token.isNotEmpty && savedState != null) {
      state = state.copyWith(
        status: AuthStatus.authenticated,
        agentState: savedState,
      );
    } else {
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  Future<bool> sendOtp(String mobileNumber) async {
    state = state.copyWith(mobileNumber: mobileNumber);
    try {
      final dio = _ref.read(dioClientProvider).dio;
      await dio.post(ApiConstants.sendOtp, data: {'mobileNumber': mobileNumber});
    } catch (_) {}
    return true;
  }

  Future<bool> verifyOtp(String mobileNumber, String otp) async {
    try {
      final dio = _ref.read(dioClientProvider).dio;
      final response = await dio.post(ApiConstants.verifyOtp, data: {
        'mobileNumber': mobileNumber,
        'otp': otp,
        'deviceId': 'Android-Device-Mobile',
      });

      if (response.data['success'] == true) {
        final data = response.data['data'];
        final agentState = data['agentState'] ?? 'NEW';

        await _storage.saveTokens(
          accessToken: data['accessToken'],
          refreshToken: data['refreshToken'],
          agentState: agentState,
          userId: data['user']['id'],
          agentId: data['user']['agentId'],
        );

        state = AuthState(
          status: AuthStatus.authenticated,
          agentState: agentState,
          mobileNumber: mobileNumber,
        );
        return true;
      }
    } catch (e) {
      state = state.copyWith(errorMessage: 'Invalid or expired OTP code entered');
    }
    return false;
  }

  void updateAgentState(String newState, {String? rejectionReason}) {
    _storage.updateAgentState(newState);
    state = state.copyWith(agentState: newState, rejectionReason: rejectionReason);
  }

  Future<void> logout() async {
    try {
      final dio = _ref.read(dioClientProvider).dio;
      await dio.post(ApiConstants.logout);
    } catch (_) {}
    await _storage.clearAll();
    state = AuthState(status: AuthStatus.unauthenticated);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return AuthNotifier(storage, ref);
});
