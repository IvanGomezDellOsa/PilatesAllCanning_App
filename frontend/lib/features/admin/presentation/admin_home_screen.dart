import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/gym_class.dart';
import '../../../models/user.dart';
import '../../../core/providers/providers.dart';
import '../../shared/widgets/common_widgets.dart';
import '../../../core/constants/app_constants.dart';

class AdminHomeScreen extends ConsumerStatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  ConsumerState<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends ConsumerState<AdminHomeScreen> {
  DateTime _selectedDate = DateTime.now();
  final ScrollController _dateScrollController = ScrollController();
  final int _currentNavIndex = 0;

  @override
  void dispose() {
    _dateScrollController.dispose();
    super.dispose();
  }

  List<DateTime> _generateWeekDates() {
    final today = DateTime.now();
    return List.generate(30, (index) => today.add(Duration(days: index)));
  }

  void _onNavTap(int index) {
    if (index == _currentNavIndex) return;

    switch (index) {
      case 0:
        // Ya estamos en Agenda
        break;
      case 1:
        context.push('/admin/users');
        break;
      case 2:
        context.push('/admin/announcements');
        break;
      case 3:
        context.push('/admin/settings');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final selectedDateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final classesAsync = ref.watch(gymClassesProvider(selectedDateStr));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        toolbarHeight: 64,
        automaticallyImplyLeading: false,
        centerTitle: true,
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          'Pilates en All Canning (Admin)',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 19,
                letterSpacing: -0.3,
              ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: AppColors.divider,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildDateStrip(screenWidth),
          Container(height: 1, color: AppColors.divider),
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

                if (classes.isEmpty) {
                  return EmptyState(
                    icon: Icons.event_busy,
                    title: 'No hay clases programadas',
                    subtitle: 'Toca el botón + para crear una clase',
                    action: ElevatedButton.icon(
                      onPressed: () => _showCreateClassDialog(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Crear Clase'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFA67777),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                      ),
                    ),
                  );
                } else if (visibleClasses.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.event_available,
                            size: 64, color: AppColors.textSecondary),
                        const SizedBox(height: 16),
                        Text(
                          'No hay más clases por hoy',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => _showCreateClassDialog(context),
                          icon: const Icon(Icons.add, color: Colors.white),
                          label: const Text('Crear Clase'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFA67777),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
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
                          return _AdminClassCard(
                            gymClass: visibleClasses[index],
                            onTap: () => _showClassDetailDialog(
                              context,
                              visibleClasses[index],
                            ),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateClassDialog(context),
        backgroundColor: const Color(0xFFA67777),
        elevation: 6,
        icon: const Icon(Icons.add, size: 28),
        label: const Text(
          'Nueva Clase',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
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
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined),
              selectedIcon: Icon(Icons.calendar_month),
              label: 'Agenda',
            ),
            NavigationDestination(
              icon: Icon(Icons.people_outline),
              selectedIcon: Icon(Icons.people),
              label: 'Usuarios',
            ),
            NavigationDestination(
              icon: Icon(Icons.campaign_outlined),
              selectedIcon: Icon(Icons.campaign),
              label: 'Novedades',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: 'Ajustes',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateStrip(double screenWidth) {
    final dates = _generateWeekDates();
    final today = DateTime.now();
    final visibleDatesCount =
        screenWidth > 1200 ? 14 : (screenWidth > 600 ? 21 : 30);
    final visibleDates = dates.take(visibleDatesCount).toList();
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

                return GestureDetector(
                  onTap: () {
                    if (isHoliday) {
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Día Feriado: No se pueden programar clases'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                      return;
                    }
                    setState(() => _selectedDate = date);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    width: dateWidth,
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    decoration: BoxDecoration(
                      color: isHoliday
                          ? Colors.blue.shade700
                          : (isSelected
                              ? const Color(0xFFA67777)
                              : AppColors.background),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: const Color(0xFFA67777)
                                    .withValues(alpha: 0.4),
                                blurRadius: 18,
                                offset: const Offset(0, 6),
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
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
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _showCreateClassDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _CreateClassDialog(date: _selectedDate),
    );
  }

  void _showClassDetailDialog(BuildContext context, GymClass gymClass) {
    showDialog(
      context: context,
      builder: (context) => _ClassDetailDialog(
        gymClass: gymClass,
        onRefresh: () {
          // Invalidate current date to force UI update (slots count)
          final selectedDateStr =
              DateFormat('yyyy-MM-dd').format(_selectedDate);
          ref.invalidate(gymClassesProvider(selectedDateStr));

          // Invalidate all family for consistency
          ref.invalidate(gymClassesProvider);
        },
      ),
    );
  }
}

// ========== ADMIN CLASS CARD ==========

class _AdminClassCard extends StatelessWidget {
  final GymClass gymClass;
  final VoidCallback onTap;
  final bool isFirst;

  const _AdminClassCard({
    required this.gymClass,
    required this.onTap,
    this.isFirst = false,
  });

  @override
  Widget build(BuildContext context) {
    final occupancyPercentage =
        (gymClass.confirmedCount / gymClass.maxSlots * 100).round();
    final isFull = gymClass.confirmedCount >= gymClass.maxSlots;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
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
          child: Row(
            children: [
              // Hora
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                decoration: BoxDecoration(
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

              // Info
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
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.person,
                            size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 6),
                        Text(
                          gymClass.instructor,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Ocupación
              Column(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: (isFull ? AppColors.error : AppColors.success)
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: (isFull ? AppColors.error : AppColors.success)
                            .withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      '${gymClass.confirmedCount}/${gymClass.maxSlots}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: isFull ? AppColors.error : AppColors.success,
                        height: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$occupancyPercentage%',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),

              const SizedBox(width: 12),
              const Icon(
                Icons.chevron_right,
                color: AppColors.textSecondary,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ========== CREATE CLASS DIALOG ==========

class _CreateClassDialog extends ConsumerStatefulWidget {
  final DateTime date;
  const _CreateClassDialog({required this.date});

  @override
  ConsumerState<_CreateClassDialog> createState() => _CreateClassDialogState();
}

class _CreateClassDialogState extends ConsumerState<_CreateClassDialog> {
  final _formKey = GlobalKey<FormState>();
  String _name = 'Clase';
  String? _instructor;
  TimeOfDay _time = const TimeOfDay(hour: 9, minute: 0);
  int _maxSlots = 8;
  // ignore: prefer_final_fields
  int _duration = 60;
  bool _isRecurring = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final instructorsAsync = ref.watch(allInstructorsProvider);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        'Nueva Clase',
        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 22),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: _name,
                decoration: const InputDecoration(labelText: 'Nombre'),
                onChanged: (value) => _name = value,
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () async {
                  final TimeOfDay? picked = await showTimePicker(
                    context: context,
                    initialTime: _time,
                  );
                  if (picked != null) setState(() => _time = picked);
                },
                child: AbsorbPointer(
                  child: TextFormField(
                    decoration: const InputDecoration(labelText: 'Hora'),
                    controller:
                        TextEditingController(text: _time.format(context)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              instructorsAsync.when(
                data: (instructors) => DropdownButtonFormField<String>(
                  // ignore: deprecated_member_use
                  value: _instructor ??
                      (instructors.isNotEmpty ? instructors.first.name : null),
                  items: instructors
                      .map((i) =>
                          DropdownMenuItem(value: i.name, child: Text(i.name)))
                      .toList(),
                  onChanged: (val) => setState(() => _instructor = val),
                  decoration: const InputDecoration(labelText: 'Instructor'),
                ),
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('Error: $e'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _maxSlots.toString(),
                decoration: const InputDecoration(labelText: 'Cupos'),
                keyboardType: TextInputType.number,
                onChanged: (val) => _maxSlots = int.tryParse(val) ?? 8,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                  title: const Text('Semanal (12 sem)'),
                  value: _isRecurring,
                  onChanged: (v) => setState(() => _isRecurring = v)),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: _isLoading ? null : _createClass,
          child: _isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text('Crear'),
        )
      ],
    );
  }

  Future<void> _createClass() async {
    setState(() => _isLoading = true);
    try {
      final startTime = DateTime(widget.date.year, widget.date.month,
          widget.date.day, _time.hour, _time.minute);

      await ref.read(gymClassRepositoryProvider).createGymClass(
            name: _name,
            instructor: _instructor ?? 'Instructor',
            startTime: startTime,
            maxSlots: _maxSlots,
            durationMinutes: _duration,
            recurrence: _isRecurring,
          );

      if (mounted) {
        Navigator.pop(context);

        // Invalidate specific date to ensure UI updates immediately
        final dateStr = DateFormat('yyyy-MM-dd').format(widget.date);
        ref.invalidate(gymClassesProvider(dateStr));

        // Also invalidate generic to be safe for other dates
        ref.invalidate(gymClassesProvider);

        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Clase Creada')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _isLoading = false);
      }
    }
  }
}

// ========== CLASS DETAIL DIALOG ==========

class _ClassDetailDialog extends ConsumerStatefulWidget {
  final GymClass gymClass;
  final VoidCallback onRefresh;

  const _ClassDetailDialog({required this.gymClass, required this.onRefresh});

  @override
  ConsumerState<_ClassDetailDialog> createState() => _ClassDetailDialogState();
}

class _ClassDetailDialogState extends ConsumerState<_ClassDetailDialog> {
  GymClassDetail? _detail;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    try {
      final data = await ref
          .read(gymClassRepositoryProvider)
          .getClassDetail(widget.gymClass.id);
      if (mounted) {
        setState(() {
          _detail = data;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deleteClass(bool series) async {
    try {
      await ref
          .read(gymClassRepositoryProvider)
          .deleteGymClass(widget.gymClass.id, cancelSeries: series);
      if (mounted) {
        Navigator.pop(context);
        Navigator.pop(context); // Close confirmation if open
        widget.onRefresh();
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Clase Eliminada')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const AlertDialog(
          content: SizedBox(
              height: 100, child: Center(child: CircularProgressIndicator())));
    }

    // If error or null
    if (_detail == null) {
      return const AlertDialog(content: Text("Error cargando detalles"));
    }

    final students = _detail!.bookings;
    final gymClass = widget.gymClass.copyWith(
      confirmedCount: _detail!.confirmedCount,
    );

    Future<void> funcCancelBooking(String bookingId, String userName) async {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Cancelar reserva'),
          content: Text(
              '¿Cancelar la reserva de $userName? Se devolverá el crédito.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('No')),
            TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Sí', style: TextStyle(color: Colors.red))),
          ],
        ),
      );

      if (confirm == true) {
        try {
          await ref
              .read(gymClassRepositoryProvider)
              .adminCancelBooking(bookingId);
          if (!context.mounted) return;
          _loadDetail(); // Reload list
          widget.onRefresh(); // Refresh parent list
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Reserva cancelada')));
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text('Error: $e')));
          }
        }
      }
    }

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        gymClass.name,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 22),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InfoRow(
                icon: Icons.access_time,
                text: DateFormat('HH:mm').format(gymClass.startTime)),
            _InfoRow(icon: Icons.person, text: gymClass.instructor),
            _InfoRow(
                icon: Icons.people,
                text:
                    '${gymClass.confirmedCount}/${gymClass.maxSlots} inscriptos'),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Alumnos Inscriptos',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showManualBookDialog(context, ref),
                  icon: const Icon(Icons.person_add, size: 18),
                  label: const Text('Agregar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFA67777),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            students.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: Text(
                        'No hay alumnos inscritos',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  )
                : SizedBox(
                    height: 200, // Limit height for list
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: students.length,
                      itemBuilder: (ctx, i) {
                        final booking = students[i];
                        return ListTile(
                          dense: true,
                          leading: CircleAvatar(
                            backgroundColor:
                                AppColors.primary.withValues(alpha: 0.2),
                            child: Text(
                              (booking.userName ?? 'U')
                                  .substring(0, 1)
                                  .toUpperCase(),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ),
                          title: Text(booking.userName ?? 'Usuario'),
                          // subtitle: Text(booking.status.name), // Removed as per request
                          trailing: IconButton(
                            icon: const Icon(Icons.close,
                                size: 20, color: AppColors.error),
                            onPressed: () => funcCancelBooking(
                                booking.bookingId,
                                booking.userName ?? 'Usuario'),
                          ),
                        );
                      },
                    ),
                  ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cerrar'),
        ),
        // Edit button placeholder
        TextButton(
          onPressed: () async {
            // Close detail dialog
            if (mounted) Navigator.pop(context);
            // Show edit dialog
            if (mounted) {
              await showDialog(
                context: context,
                builder: (ctx) => _EditClassDialog(classData: widget.gymClass),
              );
            }
            // Refresh parent on return (if changed)
            widget.onRefresh();
          },
          child: const Text('Editar'),
        ),
        TextButton(
          onPressed: () {
            final isRecurring = widget.gymClass.recurrenceGroup != null;
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Cancelar Clase'),
                content: Text(isRecurring
                    ? 'Esta clase es parte de una serie. ¿Qué deseas eliminar?'
                    : '¿Deseas cancelar esta clase? Esta acción no se puede deshacer.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Volver'),
                  ),
                  if (isRecurring)
                    TextButton(
                      onPressed: () => _deleteClass(true),
                      child: const Text('Toda la serie',
                          style: TextStyle(color: AppColors.error)),
                    ),
                  TextButton(
                    onPressed: () => _deleteClass(false),
                    child: Text(isRecurring ? 'Solo esta' : 'Sí, cancelar',
                        style: const TextStyle(color: AppColors.error)),
                  ),
                ],
              ),
            );
          },
          child: const Text('Cancelar Clase',
              style: TextStyle(color: AppColors.error)),
        ),
      ],
    );
  }

  void _showManualBookDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => _ManualBookDialog(
        gymClass: widget.gymClass,
        onSuccess: () {
          _loadDetail();
          widget.onRefresh();
        },
      ),
    );
  }
}

// ========== MANUAL BOOK DIALOG ==========

class _ManualBookDialog extends ConsumerStatefulWidget {
  final GymClass gymClass;
  final VoidCallback onSuccess;

  const _ManualBookDialog({required this.gymClass, required this.onSuccess});

  @override
  ConsumerState<_ManualBookDialog> createState() => _ManualBookDialogState();
}

class _ManualBookDialogState extends ConsumerState<_ManualBookDialog> {
  bool _isNewUser = false; // false = Buscar Usuario | true = Nuevo/Sombra

  // Modo A: Usuario existente
  User? _selectedUser;
  final _scrollController = ScrollController();

  // Modo B: Usuario nuevo/sombra
  final _fullNameController = TextEditingController();
  final _dniController = TextEditingController();
  bool _isTrial = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _fullNameController.dispose();
    _dniController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(usersSearchProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        'Inscribir Alumno',
        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 22),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Toggle entre modos
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isNewUser = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: !_isNewUser
                                ? const Color(0xFFA67777)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Buscar Usuario',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: !_isNewUser
                                  ? Colors.white
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isNewUser = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _isNewUser
                                ? const Color(0xFFA67777)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Usuario no registrado',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: _isNewUser
                                  ? Colors.white
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Contenido según modo
              if (!_isNewUser) _buildSearchUserMode() else _buildNewUserMode(),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFA67777),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
              : Text(_isNewUser ? 'Crear y Reservar' : 'Confirmar'),
        ),
      ],
    );
  }

  Widget _buildSearchUserMode() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          decoration: InputDecoration(
            hintText: 'Buscar por nombre o DNI...',
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          onChanged: (value) {
            ref.read(usersSearchProvider.notifier).onSearchChanged(value);
          },
        ),
        const SizedBox(height: 16),
        SizedBox(
            height: 300,
            child: Consumer(builder: (ctx, ref, _) {
              final searchState = ref.watch(usersSearchProvider);
              final users = searchState.users;

              if (searchState.isLoading && users.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              if (users.isEmpty && !searchState.isLoading) {
                return const Center(
                  child: Text(
                    'No se encontraron usuarios',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                );
              }

              return ListView.builder(
                controller: _scrollController,
                itemCount: users.length +
                    (searchState.isLoading && users.isNotEmpty ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == users.length) {
                    return const Center(
                        child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(),
                    ));
                  }
                  final user = users[index];
                  final isSelected = _selectedUser?.id == user.id;

                  return ListTile(
                    selected: isSelected,
                    selectedTileColor: AppColors.primary.withValues(alpha: 0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    leading: CircleAvatar(
                      backgroundColor: isSelected
                          ? AppColors.primary
                          : AppColors.primary.withValues(alpha: 0.2),
                      child: Text(
                        user.fullName?.substring(0, 1).toUpperCase() ?? 'U',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color:
                              isSelected ? Colors.white : AppColors.primaryDark,
                        ),
                      ),
                    ),
                    title: Text(
                      user.fullName ?? 'Usuario',
                      style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w600,
                      ),
                    ),
                    subtitle: Text('DNI: ${user.dni ?? 'N/A'}'),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle,
                            color: AppColors.primary)
                        : null,
                    onTap: () {
                      setState(() {
                        _selectedUser = user;
                      });
                    },
                  );
                },
              );
            })),
      ],
    );
  }

  Widget _buildNewUserMode() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _fullNameController,
          decoration: InputDecoration(
            labelText: 'Nombre Completo',
            prefixIcon: const Icon(Icons.person_outline),
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _dniController,
          decoration: InputDecoration(
            labelText: 'DNI',
            prefixIcon: const Icon(Icons.badge_outlined),
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          keyboardType: TextInputType.number,
          // Removed standard import dependency for simplicity if not present
          // inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.warning.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.help_outline,
                    color: AppColors.warning,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      '¿Es una clase de prueba?',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  Switch(
                    value: _isTrial,
                    onChanged: (value) => setState(() => _isTrial = value),
                    activeThumbColor: AppColors.warning,
                  ),
                ],
              ),
              if (_isTrial) ...[
                const SizedBox(height: 8),
                const Text(
                  'Los usuarios de prueba no podrán reservar ni cancelar clases desde la app.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  void _handleSubmit() async {
    setState(() => _isLoading = true);
    try {
      if (!_isNewUser) {
        // Modo A: Usuario existente
        final user = _selectedUser;
        if (user == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Selecciona un usuario'),
                backgroundColor: AppColors.error,
              ),
            );
          }
          setState(() => _isLoading = false);
          return;
        }

        await ref.read(gymClassRepositoryProvider).manualBook(
              classId: widget.gymClass.id,
              userId: user.id,
              isTrial: _isTrial, // Optional?
            );

        widget.onSuccess();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${user.fullName} inscrito correctamente'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.pop(context);
        }
      } else {
        // Modo B: Nuevo/Sombra
        final fullName = _fullNameController.text.trim();
        final dni = _dniController.text.trim();

        if (fullName.isEmpty || dni.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Completa todos los campos'),
                backgroundColor: AppColors.error,
              ),
            );
          }
          setState(() => _isLoading = false);
          return;
        }

        await ref.read(gymClassRepositoryProvider).manualBook(
              classId: widget.gymClass.id,
              dni: dni,
              fullName: fullName,
              isTrial: _isTrial,
            );

        widget.onSuccess();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$fullName creado e inscrito correctamente'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 15)),
        ],
      ),
    );
  }
}

