import 'package:flutter/material.dart';
import '../services/music_service.dart';
import '../widgets/song_tile.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final music = MusicService();

  @override
  void initState() {
    super.initState();
    music.addListener(_onChange);
  }

  @override
  void dispose() {
    music.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final favs = music.favorites;
    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: favs.isEmpty
        ? const Center(child: Text('No favorites yet'))
        : ListView.builder(
            itemCount: favs.length,
            itemBuilder: (_, i) => SongTile(song: favs[i]),
          ),
    );
  }
}
