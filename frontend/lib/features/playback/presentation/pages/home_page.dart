import 'package:flutter/material.dart';
import 'package:otune/features/playback/presentation/widgets/player_widget.dart';

/// Pantalla principal y punto de partida de la experiencia Otune.
class HomePage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Otune'), centerTitle: false),
      body: const SafeArea(
        child: Center(child: SingleChildScrollView(child: PlayerWidget())),
      ),
    );
  }
}
