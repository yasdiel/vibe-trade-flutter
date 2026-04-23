import 'package:flutter/material.dart';
import 'package:vibe_trade_v1/pages/chat_page.dart';
import 'package:vibe_trade_v1/pages/home_page.dart';
import 'package:vibe_trade_v1/pages/profile_page.dart';
import 'package:vibe_trade_v1/pages/reels_page.dart';
import 'package:vibe_trade_v1/theme/app_theme.dart';
import 'package:vibe_trade_v1/widgets/intro_btn.dart';
import 'package:vibe_trade_v1/widgets/warning_modal_btn.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0; // índice de la pestaña activa
  bool isLoged = false; // estado de inicio de sesión (falso por defecto)

  // Lista de pestañas pata iterar sobre ellas
  final List<Widget> _pages = [
    HomePage(),
    ReelsPage(),
    ChatPage(),
    ProfilePage(),
  ];

  // funcion que verifica si el usuario esta logeado o no para dejarlo acceder a las pestañas o mostrarle un mensaje de que debe iniciar sesión
  void _onItemTapped(int index) {
    if (isLoged) {
      setState(() => _selectedIndex = index);
    } else {
      _showDialog();
    }
  }

  // funcion que muestra un modal advirtiendote que debes tener cuenta para acceder a las pestañas
  void _showDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: AppTheme.primaryColor,
        title: Text(
          '¡Ups!',
          style: TextStyle(
            color: AppTheme.foregroundColor,
            fontSize: 20,
            fontWeight: FontWeight(700),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Debes tener una cuenta para acceder a esta sección.',
              style: TextStyle(color: AppTheme.foregroundColor),
            ),
            SizedBox(height: 15),
            WarningModalBtn(
              onPressed: () {},
              text: 'Iniciar Sesion',
              icon: Icon(Icons.login, color: AppTheme.primaryColor),
            ),
            SizedBox(height: 10),
            WarningModalBtn(
              onPressed: () {},
              text: 'Crear Cuenta',
              icon: Icon(Icons.person_add, color: AppTheme.primaryColor),
            ),
            SizedBox(height: 10),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        shape: Border(bottom: BorderSide(color: Colors.grey, width: 1)),
        automaticallyImplyLeading: false,
        actions: [
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
                  borderRadius: BorderRadiusGeometry.circular(10),
                ),
                padding: EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              ),
            ),
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey, width: 1)),
        ),
        child: BottomNavigationBar(
          backgroundColor: AppTheme.foregroundColor,
          selectedItemColor: AppTheme.primaryColor,
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          items: [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(
              icon: Icon(Icons.video_collection),
              label: 'Reels',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
          currentIndex: _selectedIndex,
          onTap: (index) => _onItemTapped(index),
        ),
      ),
    );
  }
}
