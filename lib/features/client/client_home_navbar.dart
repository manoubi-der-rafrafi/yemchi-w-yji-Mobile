import 'package:flutter/material.dart';
// Import your section widgets
import 'pages/livrer_page.dart';
import 'pages/commandes_page.dart';
import 'pages/amis_page.dart';
import 'pages/profil_page.dart';

class ClientHome extends StatefulWidget {
  const ClientHome({super.key});

  @override
  _ClientHomeState createState() => _ClientHomeState();
}

class _ClientHomeState extends State<ClientHome> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    LivrerPage(),        // Page for "Livrer"
    CommandesPage(),     // Page for "Commandes"
    AmisPage(),          // Page for "Amis"
    ProfilPage(),        // Page for "Profil" 
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        onTap: (int index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.local_shipping),
            label: 'Livrer',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'Commandes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Amis',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
