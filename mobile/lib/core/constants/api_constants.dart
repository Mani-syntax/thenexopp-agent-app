class ApiConstants {
  // Base URLs (Configurable for local dev / staging / KVM2 VPS production)
  static const String baseUrl = 'http://10.0.2.2:3000/api/v1'; // Android emulator localhost alias
  static const String webSocketUrl = 'http://10.0.2.2:3000/ws';

  // Production fallback domain
  static const String prodBaseUrl = 'https://api.thenexopp.com/api/v1';
  static const String prodWebSocketUrl = 'https://api.thenexopp.com/ws';

  // Auth Endpoints
  static const String sendOtp = '/auth/send-otp';
  static const String verifyOtp = '/auth/verify-otp';
  static const String refreshToken = '/auth/refresh';
  static const String logout = '/auth/logout';

  // Agent & Onboarding
  static const String getProfile = '/agent/profile';
  static const String updateProfile = '/agent/profile';
  static const String kycDetails = '/agent/kyc';
  static const String submitKyc = '/agent/kyc';
  static const String bankDetails = '/agent/bank-details';
  static const String submitBankDetails = '/agent/bank-details';

  // Properties
  static const String properties = '/properties';
  static const String createProperty = '/properties';
  static String submitProperty(String id) => '/properties/$id/submit';

  // Financials
  static const String earnings = '/earnings';
  static const String payments = '/payments';

  // Notifications
  static const String notifications = '/notifications';
  static const String markAllRead = '/notifications/read-all';

  // Uploads
  static const String presignedUrl = '/uploads/presigned-url';
  static const String secureViewUrl = '/uploads/secure-view-url';
}
