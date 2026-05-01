import 'package:flutter/material.dart';
import 'package:vibe_trade_v1/pages/chat_page.dart';
import 'package:vibe_trade_v1/pages/home_page.dart';
import 'package:vibe_trade_v1/pages/profile_page.dart';
import 'package:vibe_trade_v1/pages/reels_page.dart';
import 'package:vibe_trade_v1/services/auth_service.dart';
import 'package:vibe_trade_v1/theme/app_theme.dart';
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
    AuthService.isLoggedInNotifier.addListener(_handleSessionChanged);
    AppTheme.modeNotifier.addListener(_handleThemeChanged);
    _hydrateSession();
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
  }

  void _handleSessionChanged() {
    if (!mounted) {
      return;
    }

    setState(() {
      _isLoged = AuthService.isLoggedInNotifier.value;
    });
  }

  void _handleThemeChanged() {
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  @override
  void dispose() {
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
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notificaciones proximamente')),
    );
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
                      child: Row(
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

    return Scaffold(
      backgroundColor: AppTheme.appBgColor,
      appBar: AppBar(
        backgroundColor: AppTheme.appBgColor,
        shape: Border(
          bottom: BorderSide(color: AppTheme.dividerColor, width: 1),
        ),
        automaticallyImplyLeading: false,
        titleSpacing: 12,
        title: _isLoged
            ? TrustAppBarActions(
                isLoggedIn: true,
                onNotificationsTap: _showNotifications,
              )
            : null,
        actions: [
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
      ),
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
