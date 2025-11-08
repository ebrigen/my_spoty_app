import 'package:flutter/material.dart';
import '../models/song.dart';
import '../services/music_service.dart';

class SongTile extends StatefulWidget {
  final Song song;
  const SongTile({super.key, required this.song});

  @override
  State<SongTile> createState() => _SongTileState();
}

class _SongTileState extends State<SongTile> {
  final music = MusicService();

  void _playOrDownload() async {
    if (widget.song.localPath == null) {
      await music.downloadSong(widget.song);
      if (widget.song.localPath != null) {
        music.addToQueue(widget.song);
        await music.playSong(widget.song);
      }
    } else {
      music.addToQueue(widget.song);
      await music.playSong(widget.song);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.song;
    return ListTile(
      leading: const CircleAvatar(child: Icon(Icons.music_note)),
      title: Text(s.title),
      subtitle: Text(s.artist),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(s.isFavorite ? Icons.favorite : Icons.favorite_border),
            onPressed: () {
              music.toggleFavorite(s);
              setState(() {});
            },
          ),
          if (s.isDownloading)
            const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            IconButton(
              icon: Icon(s.localPath == null ? Icons.download : Icons.play_arrow),
              onPressed: _playOrDownload,
            ),
        ],
      ),
    );
  }
}
