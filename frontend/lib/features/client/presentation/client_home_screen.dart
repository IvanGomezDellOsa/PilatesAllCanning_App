import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/gym_class.dart';
import '../../../core/providers/providers.dart';
import '../providers/client_providers.dart';
import '../../shared/widgets/common_widgets.dart';
import '../../../models/booking.dart';
import '../../../core/constants/app_constants.dart';
import 'widgets/feedback_dialog.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  DateTime _selectedDate = DateTime.now();
  final ScrollController _dateScrollController = ScrollController();
  final int _currentNavIndex = 0;

  @override
  void initState() {
    super.initState();
    // Default initialization
  }

  @override
  void dispose() {
    _dateScrollController.dispose();
    super.dispose();
  }

  List<DateTime> _generateWeekDates() {
    final today = DateTime.now();
    // 14 días fijos
    return List.generate(14, (index) => today.add(Duration(days: index)));
  }

  bool _isDateSelectable(DateTime date) {
    final now = DateTime.now();

    // Si es hoy, siempre se puede
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return true;
    }

    // Si estamos en domingo, permitimos hasta el domingo de la OTRA semana.
    // Si es lunes-sabado, permitimos solo hasta este domingo.
    // weekday: 1=Mon, ..., 7=Sun

    int daysUntilNextSunday;
    if (now.weekday == DateTime.sunday) {
      // Estamos en domingo -> habilitamos semana siguiente completa (7 dias + lo que queda de hoy)
      // Ejemplo: Hoy Domingo 10. Proximo domingo es 17.
      daysUntilNextSunday = 7;
    } else {
      // Estamos Lunes (1) .. Sabado (6).
      // Dias hasta el domingo de esta semana.
      // E.g. Lunes(1) -> 7 - 1 = 6 dias hasta domingo.
      daysUntilNextSunday = DateTime.sunday - now.weekday;
    }

    // Calculamos la fecha límite (inclusive)
    // Usamos el 'final del día' para asegurar comparaciones correctas si hay horas
    final limitDate = now.add(Duration(days: daysUntilNextSunday));
    final limitWithTime = DateTime(
      limitDate.year,
      limitDate.month,
      limitDate.day,
      23,
      59,
      59,
    );

    return date.isBefore(limitWithTime);
  }

  void _showRestrictedMessage() {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.white, size: 20),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'La próxima semana se habilita el domingo.',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.textPrimary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.only(bottom: 80, left: 20, right: 20),
      ),
    );
  }

  void _onNavTap(int index) {
    if (index == _currentNavIndex) return;

    switch (index) {
      case 0:
        // Ya estamos en Home
        break;
      case 1:
        context.push('/client/my-classes');
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
    final selectedDateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final classesAsync = ref.watch(gymClassesProvider(selectedDateStr));
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
          'Pilates en All Canning',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 19,
                letterSpacing: -0.3,
              ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.divider),
        ),
      ),
      body: Column(
        children: [
          // Calendario Horizontal adaptado por breakpoint
          _buildDateStrip(screenWidth),

          // Divider sutil
          Container(height: 1, color: AppColors.divider),

          // Lista de Clases con ancho máximo en desktop
          Expanded(
            child: classesAsync.when(
              data: (classes) {
                // Filtrar clases pasadas si es el día de hoy
                final now = DateTime.now();
                final isToday =
                    DateTime.parse(selectedDateStr).year == now.year &&
                        DateTime.parse(selectedDateStr).month == now.month &&
                        DateTime.parse(selectedDateStr).day == now.day;

                final visibleClasses = isToday
                    ? classes.where((c) => c.startTime.isAfter(now)).toList()
                    : classes;

                if (visibleClasses.isEmpty) {
                  return const EmptyState(
                    icon: Icons.event_busy,
                    title: 'No hay clases disponibles',
                    subtitle: 'Selecciona otro día o revisa más tarde',
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(gymClassesProvider(selectedDateStr));
                  },
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 800),
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 90),
                        itemCount: visibleClasses.length,
                        itemBuilder: (context, index) {
                          return _ClassCard(
                            gymClass: visibleClasses[index],
                            onBook: () =>
                                _handleBookClass(visibleClasses[index]),
                            isFirst: index == 0,
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
              loading: () =>
                  const LoadingIndicator(message: 'Cargando clases...'),
              error: (error, _) => ErrorView(
                message: 'Error al cargar las clases',
                onRetry: () =>
                    ref.invalidate(gymClassesProvider(selectedDateStr)),
              ),
            ),
          ),
        ],
      ),
      // Bottom Navigation Bar con 4 opciones
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
                    backgroundColor: const Color(0xFFA67777), // Primary color
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

  Widget _buildDateStrip(double screenWidth) {
    final dates = _generateWeekDates();
    final today = DateTime.now();

    // Responsive: mostramos los 14 dias generados (scroll si es necesario)
    final visibleDates = dates;

    // Responsive: reducir tamaño en desktop
    final isDesktop = screenWidth > 1200;
    final dateWidth = isDesktop ? 52.0 : 62.0;
    final fontSize = isDesktop ? 24.0 : 26.0;
    final dayFontSize = isDesktop ? 10.0 : 11.0;

    return Container(
      height: 92,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(color: AppColors.surface),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: ShaderMask(
            shaderCallback: (Rect bounds) {
              return LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  AppColors.surface,
                  AppColors.surface.withValues(alpha: 0),
                  AppColors.surface.withValues(alpha: 0),
                  AppColors.surface,
                ],
                stops: const [0.0, 0.05, 0.95, 1.0],
              ).createShader(bounds);
            },
            blendMode: BlendMode.dstOut,
            child: ListView.builder(
              controller: _dateScrollController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: visibleDates.length,
              itemBuilder: (context, index) {
                final date = visibleDates[index];

                final isSelected = date.day == _selectedDate.day &&
                    date.month == _selectedDate.month &&
                    date.year == _selectedDate.year;

                final isToday = date.day == today.day &&
                    date.month == today.month &&
                    date.year == today.year;

                final dateStr = DateFormat('yyyy-MM-dd').format(date);
                final isHoliday = AppConstants.holidays2026.contains(dateStr);

                final isSelectable = _isDateSelectable(date) && !isHoliday;

                return GestureDetector(
                  onTap: () {
                    if (isHoliday) {
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Día Feriado: No hay clases'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                      return;
                    }
                    if (isSelectable) {
                      setState(() => _selectedDate = date);
                    } else {
                      _showRestrictedMessage();
                    }
                  },
                  child: Opacity(
                    opacity:
                        isSelectable ? 1.0 : 0.4, // Visualmente deshabilitado
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      width: dateWidth,
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      decoration: BoxDecoration(
                        // JERARQUÍA TONAL: Día activo más intenso
                        color: isHoliday
                            ? Colors.blue.shade700 // HOLIDAY COLOR
                            : (isSelected
                                ? const Color(0xFFA67777)
                                : AppColors.background),
                        borderRadius: BorderRadius.circular(16),
                        // Sombra solo en seleccionado
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: const Color(
                                    0xFFA67777,
                                  ).withValues(alpha: 0.4),
                                  blurRadius: 18,
                                  offset: const Offset(0, 6),
                                  spreadRadius: 0,
                                ),
                              ]
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Día de la semana
                          Text(
                            DateFormat('EEE', 'es').format(date).toUpperCase(),
                            style: TextStyle(
                              fontSize: dayFontSize,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.textSecondary,
                              letterSpacing: 1,
                              height: 1,
                            ),
                          ),
                          const SizedBox(height: 6),
                          // Número del día
                          Text(
                            isHoliday ? 'FER' : date.day.toString(),
                            style: TextStyle(
                              fontSize: isHoliday ? 16 : fontSize,
                              fontWeight: FontWeight.w900,
                              color: (isSelected || isHoliday)
                                  ? Colors.white
                                  : AppColors.textPrimary,
                              height: 1,
                              letterSpacing: -0.5,
                            ),
                          ),
                          // Indicador "hoy"
                          if (isToday) ...[
                            const SizedBox(height: 6),
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFFA67777),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: (isSelected
                                            ? Colors.white
                                            : const Color(0xFFA67777))
                                        .withValues(alpha: 0.6),
                                    blurRadius: 6,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleBookClass(GymClass gymClass) async {
    try {
      await ref
          .read(bookClassControllerProvider.notifier)
          .bookClass(gymClass.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 22),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  '¡Reserva confirmada!',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 80),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );

      // Refrescar datos
      final selectedDateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      ref.invalidate(gymClassesProvider(selectedDateStr));
      ref.invalidate(userProfileProvider);
      ref.invalidate(myBookingsProvider);

      // FEEDBACK TRIGGER - Verificar con datos frescos
      Future.delayed(const Duration(seconds: 10), () async {
        if (!mounted) return;
        // Forzar refresh y esperar el resultado
        final freshUser = await ref.refresh(userProfileProvider.future);
        if (!freshUser.hasGivenFeedback && mounted) {
          showDialog(context: context, builder: (_) => const FeedbackDialog());
        }
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
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

// ========== CLASS CARD OPTIMIZADO RESPONSIVE ==========

class _ClassCard extends StatelessWidget {
  final GymClass gymClass;
  final VoidCallback onBook;
  final bool isFirst;

  const _ClassCard({
    required this.gymClass,
    required this.onBook,
    this.isFirst = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasSlots = gymClass.availableSlots > 0;
    final isBooked = gymClass.myStatus == BookingStatus.confirmed;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTabletOrDesktop = screenWidth > 600;

    return Container(
      margin: EdgeInsets.only(bottom: 18, top: isFirst ? 0 : 0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight, width: 1.5),
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
                // HORA - Jerarquía rebajada (no compite con CTA)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    // JERARQUÍA TONAL: Rosa más suave para info
                    color: AppColors.primary.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    DateFormat('HH:mm').format(gymClass.startTime),
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryDark,
                      letterSpacing: -0.8,
                      height: 1,
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Info clase
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        gymClass.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 19,
                              height: 1.2,
                              letterSpacing: -0.3,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.person,
                            size: 17,
                            color: AppColors.textPrimary.withValues(alpha: 0.8),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              gymClass.instructor,
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

            const SizedBox(height: 18),

            // Separador sutil
            Container(height: 1, color: AppColors.divider),

            const SizedBox(height: 18),

            // Layout responsive: Column en mobile, Row en desktop
            isTabletOrDesktop
                ? _buildDesktopLayout(hasSlots, isBooked)
                : _buildMobileLayout(hasSlots, isBooked),
          ],
        ),
      ),
    );
  }

  // Layout Mobile: Cupos arriba, botón abajo (full width)
  Widget _buildMobileLayout(bool hasSlots, bool isBooked) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Cupos
        _buildSlotsInfo(hasSlots),
        const SizedBox(height: 14),
        // Botón CTA con ancho limitado centrado
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280),
            child: SizedBox(
              width: double.infinity,
              child: _buildCTAButton(hasSlots, isBooked),
            ),
          ),
        ),
      ],
    );
  }

  // Layout Desktop: Todo en una fila
  Widget _buildDesktopLayout(bool hasSlots, bool isBooked) {
    return Row(
      children: [
        // Cupos
        Expanded(child: _buildSlotsInfo(hasSlots)),
        const SizedBox(width: 14),
        // Botón CTA con ancho fijo
        SizedBox(width: 200, child: _buildCTAButton(hasSlots, isBooked)),
      ],
    );
  }

  Widget _buildSlotsInfo(bool hasSlots) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: (hasSlots ? AppColors.success : AppColors.error).withValues(
          alpha: 0.12,
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: (hasSlots ? AppColors.success : AppColors.error).withValues(
            alpha: 0.4,
          ),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasSlots ? Icons.check_circle : Icons.cancel,
            size: 20,
            color: hasSlots ? AppColors.success : AppColors.error,
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                hasSlots
                    ? '${gymClass.availableSlots} ${gymClass.availableSlots == 1 ? 'lugar' : 'lugares'}'
                    : 'Clase llena',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: hasSlots ? AppColors.success : AppColors.error,
                  height: 1.1,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                hasSlots ? 'disponibles' : 'sin cupos',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: (hasSlots ? AppColors.success : AppColors.error)
                      .withValues(alpha: 0.8),
                  height: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCTAButton(bool hasSlots, bool isBooked) {
    return SizedBox(
      height: 56,
      child: isBooked
          ? Container(
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.success.withValues(alpha: 0.5),
                  width: 2,
                ),
              ),
              child: const Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 21,
                      color: AppColors.success,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Reservada',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.success,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : ElevatedButton(
              onPressed: hasSlots ? onBook : null,
              style: ElevatedButton.styleFrom(
                // JERARQUÍA TONAL: Color más intenso para CTA principal
                backgroundColor: hasSlots
                    ? const Color(0xFFA67777) // Más saturado
                    : AppColors.textHint.withValues(alpha: 0.5),
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.textHint.withValues(
                  alpha: 0.5,
                ),
                disabledForegroundColor: Colors.white.withValues(alpha: 0.6),
                elevation: hasSlots ? 8 : 0,
                shadowColor: hasSlots
                    ? const Color(0xFFA67777).withValues(alpha: 0.5)
                    : Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                hasSlots ? 'Reservar' : 'Sin cupos',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                ),
              ),
            ),
    );
  }
}
