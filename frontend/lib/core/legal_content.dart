/// Static legal content for Hamsa To Go. Kept as plain strings (not fetched
/// from a backend) so the policies are always available even if the API is
/// down — Moyasar and app-store reviewers check these are reachable in-app.
abstract class LegalContent {
  static const String termsAr = '''
باستخدامك لتطبيق "حمصة لتحميص القهوة" (Hamsa To Go)، فإنك توافق على الشروط والأحكام التالية:

1. طبيعة الخدمة
يتيح التطبيق للعملاء تصفح قائمة المنتجات وتقديم طلبات الشراء لاستلامها من مقهى حمصة لتحميص القهوة شخصياً. لا يقدم التطبيق حالياً خدمة التوصيل.

2. إنشاء الحساب
يتطلب استخدام التطبيق التسجيل برقم جوال والتحقق منه عبر رمز يُرسل بالرسائل النصية (OTP). أنت مسؤول عن سرية بيانات حسابك.

3. الطلبات والأسعار
جميع الأسعار المعروضة بالريال السعودي وتشمل ضريبة القيمة المضافة حيث ينطبق ذلك. يحتفظ المقهى بالحق في تعديل الأسعار أو توفر المنتجات في أي وقت دون إشعار مسبق.

4. الدفع الإلكتروني
جميع الطلبات تُدفع إلكترونياً عبر وسائل الدفع المتاحة في التطبيق (مدى، بطاقات الائتمان، Apple Pay). لا يوجد خيار للدفع النقدي عند الاستلام.

5. قبول الطلبات
يحتفظ المقهى بالحق في رفض أو إلغاء أي طلب لأسباب تشمل، على سبيل المثال لا الحصر، نفاد المنتج أو ازدحام غير متوقع، مع إعادة المبلغ المدفوع بالكامل في هذه الحالة.

6. سلوك المستخدم
يُمنع استخدام التطبيق لأي غرض غير قانوني أو محاولة الوصول غير المصرح به إلى أنظمة التطبيق.

7. الملكية الفكرية
جميع العلامات التجارية والشعارات والمحتوى الخاص بـ"حمصة لتحميص القهوة" مملوكة للمقهى ولا يجوز استخدامها دون إذن كتابي.

8. حدود المسؤولية
لا يتحمل المقهى مسؤولية أي أضرار غير مباشرة ناتجة عن استخدام التطبيق، ضمن الحدود التي يسمح بها النظام السعودي.

9. التعديلات
يجوز تحديث هذه الشروط من وقت لآخر، وسيتم إعلام المستخدمين بأي تغييرات جوهرية عبر التطبيق.

10. القانون الحاكم
تخضع هذه الشروط لأنظمة المملكة العربية السعودية.

للاستفسارات، يُرجى التواصل معنا عبر معلومات التواصل المتوفرة في التطبيق.
''';

  static const String termsEn = '''
By using the Hamsa To Go app, you agree to the following terms and conditions:

1. Nature of the Service
The app allows customers to browse the menu and place orders for pickup in person at Hamsa Coffee Roasters. Delivery is not currently offered.

2. Account Creation
Using the app requires registering with a phone number verified via SMS OTP. You are responsible for keeping your account credentials secure.

3. Orders & Pricing
All prices are listed in Saudi Riyals (SAR) and include VAT where applicable. The cafe reserves the right to change prices or product availability at any time without prior notice.

4. Online Payment
All orders are paid electronically through the payment methods available in the app (mada, credit cards, Apple Pay). Cash on pickup is not available.

5. Order Acceptance
The cafe reserves the right to decline or cancel any order, including but not limited to cases of stock shortage or unexpected high demand, with a full refund issued in such cases.

6. User Conduct
Using the app for any unlawful purpose, or attempting unauthorized access to its systems, is prohibited.

7. Intellectual Property
All trademarks, logos, and content belonging to Hamsa Coffee Roasters are owned by the cafe and may not be used without written permission.

8. Limitation of Liability
The cafe is not liable for indirect damages arising from use of the app, to the extent permitted under Saudi law.

9. Changes to These Terms
These terms may be updated from time to time. Users will be notified of material changes through the app.

10. Governing Law
These terms are governed by the laws of the Kingdom of Saudi Arabia.

For questions, please contact us using the contact details provided in the app.
''';

