import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/models/job.dart';
import '../../core/services/job_service.dart';

class JobDetailScreen extends ConsumerStatefulWidget {
  final Job job;
  const JobDetailScreen({super.key, required this.job});

  @override
  ConsumerState<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends ConsumerState<JobDetailScreen> {
  late Job _job;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _job = widget.job;
  }

  Future<void> _updateStatus(JobStatus status) async {
    setState(() => _loading = true);
    try {
      await ref.read(jobServiceProvider).updateStatus(_job.id, status);
      setState(() => _job = Job(
            id: _job.id,
            customerName: _job.customerName,
            customerPhone: _job.customerPhone,
            car: _job.car,
            serviceType: _job.serviceType,
            address: _job.address,
            latitude: _job.latitude,
            longitude: _job.longitude,
            scheduledAt: _job.scheduledAt,
            timeSlot: _job.timeSlot,
            status: status,
          ));
      if (mounted) {
        final l10n = context.l10n;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l10n.statusUpdated(l10n.jobStatusLabel(status.name))),
          backgroundColor: Colors.green,
        ));
        if (status == JobStatus.completed) Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _copyAddress() {
    Clipboard.setData(ClipboardData(text: _job.address));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.addressCopied), backgroundColor: Colors.green));
  }

  Future<void> _openGoogleMaps() async {
    final Uri url;
    if (_job.latitude != 0 && _job.longitude != 0) {
      url = Uri.parse(
          'https://www.google.com/maps/dir/?api=1&destination=${_job.latitude},${_job.longitude}');
    } else {
      final encoded = Uri.encodeComponent(_job.address);
      url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$encoded');
    }
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.couldNotOpenMaps)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fmt = DateFormat('EEEE, MMMM d, yyyy • h:mm a');
    final hasCoords = _job.latitude != 0 && _job.longitude != 0;

    return Scaffold(
      appBar: AppBar(
        title: Text('#${_job.id.substring(0, 6).toUpperCase()}'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Chip(
              label: Text(l10n.jobStatusLabel(_job.status.name),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              backgroundColor: _statusColor(_job.status).withOpacity(0.15),
              side: BorderSide.none,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                SizedBox(
                  height: 220,
                  child: hasCoords
                      ? Stack(children: [
                          FlutterMap(
                            options: MapOptions(
                              initialCenter: LatLng(_job.latitude, _job.longitude),
                              initialZoom: 15,
                            ),
                            children: [
                              TileLayer(
                                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.washly.worker',
                              ),
                              MarkerLayer(markers: [
                                Marker(
                                  point: LatLng(_job.latitude, _job.longitude),
                                  width: 40, height: 40,
                                  child: const Icon(Icons.location_pin,
                                      color: Colors.red, size: 40),
                                ),
                              ]),
                            ],
                          ),
                          Positioned(
                            bottom: 0, left: 0, right: 0,
                            child: Container(
                              color: Colors.black54,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              child: Row(children: [
                                const Icon(Icons.location_on, color: Colors.white, size: 14),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(_job.address,
                                      style: const TextStyle(color: Colors.white, fontSize: 13),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.copy, color: Colors.white, size: 18),
                                  onPressed: _copyAddress,
                                  constraints: const BoxConstraints(),
                                  padding: EdgeInsets.zero,
                                ),
                              ]),
                            ),
                          ),
                          Positioned(
                            top: 12, right: 12,
                            child: ElevatedButton.icon(
                              onPressed: _openGoogleMaps,
                              icon: const Icon(Icons.navigation, size: 18),
                              label: Text(l10n.navigate),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.blue[700],
                                elevation: 4,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                textStyle: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ])
                      : Container(
                          color: Colors.grey[100],
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.location_off, size: 40, color: Colors.grey),
                              const SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(_job.address, textAlign: TextAlign.center),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  TextButton.icon(
                                    onPressed: _copyAddress,
                                    icon: const Icon(Icons.copy, size: 16),
                                    label: Text(l10n.copy),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton.icon(
                                    onPressed: _openGoogleMaps,
                                    icon: const Icon(Icons.navigation, size: 16),
                                    label: Text(l10n.navigate),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue[700],
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                ),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _Card(title: l10n.customer, icon: Icons.person, rows: [
                        _info(l10n.name, _job.customerName),
                        if (_job.customerPhone.isNotEmpty)
                          _info(l10n.phone, _job.customerPhone),
                      ]),
                      const SizedBox(height: 12),
                      _Card(title: l10n.car, icon: Icons.directions_car, rows: [
                        _info(l10n.vehicle, _job.carSummary),
                        if ((_job.car['plateNumber'] as String?)?.isNotEmpty == true)
                          _info(l10n.plate, _job.car['plateNumber'] as String),
                        if ((_job.car['color'] as String?)?.isNotEmpty == true)
                          _info(l10n.color, _job.car['color'] as String),
                      ]),
                      const SizedBox(height: 12),
                      _Card(title: l10n.job, icon: Icons.cleaning_services, rows: [
                        _info(l10n.service, l10n.serviceNameFor(_job.serviceType)),
                        _info(l10n.date, fmt.format(_job.scheduledAt)),
                        _info(l10n.slot, _job.timeSlot),
                      ]),
                    ],
                  ),
                ),
              ],
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_job.status == JobStatus.confirmed)
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton.icon(
                              onPressed: () => _updateStatus(JobStatus.inProgress),
                              icon: const Icon(Icons.play_arrow),
                              label: Text(l10n.startWash,
                                  style: const TextStyle(fontSize: 16)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        if (_job.status == JobStatus.inProgress) ...[
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton.icon(
                              onPressed: () => _updateStatus(JobStatus.completed),
                              icon: const Icon(Icons.check_circle),
                              label: Text(l10n.markAsDone,
                                  style: const TextStyle(fontSize: 16)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                        if (_job.status == JobStatus.pending)
                          Text(l10n.waitingForAdmin,
                              style: const TextStyle(color: Colors.grey)),
                        if (_job.status == JobStatus.completed)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_circle, color: Colors.green),
                              const SizedBox(width: 8),
                              Text(l10n.jobCompleted,
                                  style: const TextStyle(
                                      color: Colors.green, fontWeight: FontWeight.bold)),
                            ],
                          ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(JobStatus s) => switch (s) {
        JobStatus.confirmed => Colors.blue,
        JobStatus.inProgress => Colors.orange,
        JobStatus.completed => Colors.green,
        JobStatus.cancelled => Colors.red,
        _ => Colors.grey,
      };

  Widget _info(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
                width: 70,
                child: Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13))),
            Expanded(
                child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
          ],
        ),
      );
}

class _Card extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> rows;
  const _Card({required this.title, required this.icon, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(title,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary)),
            ]),
            const Divider(height: 16),
            ...rows,
          ],
        ),
      ),
    );
  }
}
