double parseDouble(dynamic val, [double defaultValue = 0.0]) {
  if (val == null) return defaultValue;
  if (val is num) return val.toDouble();
  if (val is String) {
    return double.tryParse(val) ?? defaultValue;
  }
  return defaultValue;
}

class VirtualAccountModel {
  final String id;
  final String accountNumber;
  final String accountName;
  final String bankName;
  final String bankCode;
  final String providerName;
  final String status;

  VirtualAccountModel({
    required this.id,
    required this.accountNumber,
    required this.accountName,
    required this.bankName,
    required this.bankCode,
    required this.providerName,
    required this.status,
  });

  factory VirtualAccountModel.fromJson(Map<String, dynamic> json) {
    return VirtualAccountModel(
      id: json['id'] ?? '',
      accountNumber: json['account_number'] ?? '',
      accountName: json['account_name'] ?? '',
      bankName: json['bank_name'] ?? '',
      bankCode: json['bank_code'] ?? '',
      providerName: json['provider_name'] ?? 'PROVIDUS',
      status: json['status'] ?? 'ACTIVE',
    );
  }
}

class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String phoneNumber;
  final String referralCode;
  final bool hasBvn;
  final bool hasNin;
  final bool isKycVerified;
  final double walletBalance;
  final double reservedBalance;
  final double spendableBalance;
  final double cashbackBalance;
  final double totalLifetimeSavings;
  final String currency;
  final VirtualAccountModel? virtualAccount;

  UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.phoneNumber,
    required this.referralCode,
    required this.hasBvn,
    required this.hasNin,
    required this.isKycVerified,
    required this.walletBalance,
    required this.reservedBalance,
    required this.spendableBalance,
    required this.cashbackBalance,
    required this.totalLifetimeSavings,
    required this.currency,
    this.virtualAccount,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final wBal = parseDouble(json['wallet_balance']);
    final rBal = parseDouble(json['reserved_balance']);
    final sBal = parseDouble(json['spendable_balance'], wBal - rBal);
    final vAccJson = json['virtual_account'];
    return UserModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      fullName: json['full_name'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      referralCode: json['referral_code'] ?? 'CHEEP-REF',
      hasBvn: json['has_bvn'] ?? false,
      hasNin: json['has_nin'] ?? false,
      isKycVerified: json['is_kyc_verified'] ?? false,
      walletBalance: wBal,
      reservedBalance: rBal,
      spendableBalance: sBal < 0 ? 0 : sBal,
      cashbackBalance: parseDouble(json['cashback_balance']),
      totalLifetimeSavings: parseDouble(json['total_lifetime_savings']),
      currency: json['currency'] ?? 'NGN',
      virtualAccount: vAccJson != null ? VirtualAccountModel.fromJson(vAccJson) : null,
    );
  }
}

class FundingSourceModel {
  final String id;
  final String type;
  final String cardBrand;
  final String last4;
  final String expMonth;
  final String expYear;
  final String bankName;
  final bool isDefault;
  final bool isFallback;

  FundingSourceModel({
    required this.id,
    required this.type,
    required this.cardBrand,
    required this.last4,
    required this.expMonth,
    required this.expYear,
    required this.bankName,
    required this.isDefault,
    required this.isFallback,
  });

  factory FundingSourceModel.fromJson(Map<String, dynamic> json) {
    return FundingSourceModel(
      id: json['id'] ?? '',
      type: json['type'] ?? 'CARD',
      cardBrand: json['card_brand'] ?? 'Visa',
      last4: json['last4'] ?? '4242',
      expMonth: json['exp_month'] ?? '12',
      expYear: json['exp_year'] ?? '2028',
      bankName: json['bank_name'] ?? 'Bank',
      isDefault: json['is_default'] ?? true,
      isFallback: json['is_fallback'] ?? true,
    );
  }
}

class BillCategoryModel {
  final String id;
  final String slug;
  final String name;
  final String icon;
  final String? description;
  final List<BillProductModel> products;

  BillCategoryModel({
    required this.id,
    required this.slug,
    required this.name,
    required this.icon,
    required this.description,
    required this.products,
  });

  factory BillCategoryModel.fromJson(Map<String, dynamic> json) {
    var prodsJson = (json['products'] as List? ?? []);
    return BillCategoryModel(
      id: json['id'] ?? '',
      slug: json['slug'] ?? '',
      name: json['name'] ?? '',
      icon: json['icon'] ?? 'bolt',
      description: json['description'],
      products: prodsJson.map((p) => BillProductModel.fromJson(p)).toList(),
    );
  }
}

class BillProductModel {
  final String id;
  final String categoryId;
  final String code;
  final String name;
  final String providerCode;
  final double minAmount;
  final double maxAmount;
  final double fee;
  final double providerDiscountPct;
  final double customerSharePct;
  final double cashbackPct;

