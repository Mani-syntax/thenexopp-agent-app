import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const String _keyAccessToken = 'tnx_access_token';
  static const String _keyRefreshToken = 'tnx_refresh_token';
  static const String _keyAgentState = 'tnx_agent_state';
  static const String _keyUserId = 'tnx_user_id';
  static const String _keyAgentId = 'tnx_agent_id';

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required String agentState,
    required String userId,
    String? agentId,
  }) async {
    await _storage.write(key: _keyAccessToken, value: accessToken);
    await _storage.write(key: _keyRefreshToken, value: refreshToken);
    await _storage.write(key: _keyAgentState, value: agentState);
    await _storage.write(key: _keyUserId, value: userId);
    if (agentId != null) {
      await _storage.write(key: _keyAgentId, value: agentId);
    }
  }

  Future<String?> getAccessToken() async => await _storage.read(key: _keyAccessToken);
  Future<String?> getRefreshToken() async => await _storage.read(key: _keyRefreshToken);
  Future<String?> getAgentState() async => await _storage.read(key: _keyAgentState);
  Future<String?> getUserId() async => await _storage.read(key: _keyUserId);
  Future<String?> getAgentId() async => await _storage.read(key: _keyAgentId);

  Future<void> updateAgentState(String newState) async {
    await _storage.write(key: _keyAgentState, value: newState);
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
