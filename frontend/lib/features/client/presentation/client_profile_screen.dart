import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../models/user.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/providers.dart';
import '../providers/client_providers.dart';
import '../../shared/widgets/common_widgets.dart';
import 'widgets/feedback_dialog.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _dniController;
  bool _isEditing = false;
  bool _isLoading = false;
  final int _currentNavIndex = 2;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _dniController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dniController.dispose();
    super.dispose();
  }

  void _onNavTap(int index) {
    if (index == _currentNavIndex) return;

    switch (index) {
      case 0:
        context.go('/client');
        break;
      case 1:
        context.push('/client/my-classes');
        break;
      case 2:
        // Ya estamos en Perfil
        break;
      case 3:
        context.push('/client/announcements');
        break;
      case 4:
        context.push('/client/info');
        break;
    }
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El nombre es obligatorio';
    }
    if (value.trim().length < 3) {
      return 'El nombre debe tener al menos 3 caracteres';
    }
    return null;
  }

  String? _validateDNI(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El DNI es obligatorio';
    }
    if (!RegExp(r'^\d+$').hasMatch(value.trim())) {
      return 'El DNI debe contener solo números';
    }
    if (value.trim().length < 7 || value.trim().length > 8) {
      return 'El DNI debe tener 7 u 8 dígitos';
    }
    return null;
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref.read(updateProfileControllerProvider.notifier).updateProfile(
            fullName: _nameController.text.trim(),
            dni: _dniController.text.trim(),
            phone: null,
          );

      if (!mounted) return;

      setState(() => _isEditing = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 22),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Perfil actualizado correctamente',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
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
      ref.invalidate(userProfileProvider);
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
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
          '¿Estás seguro que deseas salir?',
          style: TextStyle(
            fontSize: 16,
            height: 1.4,
          ),
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
        title: const Text('Eliminar Cuenta'),
        scrollable: true,
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Esta acción es irreversible. Se eliminarán permanentemente tus datos personales:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text('• Nombre y Apellido'),
            Text('• Email y Teléfono'),
            Text('• DNI y Certificados Médicos'),
            Text('• Vinculación con Google/Apple'),
            SizedBox(height: 16),
            Text(
              'Nota: Tu historial de reservas pasadas se conservará únicamente con fines estadísticos, pero será totalmente anonimizado y desvinculado de tu identidad.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('ELIMINAR DEFINITIVAMENTE'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (!mounted) return;

      // Mostrar loading
      setState(() => _isLoading = true);

      try {
        await ref.read(userRepositoryProvider).deleteAccount();
        // Revocar acceso de Google/Apple (Requiremento Store)
        await ref.read(authRepositoryProvider).revokeAccess();
        ref.invalidate(currentUserProvider);
        ref.invalidate(userProfileProvider);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cuenta eliminada correctamente')),
          );
          context.go('/login');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al eliminar cuenta: $e')),
          );
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
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
          'Mi Perfil',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 19,
                letterSpacing: -0.3,
              ),
        ),
        actions: [
          if (!_isEditing)
            IconButton(
              onPressed: () => setState(() => _isEditing = true),
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Editar perfil',
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: AppColors.divider,
          ),
        ),
      ),
      body: profileAsync.when(
        data: (profile) {
          // Inicializar controllers con los datos actuales
          if (!_isEditing && _nameController.text.isEmpty) {
            _nameController.text = profile.fullName ?? '';
            _dniController.text = profile.dni ?? '';
          }

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 90),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Créditos disponibles
                      Center(
                        child: CreditsDisplay(
                          credits: profile.creditsAvailable,
                          large: true,
                        ),
                      ),

                      const SizedBox(height: 32),

                      Container(
                        height: 1,
                        color: AppColors.divider,
                      ),

                      const SizedBox(height: 28),

                      // APTO FÍSICO
                      Text(
                        'Apto Físico',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 19,
                              letterSpacing: -0.3,
                            ),
                      ),
                      const SizedBox(height: 16),
                      _buildMedicalCertificateCard(profile),

                      const SizedBox(height: 28),

                      Container(
                        height: 1,
                        color: AppColors.divider,
                      ),

                      const SizedBox(height: 28),

                      // Información Personal
                      Text(
                        'Información Personal',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 19,
                              letterSpacing: -0.3,
                            ),
                      ),
                      const SizedBox(height: 20),

                      // Nombre
                      Text(
                        'Nombre Completo',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          hintText: 'Tu nombre completo',
                          prefixIcon: const Icon(Icons.person_outline),
                          filled: true,
                          fillColor: _isEditing
                              ? AppColors.surface
                              : AppColors.background,
                        ),
                        textCapitalization: TextCapitalization.words,
                        validator: _validateName,
                        enabled: _isEditing && !_isLoading,
                        textInputAction: TextInputAction.next,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      const SizedBox(height: 22),

                      // DNI
                      Text(
                        'DNI',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _dniController,
                        decoration: InputDecoration(
                          hintText: 'Tu DNI',
                          prefixIcon: const Icon(Icons.badge_outlined),
                          filled: true,
                          fillColor: _isEditing
                              ? AppColors.surface
                              : AppColors.background,
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(8),
                        ],
                        validator: _validateDNI,
                        enabled: _isEditing && !_isLoading,
                        textInputAction: TextInputAction.next,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      const SizedBox(height: 22),

                      // Email (solo lectura)
                      Text(
                        'Email',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        initialValue: profile.email,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.email_outlined),
                          suffixIcon: Icon(
                            Icons.lock_outline,
                            size: 18,
                            color: AppColors.textHint,
                          ),
                          filled: true,
                          fillColor: AppColors.background,
                        ),
                        enabled: false,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),

                      const SizedBox(height: 36),

                      // Botones de acción
                      if (_isEditing) ...[
                        // Botón Guardar (responsive)
                        screenWidth > 600
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  SizedBox(
                                    width: 160,
                                    height: 52,
                                    child: OutlinedButton(
                                      onPressed: _isLoading
                                          ? null
                                          : () {
                                              setState(() {
                                                _isEditing = false;
                                                _nameController.text =
                                                    profile.fullName ?? '';
                                                _dniController.text =
                                                    profile.dni ?? '';
                                              });
                                            },
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(
                                          color: AppColors.borderLight,
                                          width: 2,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(14),
                                        ),
                                      ),
                                      child: const Text(
                                        'Cancelar',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  SizedBox(
                                    width: 200,
                                    height: 52,
                                    child: ElevatedButton(
                                      onPressed:
                                          _isLoading ? null : _handleSave,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFFA67777),
                                        elevation: 6,
                                        shadowColor: const Color(0xFFA67777)
                                            .withValues(alpha: 0.5),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(14),
                                        ),
                                      ),
                                      child: _isLoading
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Text(
                                              'Guardar',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w900,
                                                letterSpacing: -0.3,
                                              ),
                                            ),
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                children: [
                                  Center(
                                    child: ConstrainedBox(
                                      constraints:
                                          const BoxConstraints(maxWidth: 280),
                                      child: SizedBox(
                                        width: double.infinity,
                                        height: 52,
                                        child: ElevatedButton(
                                          onPressed:
                                              _isLoading ? null : _handleSave,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                const Color(0xFFA67777),
                                            elevation: 6,
                                            shadowColor: const Color(0xFFA67777)
                                                .withValues(alpha: 0.5),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                            ),
                                          ),
                                          child: _isLoading
                                              ? const SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    color: Colors.white,
                                                  ),
                                                )
                                              : const Text(
                                                  'Guardar Cambios',
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.w900,
                                                    letterSpacing: -0.3,
                                                  ),
                                                ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Center(
                                    child: ConstrainedBox(
                                      constraints:
                                          const BoxConstraints(maxWidth: 280),
                                      child: SizedBox(
                                        width: double.infinity,
                                        height: 52,
                                        child: OutlinedButton(
                                          onPressed: _isLoading
                                              ? null
                                              : () {
                                                  setState(() {
                                                    _isEditing = false;
                                                    _nameController.text =
                                                        profile.fullName ?? '';
                                                    _dniController.text =
                                                        profile.dni ?? '';
                                                  });
                                                },
                                          style: OutlinedButton.styleFrom(
                                            side: const BorderSide(
                                              color: AppColors.borderLight,
                                              width: 2,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                            ),
                                          ),
                                          child: const Text(
                                            'Cancelar',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      ] else ...[
                        // Botón Cerrar Sesión (cuando NO está editando)
                        const SizedBox(height: 12),
                        Container(
                          height: 1,
                          color: AppColors.divider,
                        ),
                        const SizedBox(height: 24),

                        screenWidth > 600
                            ? Align(
                                alignment: Alignment.centerRight,
                                child: SizedBox(
                                  width: 200,
                                  height: 52,
                                  child: OutlinedButton.icon(
                                    onPressed: _handleSignOut,
                                    icon: const Icon(Icons.logout, size: 20),
                                    label: const Text(
                                      'Cerrar Sesión',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
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
                                  ),
                                ),
                              )
                            : Center(
                                child: OutlinedButton.icon(
                                  onPressed: _handleSignOut,
                                  icon: const Icon(Icons.logout, size: 20),
                                  label: const Text(
                                    'Cerrar Sesión',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
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
                                ),
                              ),
                      ],
                      // ZONA DE PELIGRO (Eliminar Cuenta)
                      if (!_isEditing) ...[
                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.center, // Centered
                          child: OutlinedButton(
                            onPressed: _handleDeleteAccount,
                            style: OutlinedButton.styleFrom(
                              foregroundColor:
                                  AppColors.error.withValues(alpha: 0.7),
                              side: BorderSide(
                                color: AppColors.error.withValues(alpha: 0.5),
                                width: 1,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Eliminar mi cuenta',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
        loading: () => const LoadingIndicator(message: 'Cargando perfil...'),
        error: (error, _) => ErrorView(
          message: 'Error al cargar el perfil',
          onRetry: () => ref.invalidate(userProfileProvider),
        ),
      ),
      // Bottom Navigation Bar
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

  Widget _buildMedicalCertificateCard(UserProfile profile) {
    final hasCertificate = profile.medicalCertificateUrl != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasCertificate
              ? AppColors.success.withValues(alpha: 0.3)
              : AppColors.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: hasCertificate
                  ? AppColors.success.withValues(alpha: 0.1)
                  : AppColors.background,
              shape: BoxShape.circle,
            ),
            child: Icon(
              hasCertificate
                  ? Icons.check_circle_outline
                  : Icons.file_upload_outlined,
              color:
                  hasCertificate ? AppColors.success : AppColors.textSecondary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasCertificate ? 'Certificado Cargado' : 'Sin certificado',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasCertificate
                      ? 'Tu apto físico está cargado.'
                      : 'Apto físico no cargado. Formatos: JPG, PNG, PDF, WEBP, HEIC',
                  style: TextStyle(
                    fontSize: 13,
                    color: hasCertificate ? AppColors.success : AppColors.error,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (hasCertificate) ...[
            IconButton(
              onPressed: () => _launchUrl(profile.medicalCertificateUrl!),
              icon: const Icon(Icons.visibility_outlined),
              tooltip: 'Ver certificado',
              color: AppColors.primary,
            ),
          ],
          IconButton(
            onPressed: _handleUpload,
            icon: Icon(hasCertificate
                ? Icons.edit_outlined
                : Icons.add_circle_outline),
            tooltip: hasCertificate ? 'Cambiar archivo' : 'Subir archivo',
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Future<void> _handleUpload() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'png', 'pdf', 'webp', 'heic'],
      );

      if (result != null) {
        setState(() => _isLoading = true);

        // Subir usando el repositorio
        await ref
            .read(userRepositoryProvider)
            .uploadMedicalCertificate(result.files.single);

        // Refrescar perfil para ver cambios e invalidar para que UI se actualice
        ref.invalidate(userProfileProvider);

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Apto físico subido correctamente'),
            backgroundColor: AppColors.success,
          ),
        );

        // FEEDBACK TRIGGER - Mostrar popup después de subir apto
        Future.delayed(const Duration(seconds: 3), () async {
          if (!mounted) return;
          final freshUser = await ref.refresh(userProfileProvider.future);
          if (!freshUser.hasGivenFeedback && mounted) {
            showDialog(
              context: context,
              builder: (_) => const FeedbackDialog(),
            );
          }
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al subir: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir el archivo')),
        );
      }
    }
  }
}