  BillProductModel({
    required this.id,
    required this.categoryId,
    required this.code,
    required this.name,
    required this.providerCode,
    required this.minAmount,
    required this.maxAmount,
    required this.fee,
    required this.providerDiscountPct,
    required this.customerSharePct,
    required this.cashbackPct,
  });

  factory BillProductModel.fromJson(Map<String, dynamic> json) {
    return BillProductModel(
      id: json['id'] ?? '',
      categoryId: json['category_id'] ?? '',
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      providerCode: json['provider_code'] ?? '',
      minAmount: parseDouble(json['min_amount']),
      maxAmount: parseDouble(json['max_amount']),
      fee: parseDouble(json['fee']),
      providerDiscountPct: parseDouble(json['provider_discount_pct'], 3.0),
      customerSharePct: parseDouble(json['customer_share_pct'], 40.0),
      cashbackPct: parseDouble(json['cashback_pct'], 1.0),
    );
  }
}

class CustomerValidationModel {
  final bool isValid;
  final String customerName;
  final String customerReference;
  final double outstandingAmount;

  CustomerValidationModel({
    required this.isValid,
    required this.customerName,
    required this.customerReference,
    required this.outstandingAmount,
  });

  factory CustomerValidationModel.fromJson(Map<String, dynamic> json) {
    return CustomerValidationModel(
      isValid: json['is_valid'] ?? false,
      customerName: json['customer_name'] ?? '',
      customerReference: json['customer_reference'] ?? '',
      outstandingAmount: parseDouble(json['outstanding_amount']),
    );
  }
}

class PriceCalculationModel {
  final double faceValue;
  final double fee;
  final double providerDiscountAmount;
  final double customerDiscountAmount;
  final double cheepperMarginAmount;
  final double cashbackEarnedAmount;
  final double cashbackUsedAmount;
  final double finalCustomerAmount;

  PriceCalculationModel({
    required this.faceValue,
    required this.fee,
    required this.providerDiscountAmount,
    required this.customerDiscountAmount,
    required this.cheepperMarginAmount,
    required this.cashbackEarnedAmount,
    required this.cashbackUsedAmount,
    required this.finalCustomerAmount,
  });

  factory PriceCalculationModel.fromJson(Map<String, dynamic> json) {
    return PriceCalculationModel(
      faceValue: parseDouble(json['face_value']),
      fee: parseDouble(json['fee']),
      providerDiscountAmount: parseDouble(json['provider_discount_amount']),
      customerDiscountAmount: parseDouble(json['customer_discount_amount']),
      cheepperMarginAmount: parseDouble(json['cheepper_margin_amount']),
      cashbackEarnedAmount: parseDouble(json['cashback_earned_amount']),
      cashbackUsedAmount: parseDouble(json['cashback_used_amount']),
      finalCustomerAmount: parseDouble(json['final_customer_amount']),
    );
  }
}

class PaymentModel {
  final String id;
  final String idempotencyKey;
  final String billProductCode;
  final String customerReference;
  final double amount;
  final double fee;
  final double customerDiscountAmount;
  final double cheepperMarginAmount;
  final double cashbackEarnedAmount;
  final double cashbackUsedAmount;
  final double totalAmount;
  final String currency;
  final String paymentMethod;
  final String? fundingSourceId;
  final String status;
  final String? providerTxRef;
  final String? tokenOrPin;
  final String? failureReason;
  final String? receiptNumber;
  final String createdAt;

  PaymentModel({
    required this.id,
    required this.idempotencyKey,
    required this.billProductCode,
    required this.customerReference,
    required this.amount,
    required this.fee,
    required this.customerDiscountAmount,
    required this.cheepperMarginAmount,
    required this.cashbackEarnedAmount,
    required this.cashbackUsedAmount,
    required this.totalAmount,
    required this.currency,
    required this.paymentMethod,
    this.fundingSourceId,
    required this.status,
    this.providerTxRef,
    this.tokenOrPin,
    this.failureReason,
    this.receiptNumber,
    required this.createdAt,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'] ?? '',
      idempotencyKey: json['idempotency_key'] ?? '',
      billProductCode: json['bill_product_code'] ?? '',
      customerReference: json['customer_reference'] ?? '',
      amount: parseDouble(json['amount']),
      fee: parseDouble(json['fee']),
      customerDiscountAmount: parseDouble(json['customer_discount_amount']),
      cheepperMarginAmount: parseDouble(json['cheepper_margin_amount']),
      cashbackEarnedAmount: parseDouble(json['cashback_earned_amount']),
      cashbackUsedAmount: parseDouble(json['cashback_used_amount']),
      totalAmount: parseDouble(json['total_amount']),
      currency: json['currency'] ?? 'NGN',
      paymentMethod: json['payment_method'] ?? 'WALLET',
      fundingSourceId: json['funding_source_id'],
      status: json['status'] ?? 'PENDING',
      providerTxRef: json['provider_tx_ref'],
      tokenOrPin: json['token_or_pin'],
      failureReason: json['failure_reason'],
      receiptNumber: json['receipt_number'],
      createdAt: json['created_at'] ?? '',
    );
  }
}

