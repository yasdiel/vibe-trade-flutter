import 'package:flutter/material.dart';
import 'package:vibe_trade_v1/screens/account_screen.dart';
import 'package:vibe_trade_v1/screens/saved_offerts.dart';
import 'package:vibe_trade_v1/screens/stores_screen.dart';
import 'package:vibe_trade_v1/theme/app_theme.dart';
import 'package:vibe_trade_v1/widgets/responsive_layout.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int _selectedIndex = 0;

  final List<String> _tabs = ['Cuenta', 'Mis Reels', 'Guardados', 'Tiendas'];

  final List<Widget> _tabContent = const [
    AccountScreen(),
    Center(child: Text('Contenido de Mis Reels')),
    SavedOfferts(),
    StoresScreen(),
  ];

  Widget _buildDesktopTabs() {
    return Row(
      children: List.generate(_tabs.length, (index) {
        final isSelected = _selectedIndex == index;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: index == _tabs.length - 1 ? 0 : 12),
            child: GestureDetector(
              onTap: () => setState(() => _selectedIndex = index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.selectedColor
                      : AppTheme.foregroundColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primaryColor
                        : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  _tabs[index],
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildMobileTabs() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 3.5,
      ),
      itemCount: _tabs.length,
      itemBuilder: (context, index) {
        final isSelected = _selectedIndex == index;

        return GestureDetector(
          onTap: () => setState(() => _selectedIndex = index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.selectedColor
                  : AppTheme.foregroundColor,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: isSelected
                    ? AppTheme.primaryColor
                    : Colors.transparent,
                width: 1.5,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              _tabs[index],
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 0 : 16,
            vertical: 12,
          ),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: AppTheme.foregroundColor,
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () =>
                      Navigator.pushReplacementNamed(context, '/home'),
                  icon: const Icon(Icons.arrow_back),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Perfil',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: isDesktop ? 0 : 16),
          child: isDesktop ? _buildDesktopTabs() : _buildMobileTabs(),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: KeyedSubtree(
              key: ValueKey(_selectedIndex),
              child: _tabContent[_selectedIndex],
            ),
          ),
        ),
      ],
    );
  }
}
