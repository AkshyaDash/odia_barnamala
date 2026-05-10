import 'dart:async';
import 'dart:io';

import 'package:purchases_flutter/purchases_flutter.dart';

import '../config/app_config.dart';

/// Result emitted on the [purchaseStream] after a purchase attempt.
class LangPurchaseResult {
  final String langCode;
  final bool success;
  final String? errorMessage;

  const LangPurchaseResult({
    required this.langCode,
    required this.success,
    this.errorMessage,
  });
}

/// Manages language unlocking via RevenueCat (Android + iOS).
///
/// Call [initialize] once from main() before runApp.
/// Use [isUnlocked] synchronously everywhere to gate content.
class LanguagePurchaseService {
  LanguagePurchaseService._();
  static final LanguagePurchaseService instance = LanguagePurchaseService._();

  /// Languages that are always free, no purchase required.
  static const Set<String> freeCodes = {'en', 'or'};

  /// RevenueCat entitlement ID for each paid language.
  static const Map<String, String> _entitlementIds = {
    'hi': 'lang_hi',
    'ta': 'lang_ta',
    'te': 'lang_te',
    'kn': 'lang_kn',
    'ml': 'lang_ml',
    'bn': 'lang_bn',
    'gu': 'lang_gu',
    'pa': 'lang_pa',
    'mr': 'lang_mr',
    'ur': 'lang_ur',
    'as': 'lang_as',
  };

  static const Map<String, String> _offeringIds = {
    'hi': 'lang_hi',
    'ta': 'lang_ta',
    'te': 'lang_te',
    'kn': 'lang_kn',
    'ml': 'lang_ml',
    'bn': 'lang_bn',
    'gu': 'lang_gu',
    'pa': 'lang_pa',
    'mr': 'lang_mr',
    'ur': 'lang_ur',
    'as': 'lang_as',
  };

  // TODO: Replace with real RevenueCat API keys from the dashboard.
  static const _androidApiKey = AppConfig.androidApiKey;
  static const _iosApiKey = AppConfig.iosApiKey;

  final _resultController = StreamController<LangPurchaseResult>.broadcast();

  /// Fires when a purchase or restore completes or fails.
  Stream<LangPurchaseResult> get purchaseStream => _resultController.stream;

  Set<String> _purchasedCodes = {};

  /// Cached snapshot of all currently active purchased codes.
  Set<String> get purchasedCodes => Set.unmodifiable(_purchasedCodes);

  /// Must be called once from main() before runApp.
  /// In development mode, skips RevenueCat initialization and mocks purchases.
  Future<void> initialize() async {
    if (AppConfig.useMockPurchases) {
      _purchasedCodes = {}; // start empty so cart UI is testable; purchaseLanguage mocks instantly
      return;
    }

    // Production mode: configure RevenueCat
    await Purchases.configure(PurchasesConfiguration(
      Platform.isAndroid ? _androidApiKey : _iosApiKey,
    ));
    await _refreshPurchasedCodes();
  }

  /// Initiates a RevenueCat purchase for [langCode].
  /// In development mode, immediately marks the language as purchased.
  /// In production mode, goes through the real RevenueCat flow.
  Future<void> purchaseLanguage(String langCode) async {
    if (isUnlocked(langCode)) return;

    if (AppConfig.useMockPurchases) {
      // Development mode: instantly "purchase" the language
      _purchasedCodes.add(langCode);
      _resultController.add(LangPurchaseResult(langCode: langCode, success: true));
      return;
    }

    // Production mode: real RevenueCat purchase flow
    final offeringId = _offeringIds[langCode];
    if (offeringId == null) return;

    try {
      final offerings = await Purchases.getOfferings();
      final offering = offerings.getOffering(offeringId);
      if (offering == null || offering.availablePackages.isEmpty) {
        _resultController.add(LangPurchaseResult(
          langCode: langCode,
          success: false,
          errorMessage: 'Product not found in store.',
        ));
        return;
      }

      final sdkResult = await Purchases.purchase(
        PurchaseParams.package(offering.availablePackages.first),
      );
      final entitlement = _entitlementIds[langCode]!;
      final unlocked = sdkResult.customerInfo.entitlements.active.containsKey(entitlement);
      if (unlocked) {
        _purchasedCodes.add(langCode);
        _resultController.add(LangPurchaseResult(langCode: langCode, success: true));
      } else {
        _resultController.add(LangPurchaseResult(
          langCode: langCode,
          success: false,
          errorMessage: 'Purchase completed but entitlement not active.',
        ));
      }
    } on PurchasesErrorCode catch (e) {
      if (e == PurchasesErrorCode.purchaseCancelledError) return;
      _resultController.add(LangPurchaseResult(
        langCode: langCode,
        success: false,
        errorMessage: e.toString(),
      ));
    } catch (e) {
      _resultController.add(LangPurchaseResult(
        langCode: langCode,
        success: false,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Restores prior purchases from the store.
  Future<void> restorePurchases() async {
    try {
      await Purchases.restorePurchases();
      await _refreshPurchasedCodes();
    } catch (_) {}
  }

  /// Returns true if [langCode] is free or has an active RevenueCat entitlement.
  bool isUnlocked(String langCode) =>
      freeCodes.contains(langCode) || _purchasedCodes.contains(langCode);

  Future<void> _refreshPurchasedCodes() async {
    try {
      final info = await Purchases.getCustomerInfo();
      _purchasedCodes = _entitlementIds.entries
          .where((e) => info.entitlements.active.containsKey(e.value))
          .map((e) => e.key)
          .toSet();
    } catch (_) {}
  }

  void dispose() {
    _resultController.close();
  }
}
