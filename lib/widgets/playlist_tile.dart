import 'package:flutter/material.dart';
import '../models/playlist.dart';

class PlaylistTile extends StatelessWidget {
  final Playlist playlist;
  final VoidCallback? onTap;
  const PlaylistTile({super.key, required this.playlist, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(child: Text(playlist.icon)),
      title: Text(playlist.name),
      subtitle: Text('${playlist.songIds.length} songs'),
      onTap: onTap,
    );
  }
}
