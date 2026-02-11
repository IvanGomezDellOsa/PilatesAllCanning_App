import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/booking.dart';

// --- PROVIDER para Bookings ---
final userBookingsProvider = FutureProvider.autoDispose
    .family<List<Booking>, String>((ref, userId) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/users/$userId/bookings');

  final List<dynamic> data = response.data;
  return data.map((json) {
    final gymClass = json['gym_class'];
    return Booking(
      bookingId: json['id'],
      classId: gymClass['id'],
      name: gymClass['name'],
      instructor: gymClass['instructor'] ?? 'Sin asignar',
      startTime: DateTime.parse(gymClass['start_time']),
      status: _parseStatus(json['status']),
    );
  }).toList();
});

// --- PROVIDER para Fixed Schedules ---
final userFixedSchedulesProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>((ref, userId) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/users/$userId/fixed-schedules');
  return List<Map<String, dynamic>>.from(response.data);
});

BookingStatus _parseStatus(String status) {
  switch (status) {
    case 'confirmed':
      return BookingStatus.confirmed;
    case 'cancelled':
      return BookingStatus.cancelled;
    default:
      return BookingStatus.none;
  }
}

String _dayOfWeekToSpanish(String day) {
  const map = {
    'MONDAY': 'Lunes',
    'TUESDAY': 'Martes',
    'WEDNESDAY': 'Miércoles',
    'THURSDAY': 'Jueves',
    'FRIDAY': 'Viernes',
    'SATURDAY': 'Sábado',
    'SUNDAY': 'Domingo',
  };
  return map[day.toUpperCase()] ?? day;
}

// --- SCREEN ---

class AdminUserBookingsScreen extends ConsumerStatefulWidget {
  final String userId;
  final String userName;

  const AdminUserBookingsScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  ConsumerState<AdminUserBookingsScreen> createState() =>
      _AdminUserBookingsScreenState();
}

class _AdminUserBookingsScreenState
    extends ConsumerState<AdminUserBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        toolbarHeight: 64,
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
        title: Column(
          children: [
            Text(
              'Reservas de Usuario',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    letterSpacing: -0.3,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              widget.userName,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(49),
          child: Column(
            children: [
              TabBar(
                controller: _tabController,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primary,
                labelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
                tabs: const [
                  Tab(text: 'Reservas'),
                  Tab(text: 'Canceladas'),
                  Tab(text: 'Turnos Fijos'),
                ],
              ),
              Container(height: 1, color: AppColors.divider),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ReservasTab(userId: widget.userId),
          _CanceladasTab(userId: widget.userId),
          _TurnosFijosTab(userId: widget.userId),
        ],
      ),
    );
  }
}

// ========== RESERVAS TAB ==========

class _ReservasTab extends ConsumerWidget {
  final String userId;

  const _ReservasTab({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(userBookingsProvider(userId));

    return bookingsAsync.when(
      data: (bookings) {
        final now = DateTime.now();
        final confirmedBookings =
            bookings.where((b) => b.status == BookingStatus.confirmed).toList();

        final futureBookings =
            confirmedBookings.where((b) => b.startTime.isAfter(now)).toList();
        final pastBookings =
            confirmedBookings.where((b) => b.startTime.isBefore(now)).toList();

        if (confirmedBookings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_busy,
                    size: 64,
                    color: AppColors.textSecondary.withValues(alpha: 0.3)),
                const SizedBox(height: 16),
                const Text(
                  'Sin reservas activas',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => ref.refresh(userBookingsProvider(userId)),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (futureBookings.isNotEmpty) ...[
                const _SectionTitle('Próximas'),
                const SizedBox(height: 12),
                ...futureBookings.map((b) => _BookingCard(booking: b)),
                const SizedBox(height: 24),
              ],
              if (pastBookings.isNotEmpty) ...[
                const _SectionTitle('Pasadas'),
                const SizedBox(height: 12),
                ...pastBookings
                    .map((b) => _BookingCard(booking: b, isPast: true)),
              ],
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text('Error: $err', style: const TextStyle(color: AppColors.error)),
          ],
        ),
      ),
    );
  }
}

// ========== CANCELADAS TAB ==========

class _CanceladasTab extends ConsumerWidget {
  final String userId;