// ========== EDIT CLASS DIALOG ==========

class _EditClassDialog extends ConsumerStatefulWidget {
  final GymClass classData;
  const _EditClassDialog({required this.classData});

  @override
  ConsumerState<_EditClassDialog> createState() => _EditClassDialogState();
}

class _EditClassDialogState extends ConsumerState<_EditClassDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  late String _instructor;
  late int _maxSlots;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _name = widget.classData.name;
    _instructor = widget.classData.instructor;
    _maxSlots = widget.classData.maxSlots;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isLoading = true);

    try {
      await ref.read(gymClassRepositoryProvider).updateGymClass(
            classId: widget.classData.id,
            name: _name,
            instructor: _instructor,
            maxSlots: _maxSlots,
          );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Clase actualizada')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final instructorsAsync = ref.watch(allInstructorsProvider);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Editar Clase',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
      // NOTE: Start Time editing is intentionally disabled.
      // Changing start time causes complex conflicts with Fixed Schedules (Auto-booking).
      // Standard procedure is to Cancel and Re-create the class if the time changes.
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: _name,
                style: const TextStyle(fontSize: 18), // +Size
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  labelStyle: TextStyle(fontSize: 18), // +Size
                  contentPadding: EdgeInsets.symmetric(
                      horizontal: 16, vertical: 16), // +Padding
                ),
                onSaved: (v) => _name = v ?? '',
              ),
              const SizedBox(height: 20), // +Space
              instructorsAsync.when(
                data: (instructors) {
                  final names = instructors.map((i) => i.name).toList();
                  if (_instructor.isNotEmpty && !names.contains(_instructor)) {
                    names.add(_instructor);
                  }

                  return DropdownButtonFormField<String>(
                    // ignore: deprecated_member_use
                    value: _instructor,
                    style: const TextStyle(
                        fontSize: 18, color: Colors.black), // +Size
                    decoration: const InputDecoration(
                      labelText: 'Instructor',
                      labelStyle: TextStyle(fontSize: 18), // +Size
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16), // +Padding
                    ),
                    items: names
                        .map((i) => DropdownMenuItem(value: i, child: Text(i)))
                        .toList(),
                    onChanged: (v) => setState(() => _instructor = v!),
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('Error: $e',
                    style: const TextStyle(color: Colors.red)),
              ),
              const SizedBox(height: 20), // +Space
              TextFormField(
                initialValue: _maxSlots.toString(),
                style: const TextStyle(fontSize: 18), // +Size
                decoration: const InputDecoration(
                  labelText: 'Cupos',
                  labelStyle: TextStyle(fontSize: 18), // +Size
                  contentPadding: EdgeInsets.symmetric(
                      horizontal: 16, vertical: 16), // +Padding
                ),
                keyboardType: TextInputType.number,
                onSaved: (v) => _maxSlots = int.tryParse(v ?? '') ?? 8,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: _isLoading ? null : _save,
          style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFA67777)),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('Guardar'),
        ),
      ],
    );
  }
}
