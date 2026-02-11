import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/providers.dart';

class InfoScreen extends ConsumerStatefulWidget {
  const InfoScreen({super.key});

  @override
  ConsumerState<InfoScreen> createState() => _InfoScreenState();
}

class _InfoScreenState extends ConsumerState<InfoScreen> {
  final int _currentNavIndex = 4;

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
        context.push('/client/profile');
        break;
      case 3:
        context.push('/client/announcements');
        break;
      case 4:
        break;
    }
  }

  Future<void> _launchInstagram(String? handle) async {
    if (handle == null || handle.isEmpty) {
      _showSnack('Instagram no configurado');
      return;
    }

    final Uri url;
    if (handle.startsWith('http')) {
      url = Uri.parse(handle);
    } else {
      final cleanHandle = handle.replaceAll('@', '').trim();
      url = Uri.parse('https://www.instagram.com/$cleanHandle/');
    }

    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) _showSnack('No se pudo abrir Instagram');
    }
  }

  Future<void> _launchWhatsApp(String? phone) async {
    if (phone == null || phone.isEmpty) {
      _showSnack('WhatsApp no configurado');
      return;
    }

    final Uri url;
    if (phone.startsWith('http')) {
      url = Uri.parse(phone);
    } else {
      // Remove non-numeric characters for wa.me link
      final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
      url = Uri.parse('https://wa.me/$cleanPhone');
    }

    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) _showSnack('No se pudo abrir WhatsApp');
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
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
          'Información',
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
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (settings) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 90),
                children: [
                  // Logo o Header simple
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.spa_outlined,
                            size: 48,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          settings.studioName,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppColors.primaryDark,
                              ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Card Ubicación
                  _InfoCard(
                    icon: Icons.location_on,
                    iconColor: const Color(0xFFA67777),
                    title: 'Ubicación',
                    content: settings.address,
                  ),

                  const SizedBox(height: 18),

                  // Card Horarios
                  _InfoCard(
                    icon: Icons.access_time,
                    iconColor: const Color(0xFFA67777),
                    title: 'Horarios',
                    content: settings.schedule,
                  ),

                  const SizedBox(height: 18),

                  // Card WhatsApp
                  _InfoCard(
                    customIcon: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: const Color(0xFF25D366).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color:
                              const Color(0xFF25D366).withValues(alpha: 0.35),
                          width: 1.5,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.chat,
                          color: Color(0xFF25D366),
                          size: 28,
                        ),
                      ),
                    ),
                    title: 'WhatsApp',
                    content: settings.whatsapp != null &&
                            settings.whatsapp!.isNotEmpty
                        ? 'Envianos un mensaje'
                        : 'No configurado',
                    onTap: () => _launchWhatsApp(settings.whatsapp),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Card Instagram
                  _InfoCard(
                    customIcon: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE1306C).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color:
                              const Color(0xFFE1306C).withValues(alpha: 0.35),
                          width: 1.5,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.camera_alt,
                          color: Color(0xFFE1306C),
                          size: 28,
                        ),
                      ),
                    ),
                    title: 'Instagram',
                    content: settings.instagram != null &&
                            settings.instagram!.isNotEmpty
                        ? settings.instagram!
                        : 'No configurado',
                    onTap: () => _launchInstagram(settings.instagram),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: AppColors.textSecondary,
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
}

// ========== INFO CARD WIDGET ==========

class _InfoCard extends StatelessWidget {
  final IconData? icon;
  final Color? iconColor;
  final Widget? customIcon;
  final String title;
  final String content;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _InfoCard({
    this.icon,
    this.iconColor,
    this.customIcon,
    required this.title,
    required this.content,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
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
        child: Row(
          children: [
            customIcon ??
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: iconColor?.withValues(alpha: 0.15) ??
                        AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: iconColor?.withValues(alpha: 0.35) ??
                          AppColors.primary.withValues(alpha: 0.35),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    icon ?? Icons.info,
                    color: iconColor ?? AppColors.primary,
                    size: 28,
                  ),
                ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                          letterSpacing: -0.3,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    content,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 15,
                          height: 1.4,
                          color: AppColors.textPrimary,
                        ),
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 12),
              trailing!,
            ],
          ],
        ),
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: card,
      );
    }

    return card;
  }
}
