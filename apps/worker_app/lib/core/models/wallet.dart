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
        id:            j['id']           as String,
        workerId:      j['workerId']      as String,
        bookingId:     j['bookingId']     as String?,
        amount:        (j['amount']       as num?)?.toInt() ?? 0,
        paymentMethod: j['paymentMethod'] as String? ?? 'cash',
        status:        j['status']        as String? ?? 'pending',
        customerName:  j['customerName']  as String?,
        serviceType:   j['serviceType']   as String?,
        scheduledAt:   j['scheduledAt'] != null
            ? DateTime.tryParse(j['scheduledAt'] as String)
            : null,
        timeSlot:      j['timeSlot']      as String?,
        settledAt:     j['settledAt'] != null
            ? DateTime.tryParse(j['settledAt'] as String)
            : null,
        createdAt:     DateTime.parse(j['createdAt'] as String),
      );
}
