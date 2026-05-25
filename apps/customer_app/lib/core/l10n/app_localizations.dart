import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../models/booking.dart';

class AppLocalizations {
  final Locale locale;
  const AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations)!;

  bool get _ar => locale.languageCode == 'ar';

  static const delegate = _AppLocalizationsDelegate();

  // App
  String get appTitle => _ar ? 'واشلي' : 'Washly';

  // Auth
  String get welcomeBack => _ar ? 'مرحباً بعودتك' : 'Welcome back';
  String get signInToBook =>
      _ar ? 'سجّل دخولك لحجز غسيل سيارتك' : 'Sign in to book your car wash';
  String get email => _ar ? 'البريد الإلكتروني' : 'Email';
  String get enterValidEmail =>
      _ar ? 'أدخل بريداً إلكترونياً صحيحاً' : 'Enter a valid email';
  String get password => _ar ? 'كلمة المرور' : 'Password';
  String get passwordMinLength => _ar
      ? 'يجب أن تكون كلمة المرور 6 أحرف على الأقل'
      : 'Password must be at least 6 characters';
  String get signIn => _ar ? 'تسجيل الدخول' : 'Sign In';
  String get noAccountSignUp =>
      _ar ? 'ليس لديك حساب؟ سجّل الآن' : "Don't have an account? Sign up";
  String get createAccount => _ar ? 'إنشاء حساب' : 'Create Account';
  String get fullName => _ar ? 'الاسم الكامل' : 'Full Name';
  String get enterYourName => _ar ? 'أدخل اسمك' : 'Enter your name';
  String get phoneOptional => _ar ? 'رقم الهاتف (اختياري)' : 'Phone (optional)';
  String get atLeast6Chars => _ar ? '6 أحرف على الأقل' : 'At least 6 characters';
  String get alreadyHaveAccount =>
      _ar ? 'لديك حساب بالفعل؟ سجّل الدخول' : 'Already have an account? Sign in';
  String get forgotPassword => _ar ? 'نسيت كلمة المرور؟' : 'Forgot password?';
  String get resetLinkSentHint =>
      _ar ? 'أدخل بريدك الإلكتروني وسنرسل لك رابط إعادة التعيين.'
          : 'Enter your email and we\'ll send you a reset link.';
  String get resetPassword => _ar ? 'إعادة تعيين كلمة المرور' : 'Reset Password';
  String get sendResetLink => _ar ? 'إرسال رابط الاستعادة' : 'Send Reset Link';
  String get resetLinkSent =>
      _ar ? 'تم الإرسال! تحقق من بريدك الإلكتروني.' : 'Sent! Check your email.';
  String get newPassword => _ar ? 'كلمة المرور الجديدة' : 'New Password';
  String get confirmNewPassword => _ar ? 'تأكيد كلمة المرور' : 'Confirm Password';
  String get passwordResetSuccess =>
      _ar ? 'تم تغيير كلمة المرور. يمكنك تسجيل الدخول الآن.' : 'Password changed. You can sign in now.';
  String get invalidResetLink =>
      _ar ? 'الرابط غير صالح أو منتهي الصلاحية.' : 'Link is invalid or expired.';
  String get required => _ar ? 'مطلوب' : 'Required';
  String get profile => _ar ? 'الملف الشخصي' : 'Profile';
  String get editProfile => _ar ? 'تعديل الملف الشخصي' : 'Edit Profile';
  String get personalInfo => _ar ? 'المعلومات الشخصية' : 'Personal Information';
  String get phoneNumber => _ar ? 'رقم الهاتف' : 'Phone Number';
  String get phoneTooShort => _ar ? 'رقم الهاتف يجب أن يكون 11 رقماً على الأقل' : 'Phone must be at least 11 digits';
  String get changePassword => _ar ? 'تغيير كلمة المرور' : 'Change Password';
  String get currentPassword => _ar ? 'كلمة المرور الحالية' : 'Current Password';
  String get passwordsDoNotMatch => _ar ? 'كلمتا المرور غير متطابقتين' : 'Passwords do not match';
  String get profileUpdated => _ar ? 'تم تحديث الملف الشخصي بنجاح' : 'Profile updated successfully';
  String get saveChanges => _ar ? 'حفظ التغييرات' : 'Save Changes';

  // Home
  String helloName(String name) => _ar ? 'مرحباً، $name 👋' : 'Hello, $name 👋';
  String get helloThere => _ar ? 'مرحباً! 👋' : 'Hello!';
  String get bookCarWashDoorstep =>
      _ar ? 'احجز غسيل سيارتك على بابك' : 'Book a car wash at your doorstep';
  String get bookAWash => _ar ? 'احجز غسيل' : 'Book a Wash';
  String get exteriorOnlyShort => _ar ? 'خارجي\nفقط' : 'Exterior\nOnly';
  String get quickAndClean => _ar ? 'سريع ونظيف' : 'Quick & clean';
  String get fullServiceShort => _ar ? 'خدمة\nكاملة' : 'Full\nService';
  String get insideOutside => _ar ? 'داخلي + خارجي' : 'Inside + Outside';
  String get interiorOnlyShort => _ar ? 'داخلي\nفقط' : 'Interior\nOnly';
  String get deepClean => _ar ? 'تنظيف عميق' : 'Deep clean';
  String get ourServices => _ar ? 'خدماتنا' : 'Our Services';
  String get whyWashly => _ar ? 'لماذا واشلي؟' : 'Why Washly?';
  String get featureProfessional => _ar ? 'احترافية\nمضمونة' : 'Professional\nGuaranteed';
  String get featureFast => _ar ? 'سريع\nوفعّال' : 'Fast &\nEfficient';
  String get featureEco => _ar ? 'صديق\nللبيئة' : 'Eco-\nFriendly';
  String get recentBookings => _ar ? 'الحجوزات الأخيرة' : 'Recent Bookings';
  String get noBookingsYet => _ar ? 'لا توجد حجوزات بعد' : 'No bookings yet';
  String get viewAllBookings => _ar ? 'عرض كل الحجوزات' : 'View all bookings';

  // Booking flow step names
  String get stepCarDetails => _ar ? 'تفاصيل السيارة' : 'Car Details';
  String get stepServiceType => _ar ? 'نوع الخدمة' : 'Service Type';
  String get stepLocation => _ar ? 'الموقع' : 'Location';
  String get stepTimeSlot => _ar ? 'الموعد' : 'Time Slot';
  String get stepConfirm => _ar ? 'تأكيد' : 'Confirm';
  String get continueBtn => _ar ? 'متابعة' : 'Continue';

  // Car details step
  String get tellUsAboutCar => _ar ? 'أخبرنا عن سيارتك' : 'Tell us about your car';
  String get carDetailsSubtitle => _ar
      ? 'نحتاج هذه التفاصيل لتقديم الرعاية المناسبة لسيارتك.'
      : 'We need these details to give your car the right treatment.';
  String get yourSavedCars => _ar ? 'سياراتك المحفوظة' : 'Your saved cars';
  String get make => _ar ? 'الماركة' : 'Make (Brand)';
  String get model => _ar ? 'الموديل' : 'Model';
  String get yearOptional => _ar ? 'السنة (اختياري)' : 'Year (optional)';
  String get plateNumber => _ar ? 'رقم اللوحة' : 'Plate Number';
  String get carColor => _ar ? 'لون السيارة' : 'Car Color';
  String get otherColor => _ar ? 'لون آخر' : 'Other color';
  String get selectOrEnterColor =>
      _ar ? 'اختر أو أدخل اللون' : 'Select or enter a color';
  String get saveCarForNextTime =>
      _ar ? 'احفظ هذه السيارة للمرة القادمة' : 'Save this car for next time';

  // Service selection step
  String get chooseYourService => _ar ? 'اختر خدمتك' : 'Choose Your Service';
  String get selectWashType =>
      _ar ? 'اختر نوع الغسيل الذي تحتاجه.' : 'Select what type of wash you need.';
  String get exteriorOnly => _ar ? 'خارجي فقط' : 'Exterior Only';
  String get exteriorOnlyDesc => _ar
      ? 'غسيل خارجي كامل وشطف وتجفيف. مثالي للتنشيط السريع.'
      : 'Full exterior wash, rinse, and dry. Perfect for a quick refresh.';
  String get interiorOnly => _ar ? 'داخلي فقط' : 'Interior Only';
  String get interiorOnlyDesc => _ar
      ? 'تنظيف داخلي عميق دون الجزء الخارجي.'
      : 'Deep interior clean without the exterior.';
  String get fullService => _ar ? 'خارجي + داخلي كامل' : 'Full Interior + Exterior';
  String get fullServiceDesc => _ar
      ? 'تنظيف شامل داخلي وخارجي. التجربة المميزة الكاملة.'
      : 'Complete detailing inside and out. The full premium experience.';
  String get featExteriorWash => _ar ? 'غسيل خارجي وشطف' : 'Exterior wash & rinse';
  String get featWheelCleaning => _ar ? 'تنظيف العجلات' : 'Wheel cleaning';
  String get featTowelDry => _ar ? 'تجفيف بالمنشفة' : 'Towel dry';
  String get featWindowCleaning => _ar ? 'تنظيف النوافذ' : 'Window cleaning';
  String get featVacuum => _ar ? 'شفط داخلي' : 'Interior vacuum';
  String get featDashboardWipe => _ar ? 'تنظيف اللوح والأسطح' : 'Dashboard & surfaces wipe';
  String get featWindowInterior =>
      _ar ? 'تنظيف زجاج النوافذ من الداخل' : 'Window interior cleaning';
  String get featAirFreshener => _ar ? 'معطر جو' : 'Air freshener';
  String get featEverythingExterior =>
      _ar ? 'كل ما في الغسيل الخارجي' : 'Everything in Exterior';

  // Location step
  String get dragMapPin =>
      _ar
          ? 'اسحب الخريطة لتحريك الدبوس إلى موقعك الدقيق'
          : 'Drag the map to move the pin to your exact location';
  String get savedLocations => _ar ? 'المواقع المحفوظة' : 'Saved locations';
  String get longPressToDelete =>
      _ar ? 'اضغط مطولاً لحذف الموقع' : 'Long-press a chip to delete it';
  String get confirmStreetAddress =>
      _ar ? 'تأكيد عنوان شارعك' : 'Confirm your street address';
  String get addressHint =>
      _ar ? 'مثال: 15 شارع التحرير، المعادي، القاهرة' : 'e.g. 15 شارع التحرير، المعادي، القاهرة';
  String get saveThisLocation => _ar ? 'احفظ هذا الموقع' : 'Save this location';
  String get locationLabel =>
      _ar ? 'التسمية (مثال: المنزل، العمل)' : 'Label (e.g. Home, Work)';
  String get confirmLocation => _ar ? 'تأكيد الموقع' : 'Confirm Location';
  String get enterStreetAddress =>
      _ar ? 'الرجاء إدخال عنوان شارعك.' : 'Please enter your street address.';
  String get locationDenied =>
      _ar ? 'تم رفض الموقع. حرّك دبوس الخريطة يدوياً.' : 'Location denied. Move the map pin manually.';
  String get locationServiceDisabled =>
      _ar ? 'خدمة الموقع معطّلة. فعّلها من إعدادات الجهاز.' : 'Location service is off. Enable it in device settings.';
  String get locationDeniedBrowser => _ar
      ? 'أتح الموقع في المتصفح، أو حرّك دبوس الخريطة يدوياً.'
      : 'Allow location in your browser, or drag the map pin manually.';
  String get locationRequiresHttps => _ar
      ? 'المتصفح يمنع تحديد الموقع على HTTP. اسحب الدبوس يدوياً أو استخدم تطبيق الموبايل.'
      : 'Browser blocks location on HTTP. Drag the pin manually or use the mobile app.';
  String get couldNotGetGps =>
      _ar ? 'تعذر الحصول على الموقع. حرّك الدبوس يدوياً.' : 'Could not get GPS. Drag the pin manually.';

  // Time slot step
  String get pickDateTime => _ar ? 'اختر تاريخاً ووقتاً' : 'Pick a Date & Time';
  String get slotWindowHint =>
      _ar ? 'كل موعد نافذة خدمة مدتها ساعتان.' : 'Each slot is a 2-hour service window.';
  String get availableTimeWindows => _ar ? 'المواعيد المتاحة' : 'Available Time Windows';
  String get noSlotsForDay =>
      _ar ? 'لا توجد مواعيد متاحة لهذا اليوم.' : 'No available slots for this day.';
  String spotsLeft(int n) => _ar
      ? (n == 1 ? 'موعد واحد متبقٍ' : '$n مواعيد متبقية')
      : '$n spot${n == 1 ? '' : 's'} left';

  // Confirmation step
  String get confirmBooking => _ar ? 'تأكيد الحجز' : 'Confirm Booking';
  String get reviewBooking =>
      _ar ? 'راجع حجزك قبل الإرسال.' : 'Review your booking before submitting.';
  String get makeAndModel => _ar ? 'الماركة والموديل' : 'Make & Model';
  String get color => _ar ? 'اللون' : 'Color';
  String get plate => _ar ? 'اللوحة' : 'Plate';
  String get year => _ar ? 'السنة' : 'Year';
  String get serviceLabel => _ar ? 'الخدمة' : 'Service';
  String get serviceType => _ar ? 'النوع' : 'Type';
  String get price => _ar ? 'السعر' : 'Price';
  String get address => _ar ? 'العنوان' : 'Address';
  String get schedule => _ar ? 'الموعد' : 'Schedule';
  String get date => _ar ? 'التاريخ' : 'Date';
  String get window => _ar ? 'النافذة' : 'Window';
  String get submitBooking => _ar ? 'إرسال الحجز' : 'Submit Booking';
  String get bookingSubmitted =>
      _ar ? 'تم إرسال الحجز! سنؤكده قريباً.' : "Booking submitted! We'll confirm shortly.";
  String failedToSubmit(String err) =>
      _ar ? 'فشل الإرسال: $err' : 'Failed to submit: $err';

  // History
  String get myBookings => _ar ? 'حجوزاتي' : 'My Bookings';
  String get tabActive => _ar ? 'نشطة' : 'Active';
  String get tabCompleted => _ar ? 'مكتملة' : 'Completed';
  String get tabCancelled => _ar ? 'ملغاة' : 'Cancelled';
  String get noActiveBookings => _ar ? 'لا توجد حجوزات نشطة' : 'No active bookings';
  String get noCompletedBookings =>
      _ar ? 'لا توجد حجوزات مكتملة بعد' : 'No completed bookings yet';
  String get noCancelledBookings => _ar ? 'لا توجد حجوزات ملغاة' : 'No cancelled bookings';
  String get cancelBookingTitle => _ar ? 'إلغاء الحجز؟' : 'Cancel Booking?';
  String get cancelBookingConfirm =>
      _ar ? 'هل أنت متأكد من إلغاء هذا الحجز؟' : 'Are you sure you want to cancel this booking?';
  String get no => _ar ? 'لا' : 'No';
  String get yesCancel => _ar ? 'نعم، إلغاء' : 'Yes, cancel';
  String get cancel => _ar ? 'إلغاء' : 'Cancel';
  String get addNewCar => _ar ? '+ إضافة سيارة جديدة' : '+ Add a new car';
  String get addNewAddress => _ar ? '+ إضافة عنوان جديد' : '+ Enter a new address';
  String get useDifferentAddress => _ar ? 'استخدام عنوان مختلف' : 'Use a different address';
  String get searchLocation => _ar ? 'ابحث عن موقع...' : 'Search for a location...';
  String get searchingLocation => _ar ? 'جارٍ البحث...' : 'Searching...';

  // Status & service labels
  String statusLabel(BookingStatus s) => switch (s) {
        BookingStatus.pending => _ar ? 'قيد الانتظار' : 'Pending',
        BookingStatus.confirmed => _ar ? 'مؤكد' : 'Confirmed',
        BookingStatus.inProgress => _ar ? 'جارٍ التنفيذ' : 'In Progress',
        BookingStatus.completed => _ar ? 'مكتمل' : 'Completed',
        BookingStatus.cancelled => _ar ? 'ملغى' : 'Cancelled',
      };

  String serviceTypeName(ServiceType t) => switch (t) {
        ServiceType.exteriorOnly => exteriorOnly,
        ServiceType.interiorOnly => interiorOnly,
        ServiceType.fullService => fullService,
      };

  String serviceTypePrice(ServiceType t) => switch (t) {
        ServiceType.exteriorOnly =>
          '${AppConfig.priceExteriorOnly} ${AppConfig.currency}',
        ServiceType.interiorOnly =>
          '${AppConfig.priceInteriorOnly} ${AppConfig.currency}',
        ServiceType.fullService =>
          '${AppConfig.priceFullService} ${AppConfig.currency}',
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
