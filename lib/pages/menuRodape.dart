import 'package:flutter/material.dart';
import 'package:projeto_elifone/theme/app_theme.dart';
import 'package:projeto_elifone/model/agendamento_model.dart';
import 'package:projeto_elifone/pages/HomePage.dart';
import 'package:projeto_elifone/pages/adicionarEstoque.dart';
import 'package:projeto_elifone/pages/agenda_page.dart';
import 'package:projeto_elifone/pages/detalhes_servico_page.dart';
import 'package:projeto_elifone/pages/orcamento_page.dart';

class MenuRodape extends StatefulWidget {
  const MenuRodape({super.key});

  @override
  State<MenuRodape> createState() => _MenuRodapeState();
}

class _MenuRodapeState extends State<MenuRodape> {
  int _op = 0;
  AgendamentoModel? _servicoSelecionado;

  final List<String> pageTitles = [
    'Home',
    'Agenda',
    'Gerenciamento de Estoque',
    'Orcamentos',
    'Detalhes do Servico',
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 800;
    final drawerWidth = (screenWidth * 0.82).clamp(240.0, 360.0).toDouble();
    final pages = [
      const MyHomePage(),
      AgendaPage(
        onAbrirDetalhes: (servico) {
          setState(() {
            _servicoSelecionado = servico;
            _op = 4;
          });
        },
      ),
      const AdicionarEstoquePage(),
      const OrcamentoPage(),
      _servicoSelecionado == null
          ? const AgendaPage()
          : DetalhesServicoPage(
              key: ValueKey(_servicoSelecionado!.id),
              agendamento: _servicoSelecionado!,
              onVoltar: () => setState(() => _op = 1),
            ),
    ];

    return Scaffold(
      appBar: !isMobile
          ? null
          : AppBar(
              backgroundColor: AppColors.primary,
              title: Text(pageTitles[_op]),
              actions: [
                IconButton(
                  icon: const Icon(Icons.inventory_2),
                  onPressed: () => setState(() => _op = 2),
                ),
              ],
            ),
      drawer: isMobile
          ? Drawer(
              width: drawerWidth,
              child: _menuContent(isDrawer: true),
            )
          : null,
      body: Row(
        children: [
          if (!isMobile)
            Container(
              width: 260,
              color: AppColors.primary,
              child: _menuContent(isDrawer: false),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isMobile)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 20,
                    ),
                    color: AppColors.primary,
                    child: Text(
                      pageTitles[_op],
                      style: const TextStyle(
                        fontSize: 24,
                        color: AppColors.invertedText,
                      ),
                    ),
                  ),
                const Divider(height: 1),
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

  Widget _menuContent({required bool isDrawer}) {
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Elifone',
            style: TextStyle(
              color: isDrawer ? AppColors.primary : AppColors.invertedText,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        _menuItem(Icons.home, 'Home', 0, isDrawer),
        _menuItem(Icons.calendar_month, 'Agenda', 1, isDrawer),
        _menuItem(Icons.inventory_2, 'Gerenciamento de Estoque', 2, isDrawer),
        _menuItem(Icons.request_quote, 'Orcamentos', 3, isDrawer),
      ],
    );
  }

  Widget _menuItem(IconData icon, String title, int index, bool isDrawer) {
    final selecionado = _op == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: selecionado ? AppColors.surfaceAlt : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Material(
            color: Colors.transparent,
            child: ListTile(
              leading: Icon(
                icon,
                color: selecionado
                    ? AppColors.primary
                    : isDrawer
                    ? AppColors.secondary
                    : AppColors.invertedText,
              ),
              title: Text(
                title,
                style: TextStyle(
                  color: selecionado
                      ? AppColors.primary
                      : isDrawer
                      ? AppColors.secondary
                      : AppColors.invertedText,
                  fontWeight: selecionado
                      ? FontWeight.w700
                      : FontWeight.normal,
                ),
              ),
              onTap: () {
                setState(() => _op = index);
                if (isDrawer) Navigator.pop(context);
              },
            ),
          ),
        ),
      ),
    );
  }
}
