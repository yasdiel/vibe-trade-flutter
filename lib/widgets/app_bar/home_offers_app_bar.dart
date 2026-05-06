import 'package:flutter/material.dart';
import 'package:vibe_trade_v1/theme/app_theme.dart';

/// Contenido visual del header Home (Ofertas + buscador). Usar dentro de
/// [AppBar.flexibleSpace] con [AppBar.toolbarHeight] == [toolbarHeight].
class HomeOffersAppBarBody extends StatelessWidget {
  final VoidCallback onSearchTap;
  final List<Widget> actions;

  const HomeOffersAppBarBody({
    super.key,
    required this.onSearchTap,
    this.actions = const [],
  });

  static const double toolbarHeight = 132;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final padBottom = bottomInset > 0 ? 8.0 : 10.0;

    return Material(
      color: AppTheme.appBgColor,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppTheme.dividerColor, width: 1),
          ),
        ),
        padding: EdgeInsets.fromLTRB(14, 6, 8, padBottom),
        alignment: Alignment.centerLeft,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    'Ofertas',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                if (actions.isNotEmpty)
                  Flexible(
                    fit: FlexFit.loose,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: actions,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            _SearchTrigger(onTap: onSearchTap),
          ],
        ),
      ),
    );
  }
}

/// Combina [PreferredSize] + [HomeOffersAppBarBody] (p. ej. escritorio).
class HomeOffersAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onSearchTap;
  final List<Widget> actions;

  const HomeOffersAppBar({
    super.key,
    required this.onSearchTap,
    this.actions = const [],
  });

  static double get toolbarHeight => HomeOffersAppBarBody.toolbarHeight;

  @override
  Size get preferredSize =>
      const Size.fromHeight(HomeOffersAppBarBody.toolbarHeight);

  @override
  Widget build(BuildContext context) {
    return HomeOffersAppBarBody(onSearchTap: onSearchTap, actions: actions);
  }
}

class _SearchTrigger extends StatelessWidget {
  final VoidCallback onTap;

  const _SearchTrigger({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Abrir busqueda de tiendas, productos y servicios',
      child: Material(
        color: AppTheme.foregroundColor,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppTheme.dividerColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: AppTheme.isDark ? 0.3 : 0.05,
                  ),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  Icons.search,
                  size: 18,
                  color: AppTheme.textMuted,
                ),
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
    );
  }
}
