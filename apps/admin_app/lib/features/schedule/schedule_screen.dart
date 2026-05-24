import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/services/schedule_service.dart';

class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  // Selected date — default today
  DateTime _selectedDate = DateTime.now();

  // Config currently shown in the editor (null = loading)
  ScheduleConfig? _config;
  bool _loading = false;
  bool _saving = false;
  bool _dirty = false; // has unsaved changes

  // Generate list of dates: 7 past + today + 30 future
  late final List<DateTime> _dates = List.generate(
    38,
    (i) => DateTime.now().subtract(const Duration(days: 7)).add(Duration(days: i)),
  );

  @override
  void initState() {
    super.initState();
    _loadConfig(_selectedDate);
  }

  String _fmt(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  Future<void> _loadConfig(DateTime date) async {
    setState(() {
      _loading = true;
      _config = null;
      _dirty = false;
    });
    try {
      final cfg = await ref.read(scheduleServiceProvider).getConfig(_fmt(date));
      if (mounted) setState(() => _config = cfg);
    } catch (_) {
      if (mounted) setState(() => _config = ScheduleConfig.defaults());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (_config == null) return;
    setState(() => _saving = true);
    try {
      await ref.read(scheduleServiceProvider).setConfig(_fmt(_selectedDate), _config!);
      if (mounted) {
        setState(() => _dirty = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.scheduleUpdated),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _resetToDefault() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(context.l10n.resetToDefault),
        content: Text(context.l10n.resetToDefaultConfirm),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(context.l10n.cancel)),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(context.l10n.reset,
                  style: const TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _saving = true);
    try {
      await ref.read(scheduleServiceProvider).resetConfig(_fmt(_selectedDate));
      await _loadConfig(_selectedDate);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(context.l10n.scheduleReset),
              backgroundColor: Colors.blue),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _update(ScheduleConfig updated) {
    setState(() {
      _config = updated;
      _dirty = true;
    });
  }

  Future<void> _pickTime({required bool isStart}) async {
    if (_config == null) return;
    final parts = (isStart ? _config!.dayStart : _config!.dayEnd)
        .split(':')
        .map(int.parse)
        .toList();
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: parts[0], minute: parts[1]),
      builder: (context, child) =>
          MediaQuery(data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true), child: child!),
    );
    if (picked == null) return;
    final val =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    _update(isStart ? _config!.copyWith(dayStart: val) : _config!.copyWith(dayEnd: val));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.scheduleManagement),
        actions: [
          if (_dirty)
            TextButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save, color: Colors.white),
              label: Text(l10n.save, style: const TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: Column(
        children: [
          // ── Date selector ─────────────────────────────────────────────
          Container(
            color: theme.colorScheme.surfaceContainerHighest,
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: SizedBox(
              height: 72,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _dates.length,
                itemBuilder: (_, i) {
                  final d = _dates[i];
                  final isSelected = _fmt(d) == _fmt(_selectedDate);
                  final isToday = _fmt(d) == _fmt(DateTime.now());
                  return GestureDetector(
                    onTap: () {
                      if (!isSelected) {
                        setState(() => _selectedDate = d);
                        _loadConfig(d);
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.only(right: 8),
                      width: 52,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : isToday
                                  ? theme.colorScheme.primary
                                  : Colors.grey[300]!,
                          width: isToday && !isSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            DateFormat('EEE').format(d),
                            style: TextStyle(
                              fontSize: 11,
                              color: isSelected ? Colors.white : Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${d.day}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : null,
                            ),
                          ),
                          Text(
                            DateFormat('MMM').format(d),
                            style: TextStyle(
                              fontSize: 10,
                              color: isSelected ? Colors.white70 : Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // ── Config editor ─────────────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _config == null
                    ? const SizedBox()
                    : ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          // Header
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate),
                                  style: const TextStyle(
                                      fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                              ),
                              TextButton(
                                onPressed: _saving ? null : _resetToDefault,
                                child: Text(l10n.resetToDefault,
                                    style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Open/Closed toggle
                          Card(
                            child: SwitchListTile(
                              secondary: Icon(
                                _config!.isClosed
                                    ? Icons.do_not_disturb_on_outlined
                                    : Icons.check_circle_outline,
                                color: _config!.isClosed ? Colors.red : Colors.green,
                              ),
                              title: Text(_config!.isClosed ? l10n.dayClosed : l10n.dayOpen,
                                  style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text(_config!.isClosed
                                  ? l10n.dayClosedSubtitle
                                  : l10n.dayOpenSubtitle),
                              value: !_config!.isClosed,
                              onChanged: (v) => _update(_config!.copyWith(isClosed: !v)),
                            ),
                          ),

                          if (!_config!.isClosed) ...[
                            const SizedBox(height: 12),

                            // Workers / capacity
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(children: [
                                      Icon(Icons.people_outline,
                                          color: theme.colorScheme.primary, size: 18),
                                      const SizedBox(width: 8),
                                      Text(l10n.workersAvailable,
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: theme.colorScheme.primary)),
                                    ]),
                                    const SizedBox(height: 4),
                                    Text(l10n.workersAvailableSubtitle,
                                        style: TextStyle(
                                            fontSize: 12, color: Colors.grey[600])),
                                    const SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        _CounterButton(
                                          icon: Icons.remove,
                                          onPressed: _config!.capacityPerWindow > 1
                                              ? () => _update(_config!.copyWith(
                                                    capacityPerWindow:
                                                        _config!.capacityPerWindow - 1,
                                                  ))
                                              : null,
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 28),
                                          child: Column(
                                            children: [
                                              Text(
                                                '${_config!.capacityPerWindow}',
                                                style: const TextStyle(
                                                    fontSize: 40,
                                                    fontWeight: FontWeight.bold),
                                              ),
                                              Text(l10n.workersLabel,
                                                  style: TextStyle(
                                                      color: Colors.grey[600],
                                                      fontSize: 12)),
                                            ],
                                          ),
                                        ),
                                        _CounterButton(
                                          icon: Icons.add,
                                          onPressed: _config!.capacityPerWindow < 20
                                              ? () => _update(_config!.copyWith(
                                                    capacityPerWindow:
                                                        _config!.capacityPerWindow + 1,
                                                  ))
                                              : null,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Window duration
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(children: [
                                      Icon(Icons.timelapse,
                                          color: theme.colorScheme.primary, size: 18),
                                      const SizedBox(width: 8),
                                      Text(l10n.windowDuration,
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: theme.colorScheme.primary)),
                                    ]),
                                    const SizedBox(height: 4),
                                    Text(l10n.windowDurationSubtitle,
                                        style: TextStyle(
                                            fontSize: 12, color: Colors.grey[600])),
                                    const SizedBox(height: 14),
                                    Row(
                                      children: [1, 2].map((h) {
                                        final sel = _config!.windowDuration == h;
                                        return Expanded(
                                          child: Padding(
                                            padding: EdgeInsets.only(
                                                right: h == 1 ? 8 : 0),
                                            child: GestureDetector(
                                              onTap: () => _update(
                                                  _config!.copyWith(windowDuration: h)),
                                              child: AnimatedContainer(
                                                duration: const Duration(
                                                    milliseconds: 180),
                                                height: 52,
                                                decoration: BoxDecoration(
                                                  color: sel
                                                      ? theme.colorScheme.primary
                                                      : Colors.grey[100],
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  border: Border.all(
                                                    color: sel
                                                        ? theme.colorScheme.primary
                                                        : Colors.grey[300]!,
                                                  ),
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    h == 1 ? l10n.oneHour : l10n.twoHours,
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.w600,
                                                      color: sel
                                                          ? Colors.white
                                                          : Colors.grey[700],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Day start / end times
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(children: [
                                      Icon(Icons.schedule,
                                          color: theme.colorScheme.primary, size: 18),
                                      const SizedBox(width: 8),
                                      Text(l10n.operatingHours,
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: theme.colorScheme.primary)),
                                    ]),
                                    const SizedBox(height: 14),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _TimeButton(
                                            label: l10n.startTime,
                                            value: _config!.dayStart,
                                            onTap: () => _pickTime(isStart: true),
                                          ),
                                        ),
                                        const Padding(
                                          padding: EdgeInsets.symmetric(horizontal: 12),
                                          child: Icon(Icons.arrow_forward,
                                              color: Colors.grey),
                                        ),
                                        Expanded(
                                          child: _TimeButton(
                                            label: l10n.endTime,
                                            value: _config!.dayEnd,
                                            onTap: () => _pickTime(isStart: false),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Slot preview
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(children: [
                                      Icon(Icons.preview_outlined,
                                          color: theme.colorScheme.primary, size: 18),
                                      const SizedBox(width: 8),
                                      Text(l10n.slotPreview,
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: theme.colorScheme.primary)),
                                      const Spacer(),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.primaryContainer,
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          '${_config!.slotLabels.length} ${l10n.slotsLabel}  ×  ${_config!.capacityPerWindow} ${l10n.workersLabel}',
                                          style: TextStyle(
                                              fontSize: 11,
                                              color:
                                                  theme.colorScheme.onPrimaryContainer),
                                        ),
                                      ),
                                    ]),
                                    const Divider(height: 16),
                                    if (_config!.slotLabels.isEmpty)
                                      Text(l10n.noSlotsGenerated,
                                          style: const TextStyle(color: Colors.grey))
                                    else
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: _config!.slotLabels
                                            .map((s) => Chip(
                                                  label: Text(s,
                                                      style: const TextStyle(
                                                          fontSize: 12)),
                                                  avatar: const Icon(
                                                      Icons.access_time,
                                                      size: 14),
                                                ))
                                            .toList(),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],

                          const SizedBox(height: 24),

                          // Save button
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton.icon(
                              onPressed: (_saving || !_dirty) ? null : _save,
                              icon: _saving
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white))
                                  : const Icon(Icons.save),
                              label: Text(
                                _dirty ? l10n.saveSchedule : l10n.noChanges,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
          ),
        ],
      ),
    );
  }
}

class _CounterButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  const _CounterButton({required this.icon, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: onPressed == null ? Colors.grey[200] : Theme.of(context).colorScheme.primaryContainer,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(icon,
              color: onPressed == null
                  ? Colors.grey
                  : Theme.of(context).colorScheme.primary),
        ),
      ),
    );
  }
}

class _TimeButton extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;
  const _TimeButton({required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(fontSize: 11, color: Colors.grey[600])),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.access_time, size: 16),
                const SizedBox(width: 6),
                Text(value,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
