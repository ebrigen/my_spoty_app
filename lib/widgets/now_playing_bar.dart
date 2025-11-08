import 'package:flutter/material.dart';
import '../services/music_service.dart';
import '../screens/now_playing_screen.dart';

class NowPlayingBar extends StatefulWidget {
  const NowPlayingBar({super.key});

  @override
  State<NowPlayingBar> createState() => _NowPlayingBarState();
}

class _NowPlayingBarState extends State<NowPlayingBar> {
  final music = MusicService();

  @override
  void initState() {
    super.initState();
    music.attachAudioListeners();
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
    final song = music.currentSong;
    if (song == null) return const SizedBox.shrink();

    return Material(
      color: Colors.black87,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NowPlayingScreen()),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(song.artist, style: const TextStyle(fontSize: 12, color: Colors.white70)),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(music.isPlaying ? Icons.pause : Icons.play_arrow),
                onPressed: () => music.pauseResume(),
              )
            ],
          ),
        ),
      ),
    );
  }
}
