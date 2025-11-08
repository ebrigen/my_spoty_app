import 'package:flutter/material.dart';
import '../services/music_service.dart';

class NowPlayingScreen extends StatefulWidget {
  const NowPlayingScreen({super.key});

  @override
  State<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends State<NowPlayingScreen> {
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
    final song = music.currentSong;
    final pos = music.position;
    final dur = music.duration;

    return Scaffold(
      appBar: AppBar(title: const Text('Now Playing')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 24),
            Container(
              height: 240,
              width: 240,
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.music_note, size: 96),
            ),
            const SizedBox(height: 24),
            if (song != null) ...[
              Text(song.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(song.artist, style: const TextStyle(color: Colors.white70)),
            ] else ...[
              const Text('No song playing'),
            ],
            const SizedBox(height: 16),
            Slider(
              value: dur.inMilliseconds == 0 ? 0 : pos.inMilliseconds.clamp(0, dur.inMilliseconds).toDouble(),
              max: (dur.inMilliseconds == 0 ? 1 : dur.inMilliseconds).toDouble(),
              onChanged: (v) => music.seek(Duration(milliseconds: v.toInt())),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_fmt(pos)),
                Text(_fmt(dur)),
              ],
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(music.isShuffle ? Icons.shuffle_on : Icons.shuffle),
                  onPressed: music.toggleShuffle,
                ),
                IconButton(
                  icon: const Icon(Icons.skip_previous, size: 32),
                  onPressed: music.previous,
                ),
                ElevatedButton.icon(
                  icon: Icon(music.isPlaying ? Icons.pause : Icons.play_arrow),
                  label: Text(music.isPlaying ? 'Pause' : 'Play'),
                  onPressed: () => music.pauseResume(),
                ),
                IconButton(
                  icon: const Icon(Icons.skip_next, size: 32),
                  onPressed: music.next,
                ),
                IconButton(
                  icon: Icon(music.isRepeat ? Icons.repeat_on : Icons.repeat),
                  onPressed: music.toggleRepeat,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
