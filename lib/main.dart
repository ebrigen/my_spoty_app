import 'package:flutter/material.dart';
import 'spotify_music_app.dart';
import 'package:provider/provider.dart';
import 'services/music_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final musicService = MusicService();
  await musicService.restoreDownloadedSongs();
  await musicService.loadState();
  musicService.attachAudioListeners();

  runApp(
    ChangeNotifierProvider.value(
      value: musicService,
      child: MusicApp(),
    ),
  );
}