  static const String privacyAr = '''
تصف سياسة الخصوصية هذه كيفية جمع تطبيق "حمصة لتحميص القهوة" لبياناتك واستخدامها وحمايتها.

1. البيانات التي نجمعها
- الاسم الكامل ورقم الجوال عند إنشاء الحساب.
- تفاصيل الطلبات (المنتجات، الكميات، السعر الإجمالي، طريقة الدفع).
- رمز الإشعارات (FCM Token) لإرسال تنبيهات حالة الطلب.
- بيانات الدفع تُعالج مباشرة عبر بوابة الدفع "ميسر" ولا يتم تخزين أرقام البطاقات لدينا.

2. كيفية استخدام البيانات
نستخدم بياناتك لمعالجة الطلبات، إرسال إشعارات حالة الطلب، وتحسين خدماتنا من خلال تحليلات داخلية.

3. تخزين البيانات
تُخزَّن بياناتك على خدمات Firebase (Google Cloud) وقاعدة بيانات Supabase لأغراض التحليل الداخلي، وفق معايير أمان معتمدة.

4. مشاركة البيانات
لا نبيع أو نشارك بياناتك الشخصية مع أطراف ثالثة لأغراض تسويقية. تُشارك بيانات الدفع مباشرة مع بوابة الدفع "ميسر" لإتمام العملية فقط.

5. حقوقك
يمكنك حذف حسابك وبياناتك بشكل نهائي في أي وقت من خلال خيار "حذف الحساب" داخل التطبيق.

6. أمان البيانات
نتبع ممارسات أمان معقولة لحماية بياناتك من الوصول غير المصرح به.

7. خصوصية الأطفال
التطبيق غير موجه للأطفال دون سن 13 عاماً، ولا نجمع بيانات عنهم عن علم.

8. التعديلات على هذه السياسة
قد يتم تحديث سياسة الخصوصية من وقت لآخر، وسيتم إشعار المستخدمين بأي تغييرات جوهرية.

للاستفسارات المتعلقة بالخصوصية، يُرجى التواصل معنا عبر معلومات التواصل المتوفرة في التطبيق.
''';

  static const String privacyEn = '''
This Privacy Policy describes how the Hamsa To Go app collects, uses, and protects your data.

1. Data We Collect
- Full name and phone number when creating an account.
- Order details (items, quantities, total price, payment method).
- A notification token (FCM token) used to send order status alerts.
- Payment data is processed directly by the Moyasar payment gateway; we do not store card numbers.

2. How We Use Your Data
Your data is used to process orders, send order status notifications, and improve our services through internal analytics.

3. Data Storage
Your data is stored on Firebase (Google Cloud) and a Supabase database for internal analytics purposes, following accepted security standards.

4. Data Sharing
We do not sell or share your personal data with third parties for marketing purposes. Payment data is shared directly with the Moyasar payment gateway solely to complete the transaction.

5. Your Rights
You may permanently delete your account and data at any time using the "Delete Account" option in the app.

6. Data Security
We follow reasonable security practices to protect your data from unauthorized access.

7. Children's Privacy
This app is not directed at children under 13, and we do not knowingly collect data from them.

8. Changes to This Policy
This Privacy Policy may be updated from time to time. Users will be notified of material changes.

For privacy-related questions, please contact us using the contact details provided in the app.
''';

  static const String refundAr = '''
سياسة الاسترجاع والاستبدال الخاصة بتطبيق "حمصة لتحميص القهوة":

1. طبيعة الطلبات
تُحضَّر المشروبات والمنتجات طازجة عند تأكيد الطلب، لذا فإن سياسة الاسترجاع محدودة بطبيعة المنتج.

2. إلغاء الطلب
يمكن إلغاء الطلب واسترجاع كامل المبلغ فقط إذا كان لا يزال بحالة "تم الاستلام" ولم يبدأ تحضيره بعد. بمجرد انتقال الطلب إلى حالة "جاري التحضير"، لا يمكن الإلغاء.

3. الأخطاء في الطلب
إذا تم استلام طلب مختلف عن الذي تم طلبه، أو كان به عيب واضح في الجودة، يُرجى التواصل مع فريق المقهى فوراً عند الاستلام لاستبداله أو استرجاع المبلغ.

4. نفاد المنتج
في حال عدم توفر أحد المنتجات بعد تأكيد الطلب، سيتم التواصل معك واسترجاع قيمة ذلك المنتج فقط.

5. طريقة الاسترجاع
تتم جميع عمليات الاسترجاع عبر نفس وسيلة الدفع المستخدمة في الطلب الأصلي من خلال بوابة الدفع "ميسر"، وقد تستغرق من 3 إلى 5 أيام عمل لتظهر في حسابك حسب سياسة البنك المُصدر للبطاقة.

6. عدم قابلية الاسترجاع
لا يمكن استرجاع قيمة الطلبات بعد أن تصبح بحالة "جاهز للاستلام" أو "تم الاستلام"، إلا في حال وجود عيب واضح في المنتج.

للمطالبة باسترجاع أو استبدال، يُرجى التواصل معنا عبر معلومات التواصل المتوفرة في التطبيق في أقرب وقت ممكن.
''';

  static const String refundEn = '''
Refund & Exchange Policy for the Hamsa To Go app:

1. Nature of Orders
Drinks and food items are freshly prepared upon order confirmation, so the refund policy is limited accordingly.

2. Order Cancellation
An order can be cancelled with a full refund only while it is still in "Received" status and preparation has not started. Once an order moves to "In Progress," it cannot be cancelled.

3. Order Errors
If you receive an order different from what you ordered, or with a clear quality defect, please contact the cafe staff immediately upon pickup for a replacement or refund.

4. Item Unavailability
If an item becomes unavailable after your order is confirmed, we will contact you and refund the value of that item only.

5. Refund Method
All refunds are issued to the original payment method used, processed through the Moyasar payment gateway, and may take 3–5 business days to appear depending on your card issuer's policy.

6. Non-Refundable Cases
Orders cannot be refunded once they reach "Ready for Pickup" or "Picked Up" status, except in the case of a clear product defect.

To request a refund or exchange, please contact us using the contact details provided in the app as soon as possible.
''';
}
