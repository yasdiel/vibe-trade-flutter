import 'dart:async';

import 'package:flutter/material.dart';
import 'package:vibe_trade_v1/pages/catalog_search_page.dart';
import 'package:vibe_trade_v1/pages/chat_page.dart';
import 'package:vibe_trade_v1/pages/home_page.dart';
import 'package:vibe_trade_v1/pages/notifications_page.dart';
import 'package:vibe_trade_v1/pages/profile_page.dart';
import 'package:vibe_trade_v1/pages/reels_page.dart';
import 'package:vibe_trade_v1/services/auth_service.dart';
import 'package:vibe_trade_v1/services/main_tab_bus.dart';
import 'package:vibe_trade_v1/services/notifications_service.dart';
import 'package:vibe_trade_v1/services/saved_offers_service.dart';
import 'package:vibe_trade_v1/services/store_service.dart';
import 'package:vibe_trade_v1/theme/app_theme.dart';
import 'package:vibe_trade_v1/widgets/app_bar/home_offers_app_bar.dart';
import 'package:vibe_trade_v1/widgets/app_bar/trust_app_bar_actions.dart';
import 'package:vibe_trade_v1/widgets/responsive_layout.dart';
import 'package:vibe_trade_v1/widgets/warning_modal_btn.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;
  bool _isLoged = false;
  bool _checkingSession = true;

  final List<Widget> _pages = const [
    HomePage(),
    ReelsPage(),
    ChatPage(),
    ProfilePage(),
  ];

  final List<_MainNavItem> _navigationItems = const [
    _MainNavItem(label: 'Home', icon: Icons.home_outlined),
    _MainNavItem(label: 'Reels', icon: Icons.video_collection_outlined),
    _MainNavItem(label: 'Chat', icon: Icons.chat_bubble_outline),
    _MainNavItem(label: 'Profile', icon: Icons.person_outline),
  ];

  @override
  void initState() {
    super.initState();
    MainTabBus.selectTab = _selectTabSafely;
    AuthService.isLoggedInNotifier.addListener(_handleSessionChanged);
    AppTheme.modeNotifier.addListener(_handleThemeChanged);
    _hydrateSession();
  }

  void _selectTabSafely(int index) {
    if (!mounted) return;
    if (!_isLoged || index < 0 || index >= _pages.length) return;
    setState(() => _selectedIndex = index);
  }

  Future<void> _hydrateSession() async {
    final isLoggedIn = await AuthService.hydrateSession();
    if (!mounted) {
      return;
    }

    setState(() {
      _isLoged = isLoggedIn;
      _checkingSession = false;
    });
    if (isLoggedIn) {
      unawaited(StoreService.refreshStoresFromWorkspace());
      unawaited(SavedOffersService.hydrateFromServer());
      unawaited(_refreshNotificationsSilently());
    } else {
      SavedOffersService.clear();
      NotificationsService.clear();
    }
  }

  void _handleSessionChanged() {
    if (!mounted) {
      return;
    }

    final wasLoggedIn = _isLoged;
    final isLoggedIn = AuthService.isLoggedInNotifier.value;

    setState(() {
      _isLoged = isLoggedIn;
      _selectedIndex = 0;
    });

    if (isLoggedIn) {
      unawaited(StoreService.refreshStoresFromWorkspace());
      unawaited(SavedOffersService.hydrateFromServer());
      unawaited(_refreshNotificationsSilently());
    } else {
      SavedOffersService.clear();
      NotificationsService.clear();
    }

    if (wasLoggedIn && !isLoggedIn) {
      // La sesion se invalido (probablemente el backend respondio 401).
      // Redirigimos al login y avisamos al usuario.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tu sesion expiro. Inicia sesion nuevamente.'),
          ),
        );
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/signin', (route) => false);
      });
    }
  }

  void _handleThemeChanged() {
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  Future<void> _refreshNotificationsSilently() async {
    try {
      await NotificationsService.fetchNotifications();
    } catch (_) {
      // Offline/401 transient errors should not block app startup.
    }
  }

  @override
  void dispose() {
    MainTabBus.selectTab = null;
    AuthService.isLoggedInNotifier.removeListener(_handleSessionChanged);
    AppTheme.modeNotifier.removeListener(_handleThemeChanged);
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (_isLoged) {
      setState(() => _selectedIndex = index);
    } else {
      _showDialog();
    }
  }

  void _showDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: AppTheme.primaryColor,
        title: Text(
          'Ups',
          style: TextStyle(
            color: AppTheme.foregroundColor,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Debes tener una cuenta para acceder a esta seccion.',
              style: TextStyle(color: AppTheme.foregroundColor),
            ),
            const SizedBox(height: 15),
            WarningModalBtn(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/signin');
              },
              text: 'Iniciar Sesion',
              icon: Icon(Icons.login, color: AppTheme.primaryColor),
            ),
            const SizedBox(height: 10),
            WarningModalBtn(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/signup');
              },
              text: 'Crear Cuenta',
              icon: Icon(Icons.person_add, color: AppTheme.primaryColor),
            ),
            const SizedBox(height: 10),
            WarningModalBtn(
              onPressed: () {
                Navigator.pop(context);
              },
              text: 'Continuar',
              icon: Icon(Icons.next_plan, color: AppTheme.primaryColor),
            ),
          ],
        ),
      ),
    );
  }

  void _showNotifications() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const NotificationsPage(),
      ),
    );
  }

  Widget _notificationButton() {
    return ValueListenableBuilder(
      valueListenable: NotificationsService.itemsNotifier,
      builder: (context, _, __) {
        final unread = NotificationsService.unreadCount;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              tooltip: 'Notificaciones',
              onPressed: _showNotifications,
              icon: Icon(
                Icons.notifications_none_outlined,
                color: AppTheme.textPrimary,
              ),
            ),
            if (unread > 0)
              Positioned(
                right: 5,
                top: 5,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppTheme.appBgColor, width: 1.5),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    unread > 99 ? '99+' : '$unread',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  void _openCatalogSearch() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const CatalogSearchPage(),
      ),
    );
  }

  bool get _isHomeTab => _selectedIndex == 0;

  /// Acciones a la derecha del titulo "Ofertas" en Home: campana o boton
  /// de inicio de sesion segun el estado de la sesion.
  List<Widget> _homeAppBarActions() {
    if (_isLoged) {
      return [
        _notificationButton(),
      ];
    }
    return [
      Padding(
        padding: const EdgeInsets.only(right: 4),
        child: TextButton.icon(
          onPressed: () => Navigator.pushNamed(context, '/signin'),
          icon: Icon(Icons.login, color: AppTheme.foregroundColor, size: 16),
          label: Text(
            'Iniciar Sesion',
            style: TextStyle(
              color: AppTheme.foregroundColor,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
          style: TextButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          ),
        ),
      ),
    ];
  }

  Widget _buildDesktopShell() {
    if (_checkingSession) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppTheme.appBgColor,
      body: SafeArea(
        child: Row(
          children: [
            Container(
              width: 260,
              margin: const EdgeInsets.all(18),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.foregroundColor,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.isDark
                        ? Colors.black.withValues(alpha: 0.4)
                        : Colors.black.withValues(alpha: 0.05),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: AppTheme.selectedColor,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.auto_awesome_motion_outlined,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'VibeTrade',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Navegacion',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                      color: AppTheme.textMuted,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: ListView.separated(
                      itemCount: _navigationItems.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final item = _navigationItems[index];
                        final isSelected = _selectedIndex == index;

                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: () => _onItemTapped(index),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.selectedColor
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: isSelected
                                      ? AppTheme.primaryColor.withValues(
                                          alpha: 0.18,
                                        )
                                      : Colors.transparent,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    item.icon,
                                    color: isSelected
                                        ? AppTheme.primaryColor
                                        : AppTheme.textSecondary,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    item.label,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: isSelected
                                          ? AppTheme.primaryColor
                                          : AppTheme.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (!_isLoged)
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(context, '/signin');
                        },
                        label: Text(
                          'Iniciar Sesion',
                          style: TextStyle(color: AppTheme.foregroundColor),
                        ),
                        icon: Icon(
                          Icons.login,
                          color: AppTheme.foregroundColor,
                        ),
                        style: TextButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(6, 18, 18, 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 18,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.foregroundColor,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: _isHomeTab
                          ? _DesktopOffersHeader(
                              onSearchTap: _openCatalogSearch,
                              actions: _homeAppBarActions(),
                            )
                          : Row(
                              children: [
                                Expanded(
                                  child: TrustAppBarActions(
                                    isLoggedIn: _isLoged,
                                    onNotificationsTap: _showNotifications,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  Expanded(
                    child: ResponsiveContent(
                      padding: const EdgeInsets.fromLTRB(6, 18, 18, 18),
                      child: _pages[_selectedIndex],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileShell() {
    if (_checkingSession) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final PreferredSizeWidget appBar = _isHomeTab
        ? AppBar(
            toolbarHeight: HomeOffersAppBar.toolbarHeight,
            automaticallyImplyLeading: false,
            elevation: 0,
            scrolledUnderElevation: 0,
            shadowColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            backgroundColor: AppTheme.appBgColor,
            flexibleSpace: HomeOffersAppBarBody(
              onSearchTap: _openCatalogSearch,
              actions: _homeAppBarActions(),
            ),
          )
        : AppBar(
            backgroundColor: AppTheme.appBgColor,
            shape: Border(
              bottom: BorderSide(color: AppTheme.dividerColor, width: 1),
            ),
            automaticallyImplyLeading: false,
            centerTitle: false,
            titleSpacing: 12,
            title: _isLoged ? const _MobileGreetingTitle() : null,
            actions: [
              if (_isLoged)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _notificationButton(),
                ),
              if (!_isLoged)
                Padding(
                  padding: const EdgeInsets.only(right: 10.0),
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/signin');
                    },
                    label: Text(
                      'Iniciar Sesion',
                      style: TextStyle(color: AppTheme.foregroundColor),
                    ),
                    icon: Icon(Icons.login, color: AppTheme.foregroundColor),
                    style: TextButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),
            ],
          );

    return Scaffold(
      backgroundColor: AppTheme.appBgColor,
      appBar: appBar,
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: AppTheme.dividerColor, width: 1)),
        ),
        child: BottomNavigationBar(
          backgroundColor: AppTheme.appBgColor,
          selectedItemColor: AppTheme.primaryColor,
          unselectedItemColor: AppTheme.textSecondary,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(
              icon: Icon(Icons.video_collection),
              label: 'Reels',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (ResponsiveLayout.isDesktop(context)) {
      return _buildDesktopShell();
    }

    return _buildMobileShell();
  }
}

class _MainNavItem {
  final String label;
  final IconData icon;

  const _MainNavItem({required this.label, required this.icon});
}

class _MobileGreetingTitle extends StatelessWidget {
  const _MobileGreetingTitle();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: AuthService.currentUserNotifier,
      builder: (context, user, _) {
        final name = (user?.name ?? '').trim();
        final firstName = name.isEmpty ? 'Usuario' : name.split(' ').first;
        return Row(
          children: [
            CircleAvatar(
              radius: 17,
              backgroundColor: AppTheme.primaryColor,
              child: Text(
                firstName[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hola,',
                    style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      height: 1.1,
                    ),
                  ),
                  Text(
                    firstName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Cabecera de Home en escritorio: titulo "Ofertas", caja "Buscar" clickable
/// y acciones a la derecha. Mantiene la misma jerarquia visual que el app bar
/// movil.
class _DesktopOffersHeader extends StatelessWidget {
  final VoidCallback onSearchTap;
  final List<Widget> actions;

  const _DesktopOffersHeader({
    required this.onSearchTap,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Ofertas',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Material(
            color: AppTheme.appBgColor,
            borderRadius: BorderRadius.circular(999),
            child: InkWell(
              onTap: onSearchTap,
              borderRadius: BorderRadius.circular(999),
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppTheme.dividerColor),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search, size: 18, color: AppTheme.textMuted),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Buscar tiendas, productos o servicios...',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (actions.isNotEmpty) ...[
          const SizedBox(width: 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: actions,
          ),
        ],
      ],
    );
  }
}
