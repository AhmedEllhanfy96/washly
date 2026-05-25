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
  String get appTitle => _ar ? 'مدير واشلي' : 'Washly Admin';

  // Auth
  String get signInToManage =>
      _ar ? 'سجّل دخولك لإدارة الحجوزات' : 'Sign in to manage bookings';
  String get adminEmail => _ar ? 'البريد الإلكتروني للمدير' : 'Admin Email';
  String get password => _ar ? 'كلمة المرور' : 'Password';
  String get invalidEmail => _ar ? 'بريد إلكتروني غير صحيح' : 'Invalid email';
  String get tooShort => _ar ? 'قصيرة جداً' : 'Too short';
  String get signIn => _ar ? 'تسجيل الدخول' : 'Sign In';
  String get required => _ar ? 'مطلوب' : 'Required';

  // Dashboard
  String get pendingLabel => _ar ? 'انتظار' : 'Pending';
  String get confirmedLabel => _ar ? 'مؤكدة' : 'Confirmed';
  String get todayLabel => _ar ? 'اليوم' : 'Today';
  String get inProgressLabel => _ar ? 'جارٍ التنفيذ' : 'In Progress';
  String get completedTodayLabel => _ar ? 'مكتمل اليوم' : 'Done Today';
  String get pendingApprovals => _ar ? 'طلبات قيد الموافقة' : 'Pending Approvals';
  String get viewAll => _ar ? 'عرض الكل' : 'View all';
  String get noPendingBookings =>
      _ar ? 'لا توجد حجوزات قيد الانتظار' : 'No pending bookings';
  String get todaySchedule => _ar ? 'جدول اليوم' : "Today's Schedule";
  String get noScheduleToday =>
      _ar ? 'لا توجد مواعيد مؤكدة لهذا اليوم' : 'No confirmed bookings for today';
  String get unassigned => _ar ? 'غير مسند' : 'Unassigned';
  String get waitingLabel => _ar ? 'انتظر' : 'waiting';

  // Booking list
  String get allBookings => _ar ? 'كل الحجوزات' : 'All Bookings';
  String get all => _ar ? 'الكل' : 'All';
  String get manualBooking => _ar ? 'حجز يدوي' : 'Manual Booking';
  String get noBookings => _ar ? 'لا توجد حجوزات' : 'No bookings';

  // Booking detail
  String get bookingNotFound => _ar ? 'الحجز غير موجود' : 'Booking not found';
  String get customer => _ar ? 'العميل' : 'Customer';
  String get name => _ar ? 'الاسم' : 'Name';
  String get phone => _ar ? 'الهاتف' : 'Phone';
  String get car => _ar ? 'السيارة' : 'Car';
  String get vehicle => _ar ? 'المركبة' : 'Vehicle';
  String get plate => _ar ? 'اللوحة' : 'Plate';
  String get color => _ar ? 'اللون' : 'Color';
  String get service => _ar ? 'الخدمة' : 'Service';
  String get type => _ar ? 'النوع' : 'Type';
  String get scheduleLabel => _ar ? 'الموعد' : 'Schedule';
  String get dateTime => _ar ? 'التاريخ والوقت' : 'Date & Time';
  String get slot => _ar ? 'الموعد' : 'Slot';
  String get assignedTo => _ar ? 'مسند إلى' : 'Assigned to';
  String get actions => _ar ? 'إجراءات' : 'Actions';
  String get couldNotLoadWorkers =>
      _ar ? 'تعذر تحميل العمال' : 'Could not load workers';
  String get rejectBooking => _ar ? 'رفض الحجز' : 'Reject Booking';
  String get markInProgress => _ar ? 'تحديد كقيد التنفيذ' : 'Mark as In Progress';
  String get markCompleted => _ar ? 'تحديد كمكتمل' : 'Mark as Completed';
  String get assignToWorker => _ar ? 'إسناد إلى عامل' : 'Assign to Worker';
  String get confirmAndAssign =>
      _ar ? 'تأكيد والإسناد إلى عامل' : 'Confirm & Assign to Worker';
  String get noWorkersYet =>
      _ar
          ? 'لا يوجد عمال بعد. انتقل إلى تبويب العمال لإنشاء حسابات.'
          : 'No workers yet. Go to Workers tab to create accounts.';
  String get approveWithoutAssigning =>
      _ar ? 'الموافقة دون إسناد' : 'Approve Without Assigning';
  String get copyMessageForTeam =>
      _ar ? 'نسخ الرسالة للفريق' : 'Copy Message for Team';
  String get messageCopied =>
      _ar
          ? 'تم نسخ الرسالة — الصقها في واتساب أو رسالة نصية'
          : 'Message copied — paste it in WhatsApp or SMS';
  String get bookingConfirmedAssigned =>
      _ar ? 'تم تأكيد الحجز وإسناده إلى العامل!' : 'Booking confirmed & assigned to worker!';

  // Create booking
  String get newManualBooking => _ar ? 'حجز يدوي جديد' : 'New Manual Booking';
  String get bookingSource => _ar ? 'مصدر الحجز' : 'Booking Source';
  String get customerName => _ar ? 'اسم العميل' : 'Customer Name';
  String get phoneNumber => _ar ? 'رقم الهاتف' : 'Phone Number';
  String get carDetails => _ar ? 'تفاصيل السيارة' : 'Car Details';
  String get make => _ar ? 'الماركة' : 'Make';
  String get model => _ar ? 'الموديل' : 'Model';
  String get plateNumber => _ar ? 'رقم اللوحة' : 'Plate Number';
  String get yearOpt => _ar ? 'السنة (اختياري)' : 'Year (opt.)';
  String get colorLabel => _ar ? 'اللون' : 'Color';
  String get timeSlot => _ar ? 'الموعد' : 'Time Slot';
  String get address => _ar ? 'العنوان' : 'Address';
  String get notesOptional => _ar ? 'ملاحظات (اختياري)' : 'Notes (optional)';
  String get notesHint => _ar ? 'أي تعليمات خاصة…' : 'Any special instructions…';
  String get createBookingBtn => _ar ? 'إنشاء الحجز' : 'Create Booking';
  String get bookingCreated =>
      _ar ? 'تم إنشاء الحجز بنجاح' : 'Booking created successfully';
  String get selectCarColor => _ar ? 'الرجاء اختيار لون السيارة' : 'Please select a car color';

  // Team
  String get workers => _ar ? 'العمال' : 'Workers';
  String get addWorker => _ar ? 'إضافة عامل' : 'Add Worker';
  String get noWorkersEmpty => _ar ? 'لا يوجد عمال بعد' : 'No workers yet';
  String get addWorkersHint =>
      _ar
          ? 'أضف عمالاً لتتمكن من إسناد الحجوزات إليهم'
          : 'Add workers so you can assign bookings to them';
  String get addFirstWorker => _ar ? 'إضافة أول عامل' : 'Add First Worker';
  String get addWorkerAccount => _ar ? 'إضافة حساب عامل' : 'Add Worker Account';
  String get fullName => _ar ? 'الاسم الكامل' : 'Full Name';
  String get emailLogin => _ar ? 'البريد الإلكتروني (للتسجيل)' : 'Email (login)';
  String get enterValidEmail =>
      _ar ? 'أدخل بريداً إلكترونياً صحيحاً' : 'Enter valid email';
  String get min6Chars => _ar ? '6 أحرف على الأقل' : 'Min 6 characters';
  String get workerLoginHint =>
      _ar
          ? 'سيستخدم العامل البريد الإلكتروني وكلمة المرور لتسجيل الدخول في تطبيق العمال.'
          : 'Worker will use email + password to login to the Worker app.';
  String get cancel => _ar ? 'إلغاء' : 'Cancel';
  String get createAccountBtn => _ar ? 'إنشاء الحساب' : 'Create Account';
  String get deleteWorker => _ar ? 'حذف العامل' : 'Delete Worker';
  String removeWorkerConfirm(String name) => _ar
      ? 'إزالة $name؟ لن يتمكن من تسجيل الدخول بعد الآن.'
      : 'Remove $name? They will no longer be able to login.';
  String get delete => _ar ? 'حذف' : 'Delete';
  String get failedCreateWorker =>
      _ar ? 'فشل إنشاء حساب العامل' : 'Failed to create worker';
  String get failedCreateWorkerRetry =>
      _ar ? 'فشل إنشاء الحساب. حاول مجدداً.' : 'Failed to create worker. Try again.';

  // Schedule management
  String get scheduleManagement => _ar ? 'إدارة الجداول' : 'Schedule Management';
  String get scheduleUpdated => _ar ? 'تم حفظ جدول اليوم بنجاح' : 'Schedule saved successfully';
  String get scheduleReset => _ar ? 'تمت إعادة الضبط إلى الإعدادات الافتراضية' : 'Reset to default settings';
  String get resetToDefault => _ar ? 'إعادة الضبط للافتراضي' : 'Reset to Default';
  String get resetToDefaultConfirm => _ar ? 'هل تريد حذف إعدادات هذا اليوم والعودة للافتراضية؟' : 'Delete overrides for this day and restore defaults?';
  String get reset => _ar ? 'إعادة ضبط' : 'Reset';
  String get save => _ar ? 'حفظ' : 'Save';
  String get dayClosed => _ar ? 'اليوم مغلق' : 'Day Closed';
  String get dayOpen => _ar ? 'اليوم مفتوح' : 'Day Open';
  String get dayClosedSubtitle => _ar ? 'لن يتمكن العملاء من حجز هذا اليوم' : 'Customers cannot book this day';
  String get dayOpenSubtitle => _ar ? 'متاح للحجز' : 'Available for bookings';
  String get workersAvailable => _ar ? 'العمال المتاحون' : 'Workers Available';
  String get workersAvailableSubtitle => _ar ? 'عدد الحجوزات في كل نافذة زمنية' : 'Max bookings per time window';
  String get workersLabel => _ar ? 'عامل' : 'Workers';
  String get windowDuration => _ar ? 'مدة النافذة' : 'Window Duration';
  String get windowDurationSubtitle => _ar ? 'مدة كل موعد بالساعات' : 'Duration of each booking slot';
  String get oneHour => _ar ? 'ساعة' : '1 Hour';
  String get twoHours => _ar ? 'ساعتان' : '2 Hours';
  String get operatingHours => _ar ? 'ساعات العمل' : 'Operating Hours';
  String get startTime => _ar ? 'بداية الدوام' : 'Start Time';
  String get endTime => _ar ? 'نهاية الدوام' : 'End Time';
  String get slotPreview => _ar ? 'معاينة المواعيد' : 'Slot Preview';
  String get slotsLabel => _ar ? 'موعد' : 'slots';
  String get noSlotsGenerated => _ar ? 'لا توجد مواعيد بهذه الإعدادات' : 'No slots with these settings';
  String get saveSchedule => _ar ? 'حفظ الجدول' : 'Save Schedule';
  String get noChanges => _ar ? 'لا توجد تغييرات' : 'No Changes';

  // Map location picker
  String get pickFromMap => _ar ? 'اختر من الخريطة' : 'Pick from Map';
  String get dragMapPin => _ar ? 'اسحب الخريطة لضبط الدبوس على موقعك' : 'Drag the map to place the pin on your location';
  String get confirmStreetAddress => _ar ? 'أكّد عنوان الشارع' : 'Confirm Street Address';
  String get addressHint => _ar ? 'مثال: 15 شارع التحرير، المعادي' : 'e.g. 15 El Tahrir St, Maadi';
  String get confirmLocation => _ar ? 'تأكيد الموقع' : 'Confirm Location';
  String get enterStreetAddress => _ar ? 'الرجاء إدخال عنوان الشارع' : 'Please enter a street address';
  String get couldNotGetGps => _ar ? 'تعذّر تحديد الموقع. اسحب الدبوس يدوياً.' : 'Could not get GPS. Drag the pin manually.';
  String get locationDenied => _ar ? 'إذن الموقع مرفوض. فعّله من الإعدادات.' : 'Location permission denied. Enable it in Settings.';
  String get searchLocation => _ar ? 'ابحث عن موقع...' : 'Search for a location...';

  // Create booking — source chips
  String get location => _ar ? 'الموقع' : 'Location';
  String get sourcePhone => _ar ? 'مكالمة هاتفية' : 'Phone Call';
  String get sourceWalkIn => _ar ? 'زيارة مباشرة' : 'Walk-in';
  String get sourceOther => _ar ? 'أخرى' : 'Other';

  // Customers
  String get customers => _ar ? 'العملاء' : 'Customers';
  String get noCustomers => _ar ? 'لا يوجد عملاء بعد' : 'No customers yet';
  String get totalBookings => _ar ? 'إجمالي الحجوزات' : 'Total bookings';
  String get memberSince => _ar ? 'عضو منذ' : 'Member since';
  String get callCustomer => _ar ? 'اتصال' : 'Call';
  String get whatsappCustomer => _ar ? 'واتساب' : 'WhatsApp';
  String get contactCustomer => _ar ? 'التواصل مع العميل' : 'Contact Customer';

  // Status & service
  String statusLabel(BookingStatus s) => switch (s) {
        BookingStatus.pending => _ar ? 'قيد الانتظار' : 'Pending',
        BookingStatus.confirmed => _ar ? 'مؤكد' : 'Confirmed',
        BookingStatus.inProgress => _ar ? 'جارٍ التنفيذ' : 'In Progress',
        BookingStatus.completed => _ar ? 'مكتمل' : 'Completed',
        BookingStatus.cancelled => _ar ? 'ملغى' : 'Cancelled',
      };

  String serviceTypeName(ServiceType t) => switch (t) {
        ServiceType.exteriorOnly => _ar ? 'خارجي فقط' : 'Exterior Only',
        ServiceType.interiorOnly => _ar ? 'داخلي فقط' : 'Interior Only',
        ServiceType.fullService => _ar ? 'خارجي + داخلي كامل' : 'Full Service',
      };

  String serviceTypeDetail(ServiceType t) => switch (t) {
        ServiceType.exteriorOnly => _ar
            ? 'خارجي فقط — ${AppConfig.priceExteriorOnly} ج.م.'
            : 'Exterior Only — ${AppConfig.priceExteriorOnly} ${AppConfig.currency}',
        ServiceType.interiorOnly => _ar
            ? 'داخلي فقط — ${AppConfig.priceInteriorOnly} ج.م.'
            : 'Interior Only — ${AppConfig.priceInteriorOnly} ${AppConfig.currency}',
        ServiceType.fullService => _ar
            ? 'خارجي + داخلي كامل — ${AppConfig.priceFullService} ج.م.'
            : 'Full Interior + Exterior — ${AppConfig.priceFullService} ${AppConfig.currency}',
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
