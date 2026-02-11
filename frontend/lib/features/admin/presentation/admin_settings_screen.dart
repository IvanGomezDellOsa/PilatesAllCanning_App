import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/providers.dart';

class AdminSettingsScreen extends ConsumerStatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  ConsumerState<AdminSettingsScreen> createState() =>
      _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends ConsumerState<AdminSettingsScreen> {
  final int _currentNavIndex = 3;

  void _onNavTap(int index) {
    if (index == _currentNavIndex) return;
    switch (index) {
      case 0:
        context.go('/admin');
        break;
      case 1:
        context.push('/admin/users');
        break;
      case 2:
        context.push('/admin/announcements');
        break;
      case 3:
        break;
    }
  }

  Future<void> _updateSetting(String key, String value) async {
    try {
      await ref.read(settingsControllerProvider.notifier).update(key, value);
      _showFeedback('Ajuste actualizado');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsControllerProvider);

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
          child: Container(height: 1, color: AppColors.divider),
        ),
      ),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) =>
            Center(child: Text('Error cargando ajustes: $err')),
        data: (settings) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 90),
                children: [
                  const _SectionHeader(
                    icon: Icons.settings_outlined,
                    title: 'Configuración de Reservas',
                    subtitle: 'Políticas y restricciones',
                  ),
                  const SizedBox(height: 16),
                  _SettingCard(
                    icon: Icons.timer_outlined,
                    iconColor: const Color(0xFFA67777),
                    title: 'Minutos antes para cancelar',
                    subtitle: 'Sin penalización si cancela con anticipación',
                    trailing: IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => _showEditDialog(
                        context,
                        'Minutos para cancelar',
                        settings.cancelMinutesBefore.toString(),
                        (val) => _updateSetting('cancel_minutes_before', val),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    child: Text(
                      '${settings.cancelMinutesBefore} minutos',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _SettingCard(
                    icon: Icons.pause_circle_outlined,
                    iconColor: settings.pauseReservations
                        ? AppColors.warning
                        : AppColors.textSecondary,
                    title: 'Pausar reservas',
                    subtitle: settings.pauseReservations
                        ? 'Los usuarios NO pueden reservar (modo vacaciones)'
                        : 'Reservas activas normalmente',
                    trailing: Switch(
                      value: settings.pauseReservations,
                      onChanged: (value) {
                        _updateSetting('pause_reservations', value.toString());
                      },
                      activeThumbColor: AppColors.warning,
                    ),
                  ),
                  const SizedBox(height: 32),
                  const _SectionHeader(
                    icon: Icons.store_outlined,
                    title: 'Información comercial',
                    subtitle: 'Visible en la app de clientes',
                  ),
                  const SizedBox(height: 16),
                  _SettingCard(
                    icon: Icons.location_on_outlined,
                    iconColor: const Color(0xFFA67777),
                    title: 'Dirección',
                    trailing: IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => _showEditDialog(
                        context,
                        'Dirección',
                        settings.address,
                        (val) => _updateSetting('address', val),
                      ),
                    ),
                    child: Text(
                      settings.address,
                      style: const TextStyle(
                          fontSize: 15,
                          height: 1.4,
                          color: AppColors.textPrimary),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _SettingCard(
                    icon: Icons.access_time,
                    iconColor: const Color(0xFFA67777),
                    title: 'Horarios',
                    trailing: IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => _showEditDialog(
                        context,
                        'Horarios',
                        settings.schedule,
                        (val) => _updateSetting('schedule', val),
                        multiline: true,
                      ),
                    ),
                    child: Text(
                      settings.schedule,
                      style: const TextStyle(
                          fontSize: 15,
                          height: 1.4,
                          color: AppColors.textPrimary),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _SettingCard(
                    icon: Icons.chat,
                    iconColor: const Color(0xFF25D366),
                    title: 'WhatsApp',
                    trailing: IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => _showEditDialog(
                        context,
                        'WhatsApp',
                        settings.whatsapp ?? '',
                        (val) => _updateSetting('whatsapp', val),
                        keyboardType: TextInputType.phone,
                      ),
                    ),
                    child: Text(
                      settings.whatsapp ?? 'No configurado',
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _SettingCard(
                    icon: Icons.camera_alt,
                    iconColor: const Color(0xFFE1306C),
                    title: 'Instagram',
                    trailing: IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => _showEditDialog(
                        context,
                        'Instagram',
                        settings.instagram ?? '',
                        (val) => _updateSetting('instagram', val),
                      ),
                    ),
                    child: Text(
                      settings.instagram ?? 'No configurado',
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const _SectionHeader(
                    icon: Icons.admin_panel_settings_outlined,
                    title: 'Gestión de Administradores',
                    subtitle: 'Promover usuarios a admin',
                  ),
                  const SizedBox(height: 16),
                  _SettingCard(
                    icon: Icons.person_add_outlined,
                    iconColor: const Color(0xFFA67777),
                    title: 'Promover a Administrador',
                    subtitle: 'Buscar usuario y otorgar permisos',
                    trailing: ElevatedButton.icon(
                      onPressed: () => _showSearchUserDialog(),
                      icon: const Icon(Icons.search, size: 18),
                      label: const Text('Buscar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFA67777),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const _SectionHeader(
                    icon: Icons.sports_gymnastics_outlined,
                    title: 'Gestión de Instructores',
                    subtitle: 'Lista de instructores disponibles',
                  ),
                  const SizedBox(height: 16),
                  const _InstructorManagementSection(),
                  const SizedBox(height: 32),
                  const _SectionHeader(
                    icon: Icons.logout,
                    title: 'Sesión',
                    subtitle: 'Gestionar mi cuenta',
                  ),
                  const SizedBox(height: 16),
                  _SettingCard(
                    icon: Icons.logout,
                    iconColor: AppColors.error,
                    title: 'Cerrar Sesión',
                    trailing: OutlinedButton(
                      onPressed: _handleSignOut,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                      ),
                      child: const Text('Salir'),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _SettingCard(
                    icon: Icons.delete_forever,
                    iconColor: AppColors.error,
                    title: 'Eliminar Cuenta Admin',
                    subtitle:
                        'Esta acción es irreversible. Perderás acceso al panel y tus datos.',
                    trailing: ElevatedButton(
                      onPressed: _handleDeleteAccount,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Eliminar'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
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

  void _showEditDialog(
    BuildContext context,
    String title,
    String currentValue,
    Function(String) onSave, {
    bool multiline = false,
    TextInputType? keyboardType,
  }) {
    final controller = TextEditingController(text: currentValue);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Editar $title',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
        ),
        content: TextFormField(
          controller: controller,
          decoration: InputDecoration(
            labelText: title,
            filled: true,
            fillColor: AppColors.background,
          ),
          maxLines: multiline ? 5 : 1,
          keyboardType: keyboardType,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              onSave(controller.text);
              Navigator.pop(context);
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

  void _showConfirmationDialog(
    BuildContext context,
    String title,
    String content,
    VoidCallback onConfirm, {
    bool isDestructive = false,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isDestructive ? AppColors.error : const Color(0xFFA67777),
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  void _showSearchUserDialog() {
    final searchController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (sheetContext, setDialogState) {
          return Dialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              constraints: const BoxConstraints(maxWidth: 500),
              height: MediaQuery.of(context).size.height * 0.7,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Buscar Usuario',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: 'Nombre o DNI...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) {
                      ref
                          .read(usersSearchProvider.notifier)
                          .onSearchChanged(value);
                    },
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Consumer(
                      builder: (consumerContext, dialogRef, child) {
                        final searchState =
                            dialogRef.watch(usersSearchProvider);
                        final users = searchState.users;

                        if (users.isEmpty && !searchState.isLoading) {
                          return const Center(
                            child: Text(
                              'No se encontraron usuarios',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          );
                        }

                        return NotificationListener<ScrollNotification>(
                          onNotification: (scrollInfo) {
                            if (!searchState.isLoading &&
                                searchState.hasMore &&
                                scrollInfo.metrics.pixels >=
                                    scrollInfo.metrics.maxScrollExtent - 200) {
                              dialogRef
                                  .read(usersSearchProvider.notifier)
                                  .loadMore();
                            }
                            return false;
                          },
                          child: ListView.separated(
                            separatorBuilder: (context, index) =>
                                const Divider(height: 1),
                            itemCount:
                                users.length + (searchState.hasMore ? 1 : 0),
                            itemBuilder: (listContext, index) {
                              if (index == users.length) {
                                return const Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Center(
                                      child: CircularProgressIndicator()),
                                );
                              }

                              final user = users[index];
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4.0),
                                child: ListTile(
                                  shape: user.isAdmin
                                      ? RoundedRectangleBorder(
                                          side: const BorderSide(
                                              color: Colors.green, width: 1.5),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        )
                                      : null,
                                  tileColor: user.isAdmin
                                      ? Colors.green.withValues(alpha: 0.05)
                                      : null,
                                  contentPadding: user.isAdmin
                                      ? const EdgeInsets.symmetric(
                                          horizontal: 8.0)
                                      : EdgeInsets.zero,
                                  leading: CircleAvatar(
                                    backgroundColor: user.isAdmin
                                        ? Colors.green.withValues(alpha: 0.2)
                                        : AppColors.primary
                                            .withValues(alpha: 0.1),
                                    child: Text(
                                      user.fullName
                                              ?.substring(0, 1)
                                              .toUpperCase() ??
                                          'U',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: user.isAdmin
                                            ? Colors.green
                                            : AppColors.primary,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    user.fullName ?? 'Usuario',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15),
                                  ),
                                  subtitle: Text(
                                    'DNI: ${user.dni ?? 'N/A'}',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                  trailing: user.isAdmin
                                      ? IconButton(
                                          icon: const Icon(
                                              Icons.remove_circle_outline,
                                              color: AppColors.error),
                                          tooltip: 'Revocar Admin',
                                          onPressed: () {
                                            Navigator.pop(listContext);
                                            _showConfirmationDialog(
                                              context,
                                              'Revocar Permisos',
                                              '¿Estás seguro de que deseas quitar los permisos de administrador a ${user.fullName}?',
                                              () async {
                                                try {
                                                  await ref
                                                      .read(
                                                          userRepositoryProvider)
                                                      .toggleAdmin(user.id);
                                                  if (mounted) {
                                                    ref
                                                        .read(
                                                            usersSearchProvider
                                                                .notifier)
                                                        .refresh();
                                                    _showFeedback(
                                                        'Permisos revocados');
                                                  }
                                                } catch (e) {
                                                  if (mounted) {
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                      SnackBar(
                                                          content: Text(
                                                              'Error: $e')),
                                                    );
                                                  }
                                                }
                                              },
                                              isDestructive: true,
                                            );
                                          },
                                        )
                                      : IconButton(
                                          icon: const Icon(
                                              Icons.add_circle_outline,
                                              color: Color(0xFFA67777)),
                                          tooltip: 'Hacer Admin',
                                          onPressed: () {
                                            Navigator.pop(listContext);
                                            _showConfirmationDialog(
                                              context,
                                              'Promover a Admin',
                                              '¿Estás seguro de que deseas hacer administrador a ${user.fullName}?',
                                              () async {
                                                try {
                                                  await ref
                                                      .read(
                                                          userRepositoryProvider)
                                                      .toggleAdmin(user.id);
                                                  if (mounted) {
                                                    ref
                                                        .read(
                                                            usersSearchProvider
                                                                .notifier)
                                                        .refresh();
                                                    _showFeedback(
                                                        'Usuario promovido a admin');
                                                  }
                                                } catch (e) {
                                                  if (mounted) {
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                      SnackBar(
                                                          content: Text(
                                                              'Error: $e')),
                                                    );
                                                  }
                                                }
                                              },
                                            );
                                          },
                                        ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      child: const Text('Cerrar'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleSignOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Cerrar Sesión',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        content: const Text(
          '¿Estás seguro que deseas salir del panel de administración?',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Salir',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await ref.read(authRepositoryProvider).signOut();
      ref.invalidate(currentUserProvider);
      ref.invalidate(userProfileProvider);
      if (mounted) context.go('/login');
    }
  }

  Future<void> _handleDeleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Cuenta Admin'),
        content: const Text(
            '¡ADVERTENCIA CRÍTICA!\n\nEstás a punto de eliminar tu cuenta de ADMINISTRADOR.\nSi eres el único admin, nadie podrá gestionar la app.\n\n¿Confirmas esta acción destructiva?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('SÍ, ELIMINAR'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (!mounted) return;

      try {
        await ref.read(userRepositoryProvider).deleteAccount();
        await ref.read(authRepositoryProvider).signOut();
        ref.invalidate(currentUserProvider);
        ref.invalidate(userProfileProvider);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cuenta admin eliminada')),
          );
          context.go('/login');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
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

// ========== SECTION HEADER ==========
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: AppColors.primaryDark,
            size: 24,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      letterSpacing: -0.3,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ========== SETTING CARD ==========
class _SettingCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Widget? child;
  final Widget? trailing;

  const _SettingCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: iconColor.withValues(alpha: 0.35),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            letterSpacing: -0.3,
                          ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          if (child != null) ...[
            const SizedBox(height: 16),
            Container(
              height: 1,
              color: AppColors.divider,
            ),
            const SizedBox(height: 16),
            child!,
          ],
        ],
      ),
    );
  }
}

/// Sección de gestión de instructores.
/// Muestra una tarjeta con un botón para abrir el diálogo de administración.
/// Mantiene la pantalla de ajustes limpia al delegar la gestión detallada a un modal.
class _InstructorManagementSection extends ConsumerStatefulWidget {
  const _InstructorManagementSection();

  @override
  ConsumerState<_InstructorManagementSection> createState() =>
      _InstructorManagementSectionState();
}

class _InstructorManagementSectionState
    extends ConsumerState<_InstructorManagementSection> {
  @override
  Widget build(BuildContext context) {
    return _SettingCard(
      icon: Icons.sports_gymnastics_outlined,
      iconColor: const Color(0xFFA67777),
      title: 'Gestión de Instructores',
      subtitle: 'Agregar o eliminar instructores',
      trailing: ElevatedButton.icon(
        onPressed: () => _showInstructorManagementDialog(context),
        icon: const Icon(Icons.edit, size: 18),
        label: const Text('Gestionar'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFA67777),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),
    );
  }

  /// Abre el diálogo modal que contiene la lista completa y el formulario de creación.
  void _showInstructorManagementDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _InstructorDialogContent(),
    );
  }
}

/// Contenido del diálogo de gestión de instructores.
/// Permite:
/// 1. Crear nuevos instructores (Formulario superior).
/// 2. Ver la lista completa de instructores existentes.
/// 3. Eliminar instructores individualmente (Hard Delete en Backend).
class _InstructorDialogContent extends ConsumerStatefulWidget {
  const _InstructorDialogContent();

  @override
  ConsumerState<_InstructorDialogContent> createState() =>
      _InstructorDialogContentState();
}

class _InstructorDialogContentState
    extends ConsumerState<_InstructorDialogContent> {
  final TextEditingController _nameController = TextEditingController();
  bool _isCreating = false;

  @override
  Widget build(BuildContext context) {
    final instructosAsync = ref.watch(allInstructorsProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ... Header ...
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Instructores',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Formulario Creación (Arriba para fácil acceso)
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      hintText: 'Nuevo instructor...',
                      filled: true,
                      fillColor: AppColors.background,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isCreating ? null : _createInstructor,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFA67777),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isCreating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Lista
            Flexible(
              child: instructosAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(child: Text('Error: $err')),
                data: (instructors) {
                  if (instructors.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'No hay instructores.\nAgrega uno arriba.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    itemCount: instructors.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final instructor = instructors[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor:
                              const Color(0xFFA67777).withValues(alpha: 0.1),
                          child: Text(
                            instructor.name.substring(0, 1).toUpperCase(),
                            style: const TextStyle(
                                color: Color(0xFFA67777),
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(instructor.name,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: AppColors.error),
                          tooltip: 'Eliminar',
                          onPressed: () => _deleteInstructor(instructor.id),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Crea un instructor y actualiza la lista localmente invalidando el provider.
  Future<void> _createInstructor() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isCreating = true);
    try {
      await ref.read(instructorRepositoryProvider).createInstructor(name);
      _nameController.clear();
      // Invalidate to refresh the list
      ref.invalidate(allInstructorsProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  /// Elimina un instructor tras confirmación y actualiza la UI.
  Future<void> _deleteInstructor(String id) async {
    // Confirm dialog overlay
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Instructor'),
        content: const Text(
            '¿Seguro que deseas eliminar a este instructor? Las clases pasadas mantendrán su nombre.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ref.read(instructorRepositoryProvider).deleteInstructor(id);
      ref.invalidate(allInstructorsProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}
