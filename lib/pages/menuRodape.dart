import 'package:flutter/material.dart';
import 'package:projeto_elifone/pages/HomePage.dart';
import 'package:projeto_elifone/pages/adicionarEstoque.dart';
import 'package:projeto_elifone/pages/adicionarMaterial.dart';

class MenuRodape extends StatefulWidget {
  const MenuRodape({super.key});

  @override
  State<MenuRodape> createState() => _MenuRodapeState();
}

class _MenuRodapeState extends State<MenuRodape> {
  int _op = 0;
  bool _expandMaterial = false;

  final List<Widget> pages = const [
    MyHomePage(),
    AdicionarEstoquePage(Entrada: true, Saida: false),
    AdicionarEstoquePage(Entrada: false, Saida: true),
    AdicionarMaterialPage()
  ];

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 800;

    return Scaffold(
      appBar: AppBar(
        title: isMobile
            ? const SizedBox() // sem título no mobile
            : const Text('Elifone'),

        // Ícone só no mobile
        actions: isMobile
            ? [
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    setState(() => _op = 3);
                  },
                ),
              ]
            : null,
      ),

      // Drawer no mobile
      drawer: isMobile
          ? Drawer(
              width: MediaQuery.of(context).size.width * 0.7,
              child: _menuContent(isDrawer: true),
            )
          : null,

      body: Row(
        children: [
          // Sidebar fixa no desktop
          if (!isMobile)
            Container(
              width: 260,
              color: Colors.grey.shade100,
              child: _menuContent(isDrawer: false),
            ),

          Expanded(
            child: IndexedStack(index: _op, children: pages),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // CONTEÚDO DO MENU (usado no Drawer e na Sidebar)
  // =====================================================
  Widget _menuContent({required bool isDrawer}) {
    return ListView(
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Menu',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ),

        _menuItem(Icons.home, 'Home', 0, isDrawer),
        _submenuMaterial(isDrawer, "Material"),

        // 🔽 SUBMENU
      ],
    );
  }

  Widget _menuItem(IconData icon, String title, int index, bool isDrawer) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      selected: _op == index,
      onTap: () {
        setState(() => _op = index);
        if (isDrawer) Navigator.pop(context);
      },
    );
  }

  Widget _submenuMaterial(bool isDrawer, String text) {
    return ExpansionTile(
      leading: const Icon(Icons.settings),
      title: Text(text),
      initiallyExpanded: _expandMaterial,
      onExpansionChanged: (value) {
        setState(() => _expandMaterial = value);
      },
      children: [
        _submenuItem('Entrada', 1, isDrawer, Icons.input),
        _submenuItem('Saida', 2, isDrawer, Icons.output),
        _submenuItem('Adicionar', 3, isDrawer, Icons.add),
      ],
    );
  }

  Widget _submenuItem(String title, int index, bool isDrawer, IconData icon) {
    return ListTile(
      leading: Icon(icon),
      contentPadding: const EdgeInsets.only(left: 72),
      title: Text(title),
      selected: _op == index,
      onTap: () {
        setState(() => _op = index);
        if (isDrawer) Navigator.pop(context);
      },
    );
  }
}
