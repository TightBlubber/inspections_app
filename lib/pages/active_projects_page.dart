import 'package:flutter/material.dart';

class ActiveProjectsPage extends StatelessWidget {
  const ActiveProjectsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Projects'),
      ),
      body: const Center(
        child: Text('Active Projects — coming soon'),
      ),
    );
  }
}
