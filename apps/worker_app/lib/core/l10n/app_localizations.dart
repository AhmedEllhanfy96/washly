import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;
  const AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations)!;

  bool get _ar => locale.languageCode == 'ar';

  static const delegate = _AppLocalizationsDelegate();

  // App
  String get appTitle => _ar ? 'عامل واشلي' : 'Washly Worker';

  // Auth
  String get signInToSeeJobs =>
      _ar ? 'سجّل دخولك لرؤية مهامك' : 'Sign in to see your jobs';
  String get email => _ar ? 'البريد الإلكتروني' : 'Email';
  String get password => _ar ? 'كلمة المرور' : 'Password';
  String get invalidEmail => _ar ? 'بريد إلكتروني غير صحيح' : 'Invalid email';
  String get tooShort => _ar ? 'قصيرة جداً' : 'Too short';
  String get signIn => _ar ? 'تسجيل الدخول' : 'Sign In';

  // Navigation
  String get wallet => _ar ? 'المحفظة' : 'Wallet';

  // Jobs screen
  String get myJobs => _ar ? 'مهامي' : 'My Jobs';
  String get noPendingJobs => _ar ? 'لا توجد مهام معلقة' : 'No pending jobs';
  String get checkBackSoon => _ar ? 'تفقّد لاحقاً' : 'Check back soon';
  String get todayJobs => _ar ? 'اليوم' : 'Today';
  String get upcoming => _ar ? 'القادمة' : 'Upcoming';
  String todayCount(int n) =>
      _ar ? 'اليوم — $n ${n == 1 ? 'مهمة' : 'مهام'}' : "Today — $n job${n == 1 ? '' : 's'}";

  // Job detail
  String get navigate => _ar ? 'انتقل' : 'Navigate';
  String get copy => _ar ? 'نسخ' : 'Copy';
  String get customer => _ar ? 'العميل' : 'Customer';
  String get name => _ar ? 'الاسم' : 'Name';
  String get phone => _ar ? 'الهاتف' : 'Phone';
  String get car => _ar ? 'السيارة' : 'Car';
  String get vehicle => _ar ? 'المركبة' : 'Vehicle';
  String get plate => _ar ? 'اللوحة' : 'Plate';
  String get color => _ar ? 'اللون' : 'Color';
  String get job => _ar ? 'المهمة' : 'Job';
  String get service => _ar ? 'الخدمة' : 'Service';
  String get date => _ar ? 'التاريخ' : 'Date';
  String get slot => _ar ? 'الموعد' : 'Slot';
  String get startWash => _ar ? 'ابدأ الغسيل' : 'Start Wash';
  String get markAsDone => _ar ? 'تحديد كمنتهٍ' : 'Mark as Done';
  String get waitingForAdmin =>
      _ar ? 'في انتظار موافقة المدير' : 'Waiting for admin confirmation';
  String get jobCompleted => _ar ? 'تمت المهمة!' : 'Job completed!';
  String get addressCopied => _ar ? 'تم نسخ العنوان' : 'Address copied';
  String get couldNotOpenMaps =>
      _ar ? 'تعذر فتح خرائط جوجل' : 'Could not open Google Maps';
  String get callCustomer => _ar ? 'اتصال' : 'Call';
  String get whatsappCustomer => _ar ? 'واتساب' : 'WhatsApp';
  String statusUpdated(String status) =>
      _ar ? 'تم تحديث الحالة إلى $status' : 'Status updated to $status';

  String serviceNameFor(String serviceType) => switch (serviceType) {
    'fullService'  || 'full_service'  => _ar ? 'خارجي + داخلي كامل' : 'Full Interior + Exterior',
    'interiorOnly' || 'interior_only' => _ar ? 'داخلي فقط' : 'Interior Only',
    'exteriorOnly' || 'exterior_only' => _ar ? 'خارجي فقط' : 'Exterior Only',
    _ => serviceType.replaceAll('_', ' '),
  };

  // Status labels
  String jobStatusLabel(String s) => switch (s) {
        'pending' => _ar ? 'قيد الانتظار' : 'Pending',
        'confirmed' => _ar ? 'مؤكد' : 'Confirmed',
        'inProgress' => _ar ? 'جارٍ التنفيذ' : 'In Progress',
        'completed' => _ar ? 'مكتمل' : 'Completed',
        'cancelled' => _ar ? 'ملغى' : 'Cancelled',
        _ => s,
      };
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['en', 'ar'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

extension BuildContextL10n on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
