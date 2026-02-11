import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/booking.dart';
import '../../../core/providers/providers.dart';
import '../providers/client_providers.dart';
import '../../shared/widgets/common_widgets.dart';
import 'widgets/feedback_dialog.dart';

class MyClassesScreen extends ConsumerStatefulWidget {
  const MyClassesScreen({super.key});

  @override
  ConsumerState<MyClassesScreen> createState() => _MyClassesScreenState();
}

class _MyClassesScreenState extends ConsumerState<MyClassesScreen>
    with SingleTickerProviderStateMixin {
  final int _currentNavIndex = 1;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onNavTap(int index) {
    if (index == _currentNavIndex) return;

    switch (index) {
      case 0:
        context.go('/client');
        break;
      case 1:
        break;
      case 2:
        context.push('/client/profile');
        break;
      case 3:
        context.push('/client/announcements');
        break;
      case 4:
        context.push('/client/info');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(myBookingsProvider);
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        toolbarHeight: 64,
        automaticallyImplyLeading: false,
        centerTitle: true,
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          'Mis Clases',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 19,
                letterSpacing: -0.3,
              ),
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
                  Tab(text: 'Próximas'),
                  Tab(text: 'Pasadas y Canceladas'),
                ],
              ),
              Container(height: 1, color: AppColors.divider),
            ],
          ),
        ),
      ),
      body: bookingsAsync.when(
        data: (bookings) {
          if (bookings.isEmpty) {
            return const EmptyState(
              icon: Icons.event_available,
              title: 'No tienes reservas',
              subtitle: 'Reserva tu primera clase desde la pantalla principal',
            );
          }

          final now = DateTime.now();

          // Próximas: confirmadas y futuras, ordenadas ascendente (más próxima primero)
          final upcoming = bookings
              .where((b) =>
                  b.status == BookingStatus.confirmed &&
                  b.startTime.isAfter(now))
              .toList()
            ..sort((a, b) => a.startTime.compareTo(b.startTime));

          // Pasadas y canceladas, ordenadas descendente (más reciente primero)
          final pastAndCancelled = bookings
              .where((b) =>
                  b.startTime.isBefore(now) ||
                  b.status == BookingStatus.cancelled)
              .toList()
            ..sort((a, b) => b.startTime.compareTo(a.startTime));

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(myBookingsProvider);
            },
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Próximas
                _buildUpcomingTab(upcoming, screenWidth),
                // Tab 2: Pasadas y Canceladas
                _buildPastAndCancelledTab(pastAndCancelled, screenWidth),
              ],
            ),
          );
        },
        loading: () => const LoadingIndicator(message: 'Cargando reservas...'),
        error: (error, _) => ErrorView(
          message: 'Error al cargar las reservas',
          onRetry: () => ref.invalidate(myBookingsProvider),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _currentNavIndex,
          onDestinationSelected: _onNavTap,
          elevation: 0,
          height: 68,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          backgroundColor: AppColors.surface,
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Reservar',
            ),
            const NavigationDestination(
              icon: Icon(Icons.event_note_outlined),
              selectedIcon: Icon(Icons.event_note_rounded),
              label: 'Mis Clases',
            ),
            const NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Perfil',
            ),
            NavigationDestination(
              icon: Consumer(
                builder: (context, ref, child) {
                  final unreadCount = ref.watch(unreadAnnouncementsProvider);
                  return Badge(
                    label: Text(unreadCount.toString()),
                    isLabelVisible: unreadCount > 0,
                    backgroundColor: const Color(0xFFA67777),
                    child: const Icon(Icons.campaign_outlined),
                  );
                },
              ),
              selectedIcon: Consumer(
                builder: (context, ref, child) {
                  final unreadCount = ref.watch(unreadAnnouncementsProvider);
                  return Badge(
                    label: Text(unreadCount.toString()),
                    isLabelVisible: unreadCount > 0,
                    backgroundColor: const Color(0xFFA67777),
                    child: const Icon(Icons.campaign),
                  );
                },
              ),
              label: 'Novedades',
            ),
            const NavigationDestination(
              icon: Icon(Icons.info_outline),
              selectedIcon: Icon(Icons.info_rounded),
              label: 'Info',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingTab(List<Booking> upcoming, double screenWidth) {
    if (upcoming.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_available,
                size: 64,
                color: AppColors.textSecondary.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            const Text(
              'No tienes clases próximas',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Reserva una clase desde Reservar',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 90),
          itemCount: upcoming.length,
          itemBuilder: (context, index) {
            return _BookingCard(
              booking: upcoming[index],
              onCancel: () =>
                  _handleCancelBooking(context, ref, upcoming[index]),
              screenWidth: screenWidth,
            );
          },
        ),
      ),
    );
  }

  Widget _buildPastAndCancelledTab(
      List<Booking> pastAndCancelled, double screenWidth) {
    if (pastAndCancelled.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history,
                size: 64,
                color: AppColors.textSecondary.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            const Text(
              'No hay historial de clases',
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

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 90),
          itemCount: pastAndCancelled.length,
          itemBuilder: (context, index) {
            return _BookingCard(
              booking: pastAndCancelled[index],
              isPast: true,
              screenWidth: screenWidth,
            );
          },
        ),
      ),
    );
  }

  Future<void> _handleCancelBooking(
    BuildContext context,
    WidgetRef ref,
    Booking booking,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Cancelar Reserva',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Deseas cancelar tu reserva para ${booking.name}?',
              style: const TextStyle(
                fontSize: 16,
                height: 1.4,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text(
              'No, mantener',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text(
              'Sí, cancelar',
              style: TextStyle(
                color: AppColors.error,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      final response = await ref
          .read(cancelBookingControllerProvider.notifier)
          .cancelBooking(booking.bookingId);

      if (!mounted) return;

      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                response.refunded ? Icons.check_circle : Icons.info_outline,
                color: Colors.white,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  response.message,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor:
              response.refunded ? AppColors.success : AppColors.warning,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 80),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );

      // Refrescar datos
      ref.invalidate(myBookingsProvider);
      ref.invalidate(userProfileProvider);
      ref.invalidate(gymClassesProvider);

      // FEEDBACK TRIGGER
      Future.delayed(const Duration(seconds: 10), () {
        if (!context.mounted) return;
        final user = ref.read(userProfileProvider).value;
        if (user != null && !user.hasGivenFeedback) {
          showDialog(
            context: context,
            builder: (_) => const FeedbackDialog(),
          );
        }
      });
    } catch (e) {
      if (!mounted) return;

      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Error: $e',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 80),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }
}

// ========== BOOKING CARD WIDGET ==========

class _BookingCard extends StatelessWidget {
  final Booking booking;
  final VoidCallback? onCancel;
  final bool isPast;
  final double screenWidth;

  const _BookingCard({
    required this.booking,
    this.onCancel,
    this.isPast = false,
    required this.screenWidth,
  });

  @override
  Widget build(BuildContext context) {
    final isCancelled = booking.status == BookingStatus.cancelled;
    final isTabletOrDesktop = screenWidth > 600;

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.borderLight,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Fecha
                Container(
                  width: 68,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isPast
                        ? AppColors.textHint.withValues(alpha: 0.15)
                        : const Color(0xFFA67777).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isPast
                          ? AppColors.textHint.withValues(alpha: 0.3)
                          : const Color(0xFFA67777).withValues(alpha: 0.35),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        DateFormat('dd').format(booking.startTime),
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: isPast
                              ? AppColors.textSecondary
                              : const Color(0xFFA67777),
                          height: 1,
                          letterSpacing: -0.8,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('MMM', 'es')
                            .format(booking.startTime)
                            .toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isPast
                              ? AppColors.textSecondary
                              : const Color(0xFFA67777),
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 16),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              booking.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 19,
                                    height: 1.2,
                                    letterSpacing: -0.3,
                                    color: isPast
                                        ? AppColors.textSecondary
                                        : AppColors.textPrimary,
                                  ),
                            ),
                          ),
                          if (isCancelled)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.error.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color:
                                      AppColors.error.withValues(alpha: 0.35),
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.cancel_outlined,
                                    size: 14,
                                    color: AppColors.error,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Cancelada',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.error,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 16,
                            color: AppColors.textPrimary.withValues(alpha: 0.7),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            DateFormat('HH:mm').format(booking.startTime),
                            style:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                      color: AppColors.textPrimary,
                                    ),
                          ),
                          const SizedBox(width: 14),
                          Icon(
                            Icons.person,
                            size: 16,
                            color: AppColors.textPrimary.withValues(alpha: 0.7),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              booking.instructor,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                    color: AppColors.textPrimary,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Botón cancelar con responsive
            if (booking.canCancel && onCancel != null) ...[
              const SizedBox(height: 18),
              Container(
                height: 1,
                color: AppColors.divider,
              ),
              const SizedBox(height: 18),
              isTabletOrDesktop
                  ? Align(
                      alignment: Alignment.centerRight,
                      child: SizedBox(
                        width: 220,
                        height: 52,
                        child: _buildCancelButton(onCancel!),
                      ),
                    )
                  : Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 280),
                        child: SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: _buildCancelButton(onCancel!),
                        ),
                      ),
                    ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCancelButton(VoidCallback onCancel) {
    return OutlinedButton.icon(
      onPressed: onCancel,
      icon: const Icon(Icons.cancel_outlined, size: 20),
      label: const Text(
        'Cancelar Reserva',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.error,
        side: const BorderSide(
          color: AppColors.error,
          width: 2,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}
