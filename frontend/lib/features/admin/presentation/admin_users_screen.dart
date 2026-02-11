import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/user.dart';
import '../../shared/widgets/common_widgets.dart';
import '../../../core/providers/providers.dart';

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final int _currentNavIndex = 1;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onNavTap(int index) {
    if (index == _currentNavIndex) return;

    switch (index) {
      case 0:
        context.go('/admin');
        break;
      case 1:
        // Ya estamos en Usuarios
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
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o DNI...',
                prefixIcon:
                    const Icon(Icons.search, color: AppColors.textSecondary),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                          ref
                              .read(usersSearchProvider.notifier)
                              .onSearchChanged('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
                ref.read(usersSearchProvider.notifier).onSearchChanged(value);
              },
            ),
          ),
          Container(height: 1, color: AppColors.divider),
          Expanded(
            child: Consumer(builder: (context, ref, _) {
              final searchState = ref.watch(usersSearchProvider);
              final users = searchState.users;

              if (users.isEmpty && !searchState.isLoading) {
                return EmptyState(
                  icon: Icons.person_search,
                  title: _searchQuery.isEmpty
                      ? 'No hay usuarios registrados'
                      : 'No se encontraron usuarios',
                  subtitle: _searchQuery.isEmpty
                      ? 'Los usuarios aparecerán aquí cuando se registren'
                      : 'Intenta con otro término de búsqueda',
                );
              }

              return NotificationListener<ScrollNotification>(
                onNotification: (scrollInfo) {
                  if (!searchState.isLoading &&
                      searchState.hasMore &&
                      scrollInfo.metrics.pixels >=
                          scrollInfo.metrics.maxScrollExtent - 200) {
                    ref.read(usersSearchProvider.notifier).loadMore();
                  }
                  return false;
                },
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 90),
                      itemCount: users.length + (searchState.hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == users.length) {
                          return const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        return _UserCard(
                          user: users[index],
                          onRefresh: () =>
                              ref.read(usersSearchProvider.notifier).refresh(),
                        );
                      },
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateUserDialog(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text(
          'Crear Usuario',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 15,
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
          )),
    );
  }

  void _showCreateUserDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _CreateUserDialog(
        onUserCreated: () {
          // Just refresh the list, the controller handles the query state
          ref.read(usersSearchProvider.notifier).refresh();
        },
      ),
    );
  }
}

// ========== USER CARD ==========

class _UserCard extends ConsumerStatefulWidget {
  final User user;
  final VoidCallback onRefresh;

  const _UserCard({
    required this.user,
    required this.onRefresh,
  });

  @override
  ConsumerState<_UserCard> createState() => _UserCardState();
}

class _UserCardState extends ConsumerState<_UserCard> {
  bool _isBlocked = false;
  bool _isTrial = false;

  @override
  void initState() {
    super.initState();
    _updateState();
  }

