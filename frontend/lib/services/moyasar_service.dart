import 'package:moyasar/moyasar.dart';
import '../core/constants.dart';

/// Builds the Moyasar PaymentConfig shared by all payment widgets
/// (CreditCard covers both mada and credit cards, plus ApplePay/SamsungPay).
abstract class MoyasarService {
  static PaymentConfig buildConfig({
    required double amountSar,
    required String description,
    Map<String, String> metadata = const {},
  }) {
    final halalas = (amountSar * 100).round();

    return PaymentConfig(
      publishableApiKey: MoyasarConfig.publishableApiKey,
      amount: halalas,
      description: description,
      metadata: metadata,
      creditCard: CreditCardConfig(saveCard: false, manual: false),
      applePay: ApplePayConfig(
        merchantId: MoyasarConfig.applePayMerchantId,
        label: MoyasarConfig.merchantName,
        manual: false,
        saveCard: false,
      ),
      samsungPay: SamsungPayConfig(
        serviceId: MoyasarConfig.samsungPayServiceId,
        merchantName: MoyasarConfig.merchantName,
        manual: false,
      ),
    );
  }
}