class LedgerEntryModel {
  final String id;
  final String transactionId;
  final String debitAccountId;
  final String creditAccountId;
  final double amount;
  final String description;
  final String createdAt;

  LedgerEntryModel({
    required this.id,
    required this.transactionId,
    required this.debitAccountId,
    required this.creditAccountId,
    required this.amount,
    required this.description,
    required this.createdAt,
  });

  factory LedgerEntryModel.fromJson(Map<String, dynamic> json) {
    return LedgerEntryModel(
      id: json['id'] ?? '',
      transactionId: json['transaction_id'] ?? '',
      debitAccountId: json['debit_account_id'] ?? '',
      creditAccountId: json['credit_account_id'] ?? '',
      amount: parseDouble(json['amount']),
      description: json['description'] ?? '',
      createdAt: json['created_at'] ?? '',
    );
  }
}

class BeneficiaryModel {
  final String id;
  final String categorySlug;
  final String productCode;
  final String name;
  final String customerReference;
  final String familyMemberRole;

  BeneficiaryModel({
    required this.id,
    required this.categorySlug,
    required this.productCode,
    required this.name,
    required this.customerReference,
    required this.familyMemberRole,
  });

  factory BeneficiaryModel.fromJson(Map<String, dynamic> json) {
    return BeneficiaryModel(
      id: json['id'] ?? '',
      categorySlug: json['category_slug'] ?? '',
      productCode: json['product_code'] ?? '',
      name: json['name'] ?? '',
      customerReference: json['customer_reference'] ?? '',
      familyMemberRole: json['family_member_role'] ?? 'ME',
    );
  }
}

class ScheduleModel {
  final String id;
  final String billProductCode;
  final String customerReference;
  final double amount;
  final String frequency;
  final String nextRunAt;
  final bool isActive;

  ScheduleModel({
    required this.id,
    required this.billProductCode,
    required this.customerReference,
    required this.amount,
    required this.frequency,
    required this.nextRunAt,
    required this.isActive,
  });

  factory ScheduleModel.fromJson(Map<String, dynamic> json) {
    return ScheduleModel(
      id: json['id'] ?? '',
      billProductCode: json['bill_product_code'] ?? '',
      customerReference: json['customer_reference'] ?? '',
      amount: parseDouble(json['amount']),
      frequency: json['frequency'] ?? 'MONTHLY',
      nextRunAt: json['next_run_at'] ?? '',
      isActive: json['is_active'] ?? true,
    );
  }
}

class CategorySpendModel {
  final String categorySlug;
  final String categoryName;
  final double totalSpent;
  final double totalSaved;
  final double totalCashbackEarned;
  final int transactionCount;
  final String icon;

  CategorySpendModel({
    required this.categorySlug,
    required this.categoryName,
    required this.totalSpent,
    required this.totalSaved,
    required this.totalCashbackEarned,
    required this.transactionCount,
    required this.icon,
  });

  factory CategorySpendModel.fromJson(Map<String, dynamic> json) {
    return CategorySpendModel(
      categorySlug: json['category_slug'] ?? '',
      categoryName: json['category_name'] ?? '',
      totalSpent: parseDouble(json['total_spent']),
      totalSaved: parseDouble(json['total_saved']),
      totalCashbackEarned: parseDouble(json['total_cashback_earned']),
      transactionCount: (json['transaction_count'] ?? 0) as int,
      icon: json['icon'] ?? 'receipt',
    );
  }
}

class SpendingAnalyticsModel {
  final double totalBillsPaid;
  final int totalTransactions;
  final double totalLifetimeSavings;
  final double totalCashbackEarned;
  final double totalCashbackUsed;
  final List<CategorySpendModel> byCategory;
  final Map<String, dynamic> byPaymentMethod;

  SpendingAnalyticsModel({
    required this.totalBillsPaid,
    required this.totalTransactions,
    required this.totalLifetimeSavings,
    required this.totalCashbackEarned,
    required this.totalCashbackUsed,
    required this.byCategory,
    required this.byPaymentMethod,
  });

  factory SpendingAnalyticsModel.fromJson(Map<String, dynamic> json) {
    final cats = (json['by_category'] as List? ?? [])
        .map((c) => CategorySpendModel.fromJson(c))
        .toList();
    return SpendingAnalyticsModel(
      totalBillsPaid: parseDouble(json['total_bills_paid']),
      totalTransactions: (json['total_transactions'] ?? 0) as int,
      totalLifetimeSavings: parseDouble(json['total_lifetime_savings']),
      totalCashbackEarned: parseDouble(json['total_cashback_earned']),
      totalCashbackUsed: parseDouble(json['total_cashback_used']),
      byCategory: cats,
      byPaymentMethod: (json['by_payment_method'] ?? {}) as Map<String, dynamic>,
    );
  }
}

