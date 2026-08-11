import 'package:moyasar/moyasar.dart';
import '../core/constants.dart';

/// Builds the Moyasar PaymentConfig shared by all payment widgets
/// (CreditCard covers both mada and credit cards, plus ApplePay on iOS).
abstract class MoyasarService {
  static PaymentConfig buildConfig({
    required double amountSar,
    required String description,
    Map<String, String> metadata = const {},
    // When true the card is tokenized with the payment; the backend then
    // stores the token if the order is placed with save_card = true.
    bool saveCard = false,
  }) {
    final halalas = (amountSar * 100).round();

    return PaymentConfig(
      publishableApiKey: MoyasarConfig.publishableApiKey,
      amount: halalas,
      description: description,
      metadata: metadata,
      creditCard: CreditCardConfig(saveCard: saveCard, manual: false),
      applePay: ApplePayConfig(
        merchantId: MoyasarConfig.applePayMerchantId,
        label: MoyasarConfig.merchantName,
        manual: false,
        saveCard: false,
      ),
    );
  }
}
