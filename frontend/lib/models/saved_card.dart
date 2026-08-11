/// A card the customer saved for future payments. Only display data — the
/// Moyasar token that can actually charge the card never leaves the backend.
class SavedCard {
  final String id;
  final String brand; // "visa" / "mada" / "master" / ...
  final String last4;
  final int? expiryMonth;
  final int? expiryYear;

  const SavedCard({
    required this.id,
    required this.brand,
    required this.last4,
    this.expiryMonth,
    this.expiryYear,
  });

  factory SavedCard.fromJson(Map<String, dynamic> json) => SavedCard(
        id: json['id'] as String,
        brand: json['brand'] as String? ?? '',
        last4: json['last4'] as String? ?? '',
        expiryMonth: (json['expiry_month'] as num?)?.toInt(),
        expiryYear: (json['expiry_year'] as num?)?.toInt(),
      );

  /// "Visa •••• 1115"
  String get displayName {
    final brandLabel = switch (brand) {
      'visa' => 'Visa',
      'master' || 'mastercard' => 'Mastercard',
      'mada' => 'mada',
      'amex' => 'Amex',
      _ => brand.isEmpty ? 'Card' : brand,
    };
    return '$brandLabel •••• $last4';
  }

  /// "05/27" — empty when Moyasar didn't return the expiry.
  String get expiryLabel {
    if (expiryMonth == null || expiryYear == null) return '';
    final mm = expiryMonth.toString().padLeft(2, '0');
    final yy = (expiryYear! % 100).toString().padLeft(2, '0');
    return '$mm/$yy';
  }
}

/// Result of charging a saved card. When the issuer demands a 3DS
/// challenge, [transactionUrl] is set and the payment stays 'initiated'
/// until the customer completes it in a webview.
class TokenChargeResult {
  final String paymentId;
  final String status; // "paid" | "initiated"
  final String? transactionUrl;

  const TokenChargeResult({
    required this.paymentId,
    required this.status,
    this.transactionUrl,
  });

  bool get isPaid => status == 'paid';
  bool get needs3ds => status == 'initiated' && transactionUrl != null;

  factory TokenChargeResult.fromJson(Map<String, dynamic> json) =>
      TokenChargeResult(
        paymentId: json['payment_id'] as String,
        status: json['status'] as String? ?? '',
        transactionUrl: json['transaction_url'] as String?,
      );
}