class GroupContributionModel {
  final String id;
  final String contributorId;
  final String contributorName;
  final double amount;
  final String createdAt;

  GroupContributionModel({
    required this.id,
    required this.contributorId,
    required this.contributorName,
    required this.amount,
    required this.createdAt,
  });

  factory GroupContributionModel.fromJson(Map<String, dynamic> json) {
    return GroupContributionModel(
      id: json['id'] ?? '',
      contributorId: json['contributor_id'] ?? '',
      contributorName: json['contributor_name'] ?? '',
      amount: parseDouble(json['amount']),
      createdAt: json['created_at'] ?? '',
    );
  }
}

class BillGroupModel {
  final String id;
  final String creatorId;
  final String title;
  final String productCode;
  final String customerReference;
  final double targetAmount;
  final double collectedAmount;
  final String status;
  final List<GroupContributionModel> contributions;
  final String createdAt;

  BillGroupModel({
    required this.id,
    required this.creatorId,
    required this.title,
    required this.productCode,
    required this.customerReference,
    required this.targetAmount,
    required this.collectedAmount,
    required this.status,
    required this.contributions,
    required this.createdAt,
  });

  factory BillGroupModel.fromJson(Map<String, dynamic> json) {
    final contribs = (json['contributions'] as List? ?? [])
        .map((c) => GroupContributionModel.fromJson(c))
        .toList();
    return BillGroupModel(
      id: json['id'] ?? '',
      creatorId: json['creator_id'] ?? '',
      title: json['title'] ?? '',
      productCode: json['product_code'] ?? '',
      customerReference: json['customer_reference'] ?? '',
      targetAmount: parseDouble(json['target_amount']),
      collectedAmount: parseDouble(json['collected_amount']),
      status: json['status'] ?? 'FUNDING',
      contributions: contribs,
      createdAt: json['created_at'] ?? '',
    );
  }
}

class CashbackCampaignModel {
  final String id;
  final String title;
  final String? description;
  final String? categorySlug;
  final double cashbackPct;
  final double minTransactionAmount;
  final double maxCashbackAmount;
  final bool isActive;

  CashbackCampaignModel({
    required this.id,
    required this.title,
    this.description,
    this.categorySlug,
    required this.cashbackPct,
    required this.minTransactionAmount,
    required this.maxCashbackAmount,
    required this.isActive,
  });

  factory CashbackCampaignModel.fromJson(Map<String, dynamic> json) {
    return CashbackCampaignModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      categorySlug: json['category_slug'],
      cashbackPct: parseDouble(json['cashback_pct']),
      minTransactionAmount: parseDouble(json['min_transaction_amount']),
      maxCashbackAmount: parseDouble(json['max_cashback_amount']),
      isActive: json['is_active'] ?? true,
    );
  }
}

class ReferralStatsModel {
  final String referralCode;
  final int totalReferrals;
  final int qualifiedReferrals;
  final double totalRewardsEarned;

  ReferralStatsModel({
    required this.referralCode,
    required this.totalReferrals,
    required this.qualifiedReferrals,
    required this.totalRewardsEarned,
  });

  factory ReferralStatsModel.fromJson(Map<String, dynamic> json) {
    return ReferralStatsModel(
      referralCode: json['referral_code'] ?? '',
      totalReferrals: (json['total_referrals'] ?? 0) as int,
      qualifiedReferrals: (json['qualified_referrals'] ?? 0) as int,
      totalRewardsEarned: parseDouble(json['total_rewards_earned']),
    );
  }
}

class PricingAuditModel {
  final String id;
  final String adminId;
  final String productCode;
  final String fieldChanged;
  final String oldValue;
  final String newValue;
  final String reason;
  final String createdAt;

  PricingAuditModel({
    required this.id,
    required this.adminId,
    required this.productCode,
    required this.fieldChanged,
    required this.oldValue,
    required this.newValue,
    required this.reason,
    required this.createdAt,
  });

  factory PricingAuditModel.fromJson(Map<String, dynamic> json) {
    return PricingAuditModel(
      id: json['id'] ?? '',
      adminId: json['admin_id'] ?? '',
      productCode: json['product_code'] ?? '',
      fieldChanged: json['field_changed'] ?? '',
      oldValue: json['old_value'] ?? '',
      newValue: json['new_value'] ?? '',
      reason: json['reason'] ?? '',
      createdAt: json['created_at'] ?? '',
    );
  }
}




