import 'package:flutter/material.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/models/booking.dart';

class StatusBadge extends StatelessWidget {
  final BookingStatus status;

  const StatusBadge({super.key, required this.status});

  Color get _color => switch (status) {
        BookingStatus.pending => const Color(0xFFFFA726),
        BookingStatus.confirmed => const Color(0xFF42A5F5),
        BookingStatus.inProgress => const Color(0xFFAB47BC),
        BookingStatus.completed => const Color(0xFF66BB6A),
        BookingStatus.cancelled => const Color(0xFFEF5350),
      };

  IconData get _icon => switch (status) {
        BookingStatus.pending => Icons.hourglass_empty,
        BookingStatus.confirmed => Icons.check_circle_outline,
        BookingStatus.inProgress => Icons.local_car_wash,
        BookingStatus.completed => Icons.check_circle,
        BookingStatus.cancelled => Icons.cancel_outlined,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: 14, color: _color),
          const SizedBox(width: 4),
          Text(
            context.l10n.statusLabel(status),
            style: TextStyle(
                color: _color, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
