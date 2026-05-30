class WorkerWalletSummary {
  final String workerId;
  final String workerName;
  final String workerPhone;
  final int totalPending;
  final int totalSettled;
  final int pendingCount;

  const WorkerWalletSummary({
    required this.workerId,
    required this.workerName,
    required this.workerPhone,
    required this.totalPending,
    required this.totalSettled,
    required this.pendingCount,
  });

  factory WorkerWalletSummary.fromJson(Map<String, dynamic> j) => WorkerWalletSummary(
        workerId:     j['workerId']    as String,
        workerName:   j['workerName']  as String? ?? '',
        workerPhone:  j['workerPhone'] as String? ?? '',
        totalPending: (j['totalPending'] as num?)?.toInt() ?? 0,
        totalSettled: (j['totalSettled'] as num?)?.toInt() ?? 0,
        pendingCount: (j['pendingCount'] as num?)?.toInt() ?? 0,
      );
}

class DailyWalletEntry {
  final DateTime date;
  final int fromInstapay;
  final int fromCash;
  final int fromCreditCard;
  final int total;
  final bool reconciled;

  const DailyWalletEntry({
    required this.date,
    required this.fromInstapay,
    required this.fromCash,
    this.fromCreditCard = 0,
    required this.total,
    required this.reconciled,
  });

  factory DailyWalletEntry.fromJson(Map<String, dynamic> j) => DailyWalletEntry(
        date:           DateTime.parse(j['date'] as String),
        fromInstapay:   (j['fromInstapay']   as num?)?.toInt() ?? 0,
        fromCash:       (j['fromCash']       as num?)?.toInt() ?? 0,
        fromCreditCard: (j['fromCreditCard'] as num?)?.toInt() ?? 0,
        total:          (j['total']          as num?)?.toInt() ?? 0,
        reconciled:     j['reconciled']      as bool? ?? false,
      );
}

class CompanyWalletSummary {
  final int fromInstapay;
  final int fromCash;
  final int fromCreditCard;
  final int grandTotal;
  final int entryCount;
  final int todayTotal;
  final int todayFromInstapay;
  final int todayFromCash;
  final int todayFromCreditCard;
  final List<DailyWalletEntry> daily;

  const CompanyWalletSummary({
    required this.fromInstapay,
    required this.fromCash,
    this.fromCreditCard = 0,
    required this.grandTotal,
    required this.entryCount,
    this.todayTotal = 0,
    this.todayFromInstapay = 0,
    this.todayFromCash = 0,
    this.todayFromCreditCard = 0,
    this.daily = const [],
  });

  factory CompanyWalletSummary.fromJson(Map<String, dynamic> j) => CompanyWalletSummary(
        fromInstapay:        (j['fromInstapay']        as num?)?.toInt() ?? 0,
        fromCash:            (j['fromCash']            as num?)?.toInt() ?? 0,
        fromCreditCard:      (j['fromCreditCard']      as num?)?.toInt() ?? 0,
        grandTotal:          (j['grandTotal']          as num?)?.toInt() ?? 0,
        entryCount:          (j['entryCount']          as num?)?.toInt() ?? 0,
        todayTotal:          (j['todayTotal']          as num?)?.toInt() ?? 0,
        todayFromInstapay:   (j['todayFromInstapay']   as num?)?.toInt() ?? 0,
        todayFromCash:       (j['todayFromCash']       as num?)?.toInt() ?? 0,
        todayFromCreditCard: (j['todayFromCreditCard'] as num?)?.toInt() ?? 0,
        daily: (j['daily'] as List<dynamic>? ?? [])
            .map((e) => DailyWalletEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class CompanyDayEntry {
  final String id;
  final String source;
  final String? bookingId;
  final String? workerId;
  final String? workerName;
  final int amount;
  final String? customerName;
  final String? serviceType;
  final String? timeSlot;
  final DateTime? scheduledAt;
  final DateTime createdAt;

  const CompanyDayEntry({
    required this.id,
    required this.source,
    this.bookingId,
    this.workerId,
    this.workerName,
    required this.amount,
    this.customerName,
    this.serviceType,
    this.timeSlot,
    this.scheduledAt,
    required this.createdAt,
  });

  factory CompanyDayEntry.fromJson(Map<String, dynamic> j) => CompanyDayEntry(
        id:           j['id']           as String,
        source:       j['source']       as String,
        bookingId:    j['bookingId']    as String?,
        workerId:     j['workerId']     as String?,
        workerName:   j['workerName']   as String?,
        amount:       (j['amount']      as num?)?.toInt() ?? 0,
        customerName: j['customerName'] as String?,
        serviceType:  j['serviceType']  as String?,
        timeSlot:     j['timeSlot']     as String?,
        scheduledAt:  j['scheduledAt'] != null
            ? DateTime.tryParse(j['scheduledAt'] as String)
            : null,
        createdAt:    DateTime.parse(j['createdAt'] as String),
      );
}

class WalletEntry {
  final String id;
  final String workerId;
  final String? bookingId;
  final int amount;
  final String paymentMethod;
  final String status;
  final String? customerName;
  final String? serviceType;
  final DateTime? scheduledAt;
  final String? timeSlot;
  final DateTime? settledAt;
  final DateTime createdAt;

  const WalletEntry({
    required this.id,
    required this.workerId,
    this.bookingId,
    required this.amount,
    required this.paymentMethod,
    required this.status,
    this.customerName,
    this.serviceType,
    this.scheduledAt,
    this.timeSlot,
    this.settledAt,
    required this.createdAt,
  });

  bool get isPending => status == 'pending';

  factory WalletEntry.fromJson(Map<String, dynamic> j) => WalletEntry(
        id:            j['id']            as String,
        workerId:      j['workerId']       as String,
        bookingId:     j['bookingId']      as String?,
        amount:        (j['amount']        as num?)?.toInt() ?? 0,
        paymentMethod: j['paymentMethod']  as String? ?? 'cash',
        status:        j['status']         as String? ?? 'pending',
        customerName:  j['customerName']   as String?,
        serviceType:   j['serviceType']    as String?,
        scheduledAt:   j['scheduledAt'] != null
            ? DateTime.tryParse(j['scheduledAt'] as String)
            : null,
        timeSlot:      j['timeSlot']       as String?,
        settledAt:     j['settledAt'] != null
            ? DateTime.tryParse(j['settledAt'] as String)
            : null,
        createdAt:     DateTime.parse(j['createdAt'] as String),
      );
}
