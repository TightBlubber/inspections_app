import 'package:flutter/material.dart';

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Page'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, size: 20),
            onPressed: () {},
          ),
        ]
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final itemHeight = (constraints.maxHeight - 80) / 3;
          final itemWidth = (constraints.maxWidth - 48) / 2;
          final aspectRatio = itemWidth / itemHeight;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: aspectRatio,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildIconButton(Icons.groups_outlined, "Customers"),
                _buildIconButton(Icons.table_chart, "Breaksheets"),
                _buildIconButton(Icons.folder, "Projects"),
                _buildIconButton(Icons.menu_book, "Codes"),
                _buildIconButton(Icons.list_alt, "Lists"),
                _buildIconButton(Icons.manage_accounts, "Management"),
              ]
            )
          );
        }
      )
      
    );
  }

  Widget _buildIconButton(IconData icon, String label) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.all(20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Icon(icon, size: 40)
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 14)),
      ],
    );
  }
}