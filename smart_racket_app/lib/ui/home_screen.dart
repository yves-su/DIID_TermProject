import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/home_provider.dart';
import 'settings_screen.dart';
import 'result_tab.dart';
import 'graph_tab.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Smart Racket V3"),
          bottom: const TabBar(
            tabs: [
              Tab(text: "Results"),
              Tab(text: "6-Axis Graph"),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsScreen()),
                );
              },
            )
          ],
        ),
        body: const TabBarView(
          children: [
            ResultTab(),
            GraphTab(),
          ],
        ),
      ),
    );
  }
}