  const _CanceladasTab({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(userBookingsProvider(userId));

    return bookingsAsync.when(
      data: (bookings) {
        final cancelledBookings =
            bookings.where((b) => b.status == BookingStatus.cancelled).toList();

        if (cancelledBookings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline,
                    size: 64, color: AppColors.success.withValues(alpha: 0.5)),
                const SizedBox(height: 16),
                const Text(
                  'Sin reservas canceladas',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => ref.refresh(userBookingsProvider(userId)),
          child: ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: cancelledBookings.length,
            itemBuilder: (context, index) {
              return _BookingCard(
                booking: cancelledBookings[index],
                isCancelled: true,
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }
}

// ========== TURNOS FIJOS TAB ==========

class _TurnosFijosTab extends ConsumerWidget {
  final String userId;

  const _TurnosFijosTab({required this.userId});

  Future<void> _deleteFixedSchedule(
      BuildContext context, WidgetRef ref, String scheduleId) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.delete('/fixed-schedules/$scheduleId');

      final bookingsCancelled = response.data['bookings_cancelled'] ?? 0;
      final creditsRefunded = response.data['credits_refunded'] ?? 0;

      messenger.showSnackBar(
        SnackBar(
          content: Text(
              'Turno fijo cancelado. $bookingsCancelled reservas canceladas, $creditsRefunded créditos reembolsados.'),
          backgroundColor: AppColors.success,
        ),
      );

      // Invalidar provider para refrescar
      ref.invalidate(userFixedSchedulesProvider(userId));
      ref.invalidate(userBookingsProvider(userId));
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error al cancelar: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schedulesAsync = ref.watch(userFixedSchedulesProvider(userId));

    return schedulesAsync.when(
      data: (schedules) {
        if (schedules.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_repeat,
                    size: 64,
                    color: AppColors.textSecondary.withValues(alpha: 0.3)),
                const SizedBox(height: 16),
                const Text(
                  'Sin turnos fijos asignados',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async =>
              ref.refresh(userFixedSchedulesProvider(userId)),
          child: ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: schedules.length,
            itemBuilder: (context, index) {
              final schedule = schedules[index];
              return _FixedScheduleCard(
                schedule: schedule,
                onDelete: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Cancelar Turno Fijo'),
                      content: const Text(
                        '¿Estás seguro? Se cancelarán todas las reservas futuras asociadas y se reembolsarán los créditos.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancelar'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.error),
                          child: const Text('Confirmar'),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true && context.mounted) {
                    await _deleteFixedSchedule(context, ref, schedule['id']);
                  }
                },
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }
}

// ========== WIDGETS ==========

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: AppColors.textSecondary,
        letterSpacing: 1.0,
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final Booking booking;
  final bool isPast;
  final bool isCancelled;

  const _BookingCard({
    required this.booking,
    this.isPast = false,
    this.isCancelled = false,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr =
        DateFormat('EEEE d MMM, HH:mm', 'es').format(booking.startTime);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isPast || isCancelled ? AppColors.background : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCancelled
              ? AppColors.error.withValues(alpha: 0.3)
              : AppColors.borderLight,
          width: 1.5,
        ),
        boxShadow: [
          if (!isPast && !isCancelled)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isCancelled
                    ? AppColors.error.withValues(alpha: 0.1)
                    : (isPast
                        ? AppColors.textSecondary.withValues(alpha: 0.1)
                        : AppColors.primary.withValues(alpha: 0.1)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isCancelled
                    ? Icons.cancel_outlined
                    : (isPast ? Icons.history : Icons.event),
                color: isCancelled
                    ? AppColors.error
                    : (isPast ? AppColors.textSecondary : AppColors.primary),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    booking.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isCancelled
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
                      decoration:
                          isCancelled ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dateStr.replaceFirst(dateStr[0], dateStr[0].toUpperCase()),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (booking.instructor.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      booking.instructor,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (isCancelled)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.3),
                  ),
                ),
                child: const Text(
                  'CANCELADA',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.error,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FixedScheduleCard extends StatelessWidget {
  final Map<String, dynamic> schedule;
  final VoidCallback onDelete;

  const _FixedScheduleCard({
    required this.schedule,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final daySpanish = _dayOfWeekToSpanish(schedule['day_of_week']);
    final time = schedule['start_time'].toString().substring(0, 5); // HH:MM

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.event_repeat,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    daySpanish,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    time,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              tooltip: 'Cancelar turno fijo',
            ),
          ],
        ),
      ),
    );
  }
}
