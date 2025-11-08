import 'package:flutter/material.dart';
import '../services/music_service.dart';
import '../widgets/song_tile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final music = MusicService();
  String query = '';

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
    final filtered = music.allSongs.where((s) {
      final q = query.toLowerCase();
      return s.title.toLowerCase().contains(q) || s.artist.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search songs or artists',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => query = v),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (_, i) => SongTile(song: filtered[i]),
            ),
          ),
        ],
      ),
    );
  }
}
