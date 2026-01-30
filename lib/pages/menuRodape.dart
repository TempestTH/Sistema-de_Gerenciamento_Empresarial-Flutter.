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
  final List<String> pageTitles = [
    'Home',
    'Entrada de Material',
    'Saída de Material',
    'Adicionar Material',
  ];
  final List<Widget> pages = const [
    MyHomePage(),
    AdicionarEstoquePage(Entrada: true, Saida: false),
    AdicionarEstoquePage(Entrada: false, Saida: true),
    AdicionarMaterialPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 800;

    return Scaffold(
      appBar: !isMobile
          ? null
          : AppBar(
              backgroundColor: Color(0xFFB3E5FC),
              title: isMobile
                  ? Text(pageTitles[_op]) // sem título no mobile
                  : const SizedBox(),

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
              color: Colors.lightBlue[200],
              child: _menuContent(isDrawer: false),
            ),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // TÍTULO DA PÁGINA
                isMobile
                    ? SizedBox()
                    : Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 20,
                        ),
                        color: const Color(0xFFB3E5FC), // mesma cor da AppBar
                        child: Text(
                          pageTitles[_op],
                          style: const TextStyle(
                            fontSize: 24,
                            color: Colors.black87,
                          ),
                        ),
                      ),

                const Divider(height: 1),

                // CONTEÚDO DA PÁGINA
                Expanded(
                  child: IndexedStack(index: _op, children: pages),
                ),
              ],
            ),
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
            'Elifone',
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
    final bool selecionado = _op == index;
    return _menuWrapper(
      child: Container(
        decoration: BoxDecoration(
          color: selecionado
              ? const Color(0xFFB3E5FC) // cor quando selecionado
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          leading: Icon(
            icon,
            color: selecionado ? const Color(0xFF0D47A1) : null,
          ),
          title: Text(
            title,
            style: TextStyle(
              color: selecionado ? const Color(0xFF0D47A1) : null,
              fontWeight: selecionado ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          onTap: () {
            setState(() => _op = index);
            if (isDrawer) Navigator.pop(context);
          },
        ),
      ),
    );
  }

  Widget _submenuMaterial(bool isDrawer, String text) {
    final bool materialSelecionado = (_op == 1 || _op == 2 || _op == 3);
    final bool destacarMaterial = materialSelecionado && !_expandMaterial;
    return _menuWrapper(
      child: Container(
        decoration: BoxDecoration(
          color: destacarMaterial
              ? const Color(0xFFB3E5FC)
              : Colors.transparent,
          border: Border.all(
            color: _expandMaterial
                ? const Color(0xFF0D47A1)
                : Colors.transparent,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(
            dividerColor: Colors.transparent, // 🚫 remove as linhas
          ),
          child: ExpansionTile(
            backgroundColor: Colors.transparent,
            collapsedBackgroundColor: Colors.transparent,
            tilePadding: const EdgeInsets.symmetric(horizontal: 16),
            childrenPadding: const EdgeInsets.only(bottom: 8),
            leading: Icon(
              Icons.settings,
              color: _expandMaterial ? const Color(0xFF0D47A1) : null,
            ),
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
          ),
        ),
      ),
    );
  }

  Widget _submenuItem(String title, int index, bool isDrawer, IconData icon) {
    final bool selecionado = _op == index;
    return _menuWrapper(
      child: Container(
        decoration: BoxDecoration(
          color: selecionado
              ? const Color(0xFFB3E5FC) // cor quando selecionado
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.only(left: 32),
          leading: Icon(
            icon,
            color: selecionado ? const Color(0xFF0D47A1) : null,
          ),
          title: Text(
            title,
            style: TextStyle(
              color: selecionado ? const Color(0xFF0D47A1) : null,
              fontWeight: selecionado ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          onTap: () {
            setState(() => _op = index);
            if (isDrawer) Navigator.pop(context);
          },
        ),
      ),
    );
  }

  Widget _menuWrapper({required Widget child}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ClipRRect(borderRadius: BorderRadius.circular(12), child: child),
    );
  }
}