  @override
  void didUpdateWidget(_UserCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.user != oldWidget.user) {
      _updateState();
    }
  }

  void _updateState() {
    _isBlocked = widget.user.disabled;
    _isTrial = widget.user.isTrial;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Opacity(
      opacity: _isBlocked ? 0.5 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 18),
        decoration: BoxDecoration(
          color: _isBlocked ? AppColors.background : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _isBlocked
                ? AppColors.error.withValues(alpha: 0.3)
                : AppColors.borderLight,
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
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                    child: Text(
                      widget.user.fullName?.substring(0, 1).toUpperCase() ??
                          'U',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                widget.user.fullName ?? 'Usuario',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 18,
                                      letterSpacing: -0.3,
                                    ),
                              ),
                            ),
                            // Badge "Usuario de Prueba"
                            if (widget.user.isTrial) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.warning.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: AppColors.warning
                                        .withValues(alpha: 0.4),
                                    width: 1,
                                  ),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.science_outlined,
                                        size: 12, color: AppColors.warning),
                                    SizedBox(width: 4),
                                    Text(
                                      'Prueba',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.warning,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'DNI: ${widget.user.dni ?? 'N/A'}',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  if (_isBlocked)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.block, size: 14, color: AppColors.error),
                          SizedBox(width: 4),
                          Text(
                            'Bloqueado',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  const Icon(Icons.email_outlined,
                      size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.user.email,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    onPressed: () => _showEditEmailDialog(context),
                    tooltip: 'Editar email',
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(8),
                  ),
                ],
              ),

              // ========== FEEDBACK STATUS BADGE ==========
              // Muestra el estado de feedback del usuario:
              // - Positivo (verde): usuario dio feedback positivo
              // - Negativo (rojo): usuario dio feedback negativo
              // - Sin respuesta (gris): usuario aún no respondió
              // Solo visible para usuarios reales (no admins, no placeholders)
              if (!widget.user.isAdmin &&
                  !widget.user.email.contains('@local.placeholder')) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      widget.user.hasGivenFeedback
                          ? (widget.user.feedbackSentiment == 'positive'
                              ? Icons.sentiment_satisfied_alt
                              : Icons.sentiment_dissatisfied)
                          : Icons.help_outline,
                      size: 16,
                      color: widget.user.hasGivenFeedback
                          ? (widget.user.feedbackSentiment == 'positive'
                              ? AppColors.success
                              : AppColors.error)
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.user.hasGivenFeedback
                          ? (widget.user.feedbackSentiment == 'positive'
                              ? 'Feedback: Positivo'
                              : 'Feedback: Negativo')
                          : 'Feedback: Sin respuesta',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: widget.user.hasGivenFeedback
                            ? (widget.user.feedbackSentiment == 'positive'
                                ? AppColors.success
                                : AppColors.error)
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 20),
              Container(height: 1, color: AppColors.divider),
              const SizedBox(height: 20),

              isTablet ? _buildTabletLayout() : _buildMobileLayout(),

              const SizedBox(height: 20),
              Container(height: 1, color: AppColors.divider),
              const SizedBox(height: 20),

              _buildSwitches(),

              // NUEVO: Botón "Ver Apto Físico"
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: widget.user.medicalCertificateUrl != null
                      ? () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final uri =
                              Uri.parse(widget.user.medicalCertificateUrl!);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri,
                                mode: LaunchMode.externalApplication);
                          } else {
                            messenger.showSnackBar(
                              const SnackBar(
                                  content: Text('No se pudo abrir el archivo')),
                            );
                          }
                        }
                      : null, // Deshabilita el click si es null
                  icon: Icon(
                    Icons.medical_services_outlined,
                    size: 20,
                    color: widget.user.medicalCertificateUrl != null
                        ? AppColors.success
                        : AppColors.textSecondary,
                  ),
                  label: Text(
                    widget.user.medicalCertificateUrl != null
                        ? 'Ver Apto Físico'
                        : 'Sin apto físico cargado',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: widget.user.medicalCertificateUrl != null
                          ? AppColors.success
                          : AppColors.textSecondary,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                        color: widget.user.medicalCertificateUrl != null
                            ? AppColors.success.withValues(alpha: 0.6)
                            : AppColors.borderLight,
                        width: 2),
                    foregroundColor: AppColors.success,
                    backgroundColor: widget.user.medicalCertificateUrl != null
                        ? AppColors.success.withValues(alpha: 0.05)
                        : AppColors.background,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              // NUEVO: Botón "Asignar Turno Fijo"
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showFixedScheduleDialog(context),
                  icon: const Icon(Icons.event_repeat, size: 20),
                  label: const Text(
                    'Asignar Turno Fijo',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                        color: AppColors.primary.withValues(alpha: 0.6),
                        width: 2),
                    foregroundColor: AppColors.primaryDark,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.05),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              // NUEVO: Botón "Visualizar Reservas"
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    context.push(
                      '/admin/users/${widget.user.id}/bookings',
                      extra: widget.user.fullName,
                    );
                  },
                  icon: const Icon(Icons.history, size: 20),
                  label: const Text(
                    'Visualizar Reservas',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                        color: Colors.indigo.withValues(alpha: 0.6), width: 2),
                    foregroundColor: Colors.indigo,
                    backgroundColor: Colors.indigo.withValues(alpha: 0.05),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.accent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              const Text(
                'Créditos Disponibles',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.user.creditsAvailable.toString(),
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: _buildCreditButton('+1', 1)),
            const SizedBox(width: 8),
            Expanded(child: _buildCreditButton('+4', 4)),
            const SizedBox(width: 8),
            Expanded(child: _buildCreditButton('-1', -1)),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _showManualCreditDialog(context),
            icon: const Icon(Icons.add_circle_outline, size: 20),
            label: const Text(
              'Manual',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.primaryDark, width: 2),
              foregroundColor: AppColors.primaryDark,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabletLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 140,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.accent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              const Text(
                'Créditos',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.user.creditsAvailable.toString(),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildCreditButton('+1', 1),
              _buildCreditButton('+4', 4),
              _buildCreditButton('-1', -1),
              OutlinedButton.icon(
                onPressed: () => _showManualCreditDialog(context),
                icon: const Icon(Icons.add_circle_outline, size: 18),
                label: const Text('Manual'),
                style: OutlinedButton.styleFrom(
                  side:
                      const BorderSide(color: AppColors.primaryDark, width: 2),
                  foregroundColor: AppColors.primaryDark,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCreditButton(String label, int amount) {
    return ElevatedButton(
      onPressed: () => _addCredits(amount),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFA67777),
        foregroundColor: Colors.white,
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildSwitches() {
    return Column(
      children: [
        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: _isTrial
                ? AppColors.warning.withValues(alpha: 0.1)
                : AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isTrial
                  ? AppColors.warning.withValues(alpha: 0.3)
                  : AppColors.borderLight,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.science_outlined, // Ícono de probeta
                color: _isTrial ? AppColors.warning : AppColors.textSecondary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Usuario de Prueba',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _isTrial
                            ? AppColors.warning
                            : AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      _isTrial
                          ? 'No puede reservar/cancelar'
                          : 'Permisos completos',
                      style: TextStyle(
                        fontSize: 13,
                        color: _isTrial
                            ? AppColors.warning
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _isTrial,
                onChanged: (value) async {
                  setState(() => _isTrial = value);
                  try {
                    // Lógica corregida: Usamos repository
                    await ref
                        .read(userRepositoryProvider)
                        .toggleTrial(widget.user.id);
                    widget
                        .onRefresh(); // Refrescamos para actualizar el badge de la lista
                    if (!mounted) return;
                    _showFeedback(
                        value ? 'Marcado como prueba' : 'Permisos restaurados');
                  } catch (e) {
                    if (!mounted) return;
                    setState(() => _isTrial = !value);
                    _showError('Error al cambiar modo prueba');
                  }
                },
                activeThumbColor: AppColors.warning,
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // --- 3. SWITCH BLOQUEAR (ROJO) ---
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: _isBlocked
                ? AppColors.error.withValues(alpha: 0.1)
                : AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isBlocked
                  ? AppColors.error.withValues(alpha: 0.3)
                  : AppColors.borderLight,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.block_outlined,
                color: _isBlocked ? AppColors.error : AppColors.textSecondary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bloquear Acceso',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _isBlocked
                            ? AppColors.error
                            : AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      _isBlocked ? 'Sin acceso a la app' : 'Acceso permitido',
                      style: TextStyle(
                        fontSize: 13,
                        color: _isBlocked
                            ? AppColors.error
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _isBlocked,
                onChanged: (value) async {
                  if (value) {
                    // Blocking action -> Show confirmation
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('¿Bloquear acceso?'),
                        content: const Text(
                            'Al bloquear al usuario, se CANCELARÁN automáticamente todas sus reservas futuras.\n\nSi decides desbloquearlo más tarde, deberás anotarlo manualmente en las clases nuevamente.\n\n¿Deseas continuar?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancelar'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.error,
                            ),
                            child: const Text('Bloquear y Cancelar Turnos'),
                          ),
                        ],
                      ),
                    );

                    if (confirm != true) {
                      return; // Cancelled
                    }
                  }

                  // Proceed with update
                  setState(() => _isBlocked = value);
                  try {
                    await ref
                        .read(userRepositoryProvider)
                        .toggleDisabled(widget.user.id);
                    widget.onRefresh();
                    if (!mounted) return;
                    _showFeedback(
                        value ? 'Usuario bloqueado' : 'Usuario desbloqueado');
                  } catch (e) {
                    if (!mounted) return;
                    setState(() => _isBlocked = !value); // Revert on error
                    _showError('Error al cambiar estado');
                  }
                },
                activeThumbColor: AppColors.error,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Helper para mostrar errores (agregalo si no lo tenés en la clase)
  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.error),
    );
  }

  Future<void> _addCredits(int amount) async {
    try {
      await ref
          .read(userRepositoryProvider)
          .addCredits(widget.user.id, amount, null);
      if (!mounted) return;
      _showFeedback(amount > 0
          ? 'Se agregaron $amount créditos'
          : 'Se quitaron ${amount.abs()} créditos');
      widget.onRefresh();
    } catch (e) {
      if (!mounted) return;
      _showError('Error: $e');
    }
  }

  void _showEditEmailDialog(BuildContext context) {
    final emailController = TextEditingController(text: widget.user.email);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Editar Email',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: TextFormField(
          controller: emailController,
          decoration: const InputDecoration(
            labelText: 'Email',
            prefixIcon: Icon(Icons.email_outlined),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newEmail = emailController.text.trim();
              if (newEmail.isEmpty) return;

              try {
                // Mostrar feedback visual de carga o cerrar y mostrar toast
                Navigator.pop(context);
                await ref
                    .read(userRepositoryProvider)
                    .updateUserDetails(widget.user.id, email: newEmail);

                widget.onRefresh();
                _showFeedback('Email actualizado correctamente');
              } catch (e) {
                _showError('Error al actualizar email: $e');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFA67777),
            ),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _showManualCreditDialog(BuildContext context) {
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Agregar/Quitar Créditos',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Ingresa un número positivo para sumar o negativo para restar',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: amountController,
              decoration: const InputDecoration(
                labelText: 'Cantidad',
                prefixIcon: Icon(Icons.numbers),
                hintText: 'Ej: 10 o -5',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                  signed: true, decimal: false),
              // Quitamos formatter estricto para evitar bloqueos de teclado
              // validamos al confirmar
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final text = amountController.text.trim();
              final amount = int.tryParse(text);

              if (amount == null) {
                // Validación manual
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Ingresa un número válido (ej: 10 o -5)'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }

              Navigator.pop(context);
              if (amount != 0) {
                _addCredits(amount);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFA67777),
            ),
            child: const Text('Aplicar'),
          ),
        ],
      ),
    );
  }

  void _showFixedScheduleDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _AddFixedScheduleDialog(
        user: widget.user,
        onSuccess: () {
          widget.onRefresh();
          _showFeedback('Turno fijo asignado correctamente');
        },
      ),
    );
  }

  void _showFeedback(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 80),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

