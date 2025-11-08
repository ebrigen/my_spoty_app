import 'package:flutter/material.dart';
import '../services/music_service.dart';
import '../models/playlist.dart';
import '../widgets/song_tile.dart';

class PlaylistDetailScreen extends StatefulWidget {
  final String playlistId;
  const PlaylistDetailScreen({super.key, required this.playlistId});

  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends State<PlaylistDetailScreen> {
  final music = MusicService();

  Playlist? get playlist => music.playlists.firstWhere((p) => p.id == widget.playlistId, orElse: () => Playlist(id: '', name: 'Unknown', songIds: []));

  void _addSongDialog() async {
    final selected = await showDialog<String>(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text('Add song'),
        children: [
          for (final s in music.allSongs)
            SimpleDialogOption(
              child: Text('${s.title} — ${s.artist}'),
              onPressed: () => Navigator.pop(context, s.id),
            ),
        ],
      ),
    );
    if (selected != null && playlist != null) {
      music.addToPlaylist(playlist!.name, music.allSongs.firstWhere((s) => s.id == selected));
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = playlist;
    if (p == null || p.id.isEmpty) {
      return const Scaffold(body: Center(child: Text('Playlist not found')));
    }
    final songs = music.songsInPlaylist(p);

    return Scaffold(
      appBar: AppBar(
        title: Text(p.name),
        actions: [IconButton(icon: const Icon(Icons.add), onPressed: _addSongDialog)],
      ),
      body: ListView.builder(
        itemCount: songs.length,
        itemBuilder: (_, i) => SongTile(song: songs[i]),
      ),
    );
  }
}
