import 'package:flutter/material.dart';
import '../widgets/icon_button_card.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final appBarHeight = screenHeight * 0.13;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: appBarHeight,
        leadingWidth: screenWidth * 0.07,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset(
            'assets/images/logo.png',
            fit: BoxFit.contain,
          ),
        ),
        actions: [
          Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.only(top: 8.0, right: 8.0),
              child: IconButton(
                icon: const Icon(Icons.settings, size: 20),
                onPressed: () {},
              ),
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final itemHeight = (constraints.maxHeight - 80) / 3;
          final itemWidth = (constraints.maxWidth - 48) / 2;
          final aspectRatio = itemWidth / itemHeight;

          return Padding(
            padding: const EdgeInsets.all(4.0),
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
              childAspectRatio: aspectRatio,
              physics: const NeverScrollableScrollPhysics(),
              children: const [
                IconButtonCard(icon: Icons.groups_outlined, label: 'Customers'),
                IconButtonCard(icon: Icons.table_chart, label: 'Breaksheets'),
                IconButtonCard(icon: Icons.folder, label: 'Projects'),
                IconButtonCard(icon: Icons.menu_book, label: 'Codes'),
                IconButtonCard(icon: Icons.list_alt, label: 'Lists'),
                IconButtonCard(icon: Icons.manage_accounts, label: 'Management'),
              ],
            ),
          );
        },
      ),
    );
  }
}