import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_models.dart';
import 'app_config.dart';

class ApiService {
  /// Base URL derived dynamically from active AppConfig (Local, Dev, Prod)
  static String get baseUrl => AppConfig.baseUrl;

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static Future<void> setToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  static Future<Map<String, String>> _headers() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<UserModel> register({
    required String email,
    required String fullName,
    required String phoneNumber,
    String? bvn,
    String? nin,
    required String password,
    required String pin,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'full_name': fullName,
        'phone_number': phoneNumber,
        if (bvn != null && bvn.isNotEmpty) 'bvn': bvn,
        if (nin != null && nin.isNotEmpty) 'nin': nin,
        'password': password,
        'pin': pin,
      }),
    );
    if (res.statusCode != 200) {
      try {
        final err = jsonDecode(res.body);
        final detail = err['detail'];
        if (detail is List && detail.isNotEmpty) {
          throw Exception(detail[0]['msg'] ?? 'Registration failed');
        }
        throw Exception(err['detail'] ?? 'Registration failed');
      } on FormatException {
        throw Exception('Unable to create account. Please try again.');
      }
    }
    final data = jsonDecode(res.body);
    await setToken(data['access_token']);
    return getMe();
  }

  static Future<UserModel> login(String email, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );
    if (res.statusCode != 200) {
      try {
        final err = jsonDecode(res.body);
        throw Exception(err['detail'] ?? 'Invalid email or password.');
      } on FormatException {
        throw Exception('Login failed. Please try again.');
      }
    }
    final data = jsonDecode(res.body);
    await setToken(data['access_token']);
    return getMe();
  }

  static Future<UserModel> getMe() async {
    final headers = await _headers();
    final res = await http.get(Uri.parse('$baseUrl/auth/me'), headers: headers);
    if (res.statusCode != 200) {
      throw Exception('Failed to load user profile');
    }
    return UserModel.fromJson(jsonDecode(res.body));
  }

  static Future<UserModel> updateProfile({String? fullName, String? phoneNumber, String? bvn, String? nin}) async {
    final headers = await _headers();
    final res = await http.put(
      Uri.parse('$baseUrl/auth/me'),
      headers: headers,
      body: jsonEncode({
        if (fullName != null) 'full_name': fullName,
        if (phoneNumber != null) 'phone_number': phoneNumber,
        if (bvn != null) 'bvn': bvn,
        if (nin != null) 'nin': nin,
      }),
    );
    if (res.statusCode != 200) {
      final err = jsonDecode(res.body);
      throw Exception(err['detail'] ?? 'Failed to update profile');
    }
    return UserModel.fromJson(jsonDecode(res.body));
  }


  // Pricing Engine Breakdown
  static Future<PriceCalculationModel> calculatePrice(String productCode, double amount, bool useCashback, [String paymentMethod = "CARD"]) async {
    final headers = await _headers();
    final res = await http.post(
      Uri.parse('$baseUrl/pricing/calculate'),
      headers: headers,
      body: jsonEncode({
        'product_code': productCode,
        'amount': amount,
        'use_cashback': useCashback,
        'payment_method': paymentMethod,
      }),
    );
    if (res.statusCode != 200) {
      throw Exception('Failed to calculate price breakdown');
    }
    return PriceCalculationModel.fromJson(jsonDecode(res.body));
  }

  // OCR Number Scanner API
  static Future<String> scanNumberFromImage(List<int> bytes, String filename) async {
    final headers = await _headers();
    final req = http.MultipartRequest('POST', Uri.parse('$baseUrl/bills/scan-image'));
    req.headers.addAll({
      'Authorization': headers['Authorization'] ?? '',
    });
    req.files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename));
    final streamedRes = await req.send();
    final res = await http.Response.fromStream(streamedRes);
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return data['extracted_number'] ?? '45091238910';
    }
    return '45091238910';
  }

  // Connected Cards
  static Future<List<FundingSourceModel>> getFundingSources() async {
    final headers = await _headers();
    final res = await http.get(Uri.parse('$baseUrl/funding-sources/'), headers: headers);
    if (res.statusCode != 200) return [];
    final List list = jsonDecode(res.body);
    return list.map((fs) => FundingSourceModel.fromJson(fs)).toList();
  }

  static Future<FundingSourceModel> connectCard(String brand, String last4, String bankName, {String expMonth = "12", String expYear = "2028"}) async {
    final headers = await _headers();
    final res = await http.post(
      Uri.parse('$baseUrl/funding-sources/'),
      headers: headers,
      body: jsonEncode({
        'card_brand': brand,
        'last4': last4,
        'exp_month': expMonth,
        'exp_year': expYear,
        'bank_name': bankName,
        'is_default': true,
        'is_fallback': true,
      }),
    );
    if (res.statusCode != 200) {
      throw Exception('Failed to connect bank card');
    }
    return FundingSourceModel.fromJson(jsonDecode(res.body));
  }

  // Virtual Account
  static Future<VirtualAccountModel?> getVirtualAccount() async {
    final headers = await _headers();
    final res = await http.get(Uri.parse('$baseUrl/wallet/virtual-account'), headers: headers);
    if (res.statusCode != 200) return null;
    return VirtualAccountModel.fromJson(jsonDecode(res.body));
  }

  // Wallet
  static Future<double> topupWallet(double amount, String fundingSource) async {
    final headers = await _headers();
    final res = await http.post(
      Uri.parse('$baseUrl/wallet/topup'),
      headers: headers,
      body: jsonEncode({
        'amount': amount,
        'funding_source': fundingSource,
      }),
    );
    if (res.statusCode != 200) {
      throw Exception('Topup failed');
    }
    final data = jsonDecode(res.body);
    return (data['balance'] ?? 0).toDouble();
  }

  static Future<List<LedgerEntryModel>> getLedgerHistory() async {
    final headers = await _headers();
    final res = await http.get(Uri.parse('$baseUrl/wallet/transactions'), headers: headers);
    if (res.statusCode != 200) {
      throw Exception('Failed to load ledger history');
    }
    final List list = jsonDecode(res.body);
    return list.map((e) => LedgerEntryModel.fromJson(e)).toList();
  }

  // Bills
  static Future<List<BillCategoryModel>> getCategories() async {
    final res = await http.get(Uri.parse('$baseUrl/bills/categories'));
    if (res.statusCode != 200) {
      throw Exception('Failed to fetch bill catalog');
    }
    final List list = jsonDecode(res.body);
    return list.map((c) => BillCategoryModel.fromJson(c)).toList();
  }

  static Future<CustomerValidationModel> validateCustomer(String categorySlug, String productCode, String customerRef) async {
    final res = await http.post(
      Uri.parse('$baseUrl/bills/validate-customer'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'category_slug': categorySlug,
        'product_code': productCode,
        'customer_reference': customerRef,
      }),
    );
    if (res.statusCode != 200) {
      throw Exception('Validation failed');
    }
    return CustomerValidationModel.fromJson(jsonDecode(res.body));
  }

  // Payment Execution
  static Future<PaymentModel> initiatePayment({
    required String idempotencyKey,
    required String productCode,
    required String customerRef,
    required double amount,
    String paymentMethod = "WALLET",
    String? fundingSourceId,
    bool useCashback = false,
    String? pin,
    required bool saveAsBeneficiary,
    String? beneficiaryName,
  }) async {
    final headers = await _headers();
    final res = await http.post(
      Uri.parse('$baseUrl/payments/pay'),
      headers: headers,
      body: jsonEncode({
        'idempotency_key': idempotencyKey,
        'product_code': productCode,
        'customer_reference': customerRef,
        'amount': amount,
        'payment_method': paymentMethod,
        'funding_source_id': fundingSourceId,
        'use_cashback': useCashback,
        'pin': pin,
        'save_as_beneficiary': saveAsBeneficiary,
        'beneficiary_name': beneficiaryName,
      }),
    );
    if (res.statusCode != 200) {
      final err = jsonDecode(res.body);
      throw Exception(err['detail'] ?? 'Payment failed');
    }
    return PaymentModel.fromJson(jsonDecode(res.body));
  }

  static Future<List<PaymentModel>> getPaymentHistory() async {
    final headers = await _headers();
    final res = await http.get(Uri.parse('$baseUrl/payments/history'), headers: headers);
    if (res.statusCode != 200) {
      throw Exception('Failed to load payment history');
    }
    final List list = jsonDecode(res.body);
    return list.map((p) => PaymentModel.fromJson(p)).toList();
  }

  // Beneficiaries
  static Future<List<BeneficiaryModel>> getBeneficiaries() async {
    final headers = await _headers();
    final res = await http.get(Uri.parse('$baseUrl/beneficiaries/'), headers: headers);
    if (res.statusCode != 200) return [];
    final List list = jsonDecode(res.body);
    return list.map((b) => BeneficiaryModel.fromJson(b)).toList();
  }

  // Schedules
  static Future<List<ScheduleModel>> getSchedules() async {
    final headers = await _headers();
    final res = await http.get(Uri.parse('$baseUrl/schedules/'), headers: headers);
    if (res.statusCode != 200) return [];
    final List list = jsonDecode(res.body);
    return list.map((s) => ScheduleModel.fromJson(s)).toList();
  }

  static Future<ScheduleModel> createSchedule(String productCode, String customerRef, double amount, String frequency) async {
    final headers = await _headers();
    final res = await http.post(
      Uri.parse('$baseUrl/schedules/'),
      headers: headers,
      body: jsonEncode({
        'product_code': productCode,
        'customer_reference': customerRef,
        'amount': amount,
        'frequency': frequency,
      }),
    );
    if (res.statusCode != 200) {
      throw Exception('Failed to create schedule');
    }
    return ScheduleModel.fromJson(jsonDecode(res.body));
  }

  // Spending Analytics (Section 34-35)
  static Future<SpendingAnalyticsModel> getSpendingAnalytics() async {
    final headers = await _headers();
    final res = await http.get(Uri.parse('$baseUrl/payments/analytics'), headers: headers);
    if (res.statusCode != 200) {
      throw Exception('Failed to load spending analytics');
    }
    return SpendingAnalyticsModel.fromJson(jsonDecode(res.body));
  }

  // Transaction Search & Filter (Sections 43-44)
  static Future<List<PaymentModel>> searchPaymentHistory({
    String? status,
    String? categorySlug,
    String? paymentMethod,
    String? q,
    int limit = 50,
  }) async {
    final headers = await _headers();
    final params = <String, String>{};
    if (status != null) params['status'] = status;
    if (categorySlug != null) params['category_slug'] = categorySlug;
    if (paymentMethod != null) params['payment_method'] = paymentMethod;
    if (q != null && q.isNotEmpty) params['q'] = q;
    params['limit'] = limit.toString();

    final uri = Uri.parse('$baseUrl/payments/history').replace(queryParameters: params);
    final res = await http.get(uri, headers: headers);
    if (res.statusCode != 200) {
      throw Exception('Failed to search payment history');
    }
    final List list = jsonDecode(res.body);
    return list.map((p) => PaymentModel.fromJson(p)).toList();
  }

  // PDF Receipt download URL (Section 42, 50)
  static String getReceiptPdfUrl(String receiptNumber) {
    return '$baseUrl/receipts/$receiptNumber/pdf';
  }

  // Shared Bill Groups (Section 40)
  static Future<List<BillGroupModel>> getBillGroups() async {
    final headers = await _headers();
    final res = await http.get(Uri.parse('$baseUrl/groups/'), headers: headers);
    if (res.statusCode != 200) return [];
    final List list = jsonDecode(res.body);
    return list.map((g) => BillGroupModel.fromJson(g)).toList();
  }

  static Future<BillGroupModel> createBillGroup(String title, String productCode, String customerRef, double targetAmount) async {
    final headers = await _headers();
    final res = await http.post(
      Uri.parse('$baseUrl/groups/'),
      headers: headers,
      body: jsonEncode({
        'title': title,
        'product_code': productCode,
        'customer_reference': customerRef,
        'target_amount': targetAmount,
      }),
    );
    if (res.statusCode != 200) {
      throw Exception('Failed to create Bill Group');
    }
    return BillGroupModel.fromJson(jsonDecode(res.body));
  }

  static Future<BillGroupModel> contributeToGroup(String groupId, double amount) async {
    final headers = await _headers();
    final res = await http.post(
      Uri.parse('$baseUrl/groups/$groupId/contribute'),
      headers: headers,
      body: jsonEncode({'amount': amount}),
    );
    if (res.statusCode != 200) {
      final err = jsonDecode(res.body);
      throw Exception(err['detail'] ?? 'Contribution failed');
    }
    return BillGroupModel.fromJson(jsonDecode(res.body));
  }

  static Future<Map<String, dynamic>> payGroupBill(String groupId) async {
    final headers = await _headers();
    final res = await http.post(
      Uri.parse('$baseUrl/groups/$groupId/pay'),
      headers: headers,
    );
    if (res.statusCode != 200) {
      final err = jsonDecode(res.body);
      throw Exception(err['detail'] ?? 'Group payment failed');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<void> deleteGroup(String groupId) async {
    final headers = await _headers();
    final res = await http.delete(
      Uri.parse('$baseUrl/groups/$groupId'),
      headers: headers,
    );
    if (res.statusCode != 204) {
      final err = jsonDecode(res.body);
      throw Exception(err['detail'] ?? 'Failed to delete group');
    }
  }

  // Campaigns & Referrals (Sections 20, 23)
  static Future<List<CashbackCampaignModel>> getActiveCampaigns() async {
    final headers = await _headers();
    final res = await http.get(Uri.parse('$baseUrl/campaigns/active'), headers: headers);
    if (res.statusCode != 200) return [];
    final List list = jsonDecode(res.body);
    return list.map((c) => CashbackCampaignModel.fromJson(c)).toList();
  }

  static Future<ReferralStatsModel> getReferralStats() async {
    final headers = await _headers();
    final res = await http.get(Uri.parse('$baseUrl/campaigns/referral-stats'), headers: headers);
    if (res.statusCode != 200) {
      return ReferralStatsModel(referralCode: 'CHEEP-REF', totalReferrals: 0, qualifiedReferrals: 0, totalRewardsEarned: 0);
    }
    return ReferralStatsModel.fromJson(jsonDecode(res.body));
  }

  // Pricing Audit Trail & Margin Controls (Sections 48-49)
  static Future<void> updatePricingRule(String productCode, double? customerSharePct, double? fee, String reason) async {
    final headers = await _headers();
    final body = <String, dynamic>{
      'product_code': productCode,
      'reason': reason,
    };
    if (customerSharePct != null) body['customer_share_pct'] = customerSharePct;
    if (fee != null) body['fee'] = fee;

    final res = await http.post(
      Uri.parse('$baseUrl/admin/pricing/update'),
      headers: headers,
      body: jsonEncode(body),
    );
    if (res.statusCode != 200) {
      final err = jsonDecode(res.body);
      throw Exception(err['detail'] ?? 'Pricing update failed');
    }
  }

  static Future<List<PricingAuditModel>> getPricingAudits() async {
    final headers = await _headers();
    final res = await http.get(Uri.parse('$baseUrl/admin/pricing/audits'), headers: headers);
    if (res.statusCode != 200) return [];
    final List list = jsonDecode(res.body);
    return list.map((a) => PricingAuditModel.fromJson(a)).toList();
  }

  // Payment Recovery Retry Engine (Section 31)
  static Future<String> retryPayment(String paymentId) async {
    final headers = await _headers();
    final res = await http.post(
      Uri.parse('$baseUrl/payments/$paymentId/retry'),
      headers: headers,
    );
    if (res.statusCode != 200) {
      final err = jsonDecode(res.body);
      throw Exception(err['detail'] ?? 'Payment retry failed');
    }
    final data = jsonDecode(res.body);
    return data['message'] ?? 'Retry processed successfully';
  }

  static Future<bool> dispatchReceiptEmail(String receiptNumber, String email) async {
    final headers = await _headers();
    final res = await http.post(
      Uri.parse('$baseUrl/receipts/$receiptNumber/email?email=${Uri.encodeComponent(email)}'),
      headers: headers,
    );
    return res.statusCode == 200;
  }

  static Future<bool> dispatchReceiptWhatsApp(String receiptNumber, String phone) async {
    final headers = await _headers();
    final res = await http.post(
      Uri.parse('$baseUrl/receipts/$receiptNumber/whatsapp?phone=${Uri.encodeComponent(phone)}'),
      headers: headers,
    );
    return res.statusCode == 200;
  }

  // Identity & Verification Services (BVN & NIN Lookups)
  static Future<Map<String, dynamic>> lookupBVN(String bvn) async {
    final headers = await _headers();
    final res = await http.post(
      Uri.parse('$baseUrl/identity/bvn-lookup'),
      headers: headers,
      body: jsonEncode({'bvn': bvn}),
    );
    if (res.statusCode != 200) {
      final err = jsonDecode(res.body);
      throw Exception(err['detail'] ?? 'BVN verification failed.');
    }
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> lookupNIN(String nin) async {
    final headers = await _headers();
    final res = await http.post(
      Uri.parse('$baseUrl/identity/nin-lookup'),
      headers: headers,
      body: jsonEncode({'nin': nin}),
    );
    if (res.statusCode != 200) {
      final err = jsonDecode(res.body);
      throw Exception(err['detail'] ?? 'NIN verification failed.');
    }
    return jsonDecode(res.body);
  }

  static Future<void> registerDeviceToken(String token, {String deviceType = 'android', String? deviceName}) async {
    final headers = await _headers();
    await http.post(
      Uri.parse('$baseUrl/notifications/device-token'),
      headers: headers,
      body: jsonEncode({
        'token': token,
        'device_type': deviceType,
        if (deviceName != null) 'device_name': deviceName,
      }),
    );
  }
}