// ========== ADD FIXED SCHEDULE DIALOG ==========

class _AddFixedScheduleDialog extends ConsumerStatefulWidget {
  final User user;
  final VoidCallback onSuccess;

  const _AddFixedScheduleDialog({
    required this.user,
    required this.onSuccess,
  });

  @override
  ConsumerState<_AddFixedScheduleDialog> createState() =>
      _AddFixedScheduleDialogState();
}

class _AddFixedScheduleDialogState
    extends ConsumerState<_AddFixedScheduleDialog> {
  DayOfWeek _selectedDay = DayOfWeek.monday;
  TimeOfDay _selectedTime = const TimeOfDay(hour: 18, minute: 0);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        'Nuevo Turno Fijo para ${widget.user.fullName ?? "Usuario"}',
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Selector de día
          DropdownButtonFormField<DayOfWeek>(
            initialValue: _selectedDay,
            decoration: InputDecoration(
              labelText: 'Día de la semana',
              prefixIcon: const Icon(Icons.calendar_today),
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            items: DayOfWeek.values.map((day) {
              return DropdownMenuItem(
                value: day,
                child: Text(day.displayName),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedDay = value);
              }
            },
          ),
          const SizedBox(height: 16),

          // Selector de hora
          GestureDetector(
            onTap: () async {
              final TimeOfDay? picked = await showTimePicker(
                context: context,
                initialTime: _selectedTime,
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.light(
                        primary: Color(0xFFA67777),
                        onPrimary: Colors.white,
                        onSurface: AppColors.textPrimary,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null) {
                setState(() => _selectedTime = picked);
              }
            },
            child: AbsorbPointer(
              child: TextFormField(
                decoration: InputDecoration(
                  labelText: 'Hora',
                  prefixIcon: const Icon(Icons.access_time),
                  suffixIcon: const Icon(Icons.arrow_drop_down),
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                controller: TextEditingController(
                  text: _selectedTime.format(context),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Info box
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
              ),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppColors.primaryDark,
                  size: 20,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Se reservarán automáticamente todas las clases futuras que coincidan con este horario.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _handleSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFA67777),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: const Text('Confirmar'),
        ),
      ],
    );
  }

  void _handleSubmit() async {
    try {
      // Convertir TimeOfDay a formato "HH:mm:ss"
      final hour = _selectedTime.hour.toString().padLeft(2, '0');
      final minute = _selectedTime.minute.toString().padLeft(2, '0');
      final timeString = '$hour:$minute:00';

      await ref.read(fixedScheduleProvider.notifier).addFixedSchedule(
            userId: widget.user.id,
            dayOfWeek: _selectedDay.name, // "monday", "tuesday", etc.
            startTime: timeString,
          );

      if (!mounted) return;

      Navigator.pop(context);
      widget.onSuccess();
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
        ),
      );
    }
  }
}

// ========== CREATE USER DIALOG ==========

class _CreateUserDialog extends ConsumerStatefulWidget {
  final VoidCallback onUserCreated;

  const _CreateUserDialog({
    required this.onUserCreated,
  });

  @override
  ConsumerState<_CreateUserDialog> createState() => _CreateUserDialogState();
}

class _CreateUserDialogState extends ConsumerState<_CreateUserDialog> {
  final _fullNameController = TextEditingController();
  final _dniController = TextEditingController();
  bool _isTrial = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _dniController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final fullName = _fullNameController.text.trim();
    final dni = _dniController.text.trim();

    if (fullName.isEmpty || dni.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor completa todos los campos'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final dio = ref.read(dioProvider);
      await dio.post('/users', data: {
        'full_name': fullName,
        'dni': dni,
        'is_trial': _isTrial,
      });

      if (!mounted) return;

      Navigator.pop(context);
      widget.onUserCreated();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Usuario "$fullName" creado exitosamente',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        'Crear Nuevo Usuario',
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 20,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
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
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(height: 1, color: AppColors.divider),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.science_outlined, size: 20),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Usuario de Prueba',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
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
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
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
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text('Crear Usuario'),
        ),
      ],
    );
  }
}
