import 'package:firebase_auth/firebase_auth.dart';

/// Maps FirebaseAuthException codes to friendly bilingual messages so the
/// UI never shows Firebase's raw English text or an error code.
/// [fallbackEn]/[fallbackAr] are shown for codes we don't recognize —
/// pass a message that fits the action the user was attempting.
String friendlyAuthError(
  FirebaseAuthException e, {
  required bool isAr,
  required String fallbackEn,
  required String fallbackAr,
}) {
  switch (e.code) {
    case 'invalid-phone-number':
    case 'missing-phone-number':
      return isAr
          ? 'رقم الجوال غير صحيح. تحقق من الرقم وحاول مرة أخرى.'
          : 'That phone number doesn\'t look right. Please check it and try again.';
    case 'too-many-requests':
    case 'quota-exceeded':
      return isAr
          ? 'محاولات كثيرة. الرجاء الانتظار قليلاً ثم المحاولة مجدداً.'
          : 'Too many attempts. Please wait a few minutes and try again.';
    case 'invalid-verification-code':
      return isAr
          ? 'الرمز الذي أدخلته غير صحيح. حاول مرة أخرى.'
          : 'The code you entered is incorrect. Please try again.';
    case 'session-expired':
    case 'code-expired':
      return isAr
          ? 'انتهت صلاحية الرمز. اطلب رمزاً جديداً.'
          : 'The code has expired. Please request a new one.';
    case 'network-request-failed':
      return isAr
          ? 'لا يوجد اتصال بالإنترنت. تحقق من الشبكة وحاول مجدداً.'
          : 'No internet connection. Check your network and try again.';
    default:
      return isAr ? fallbackAr : fallbackEn;
  }
}
