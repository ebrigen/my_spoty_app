import 'package:flutter/material.dart';
import '../services/music_service.dart';
import '../widgets/playlist_tile.dart';
import 'playlist_detail_screen.dart';

class PlaylistsScreen extends StatefulWidget {
  const PlaylistsScreen({super.key});

  @override
  State<PlaylistsScreen> createState() => _PlaylistsScreenState();
}

class _PlaylistsScreenState extends State<PlaylistsScreen> {
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

  void _createPlaylistDialog() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Create playlist'),
        content: TextField(controller: controller, decoration: const InputDecoration(hintText: 'Playlist name')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Create')),
        ],
      ),
    );
    if (name != null && name.trim().isNotEmpty) {
      music.createPlaylist(name.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Playlists'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _createPlaylistDialog),
        ],
      ),
      body: ListView.builder(
        itemCount: music.playlists.length,
        itemBuilder: (_, i) {
          final p = music.playlists[i];
          return PlaylistTile(
            playlist: p,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => PlaylistDetailScreen(playlistId: p.id)),
            ),
          );
        },
      ),
    );
  }
}
