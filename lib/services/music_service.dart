import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/song.dart';
import '../models/playlist.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../utils/constants.dart';

class MusicService extends ChangeNotifier {
  static final MusicService _instance = MusicService._internal();
  factory MusicService() => _instance;
  MusicService._internal() {
    allSongs.addAll([
      Song(id: '1', title: 'Lush Life', artist: 'Zara Larsson', youtubeUrl: 'https://www.youtube.com/watch?v=tD4HCZe-tew'),
      Song(id: '2', title: 'Faded', artist: 'Alan Walker', youtubeUrl: 'https://www.youtube.com/watch?v=60ItHLz5WEA'),
      Song(id: '3', title: 'Believer', artist: 'Imagine Dragons', youtubeUrl: 'https://www.youtube.com/watch?v=7wtfhZwyrcc'),
    ]);
  }

  final AudioPlayer _audioPlayer = AudioPlayer();
  final List<Song> allSongs = [];
  final List<Song> queue = [];
  final List<Playlist> playlists = [];
  Song? currentSong;
  bool isPlaying = false;
  bool isShuffle = false;
  bool isRepeat = false;
  Duration position = Duration.zero;
  Duration duration = Duration.zero;

  void attachAudioListeners() {
    _audioPlayer.onPositionChanged.listen((p) {
      position = p;
      notifyListeners();
    });
    _audioPlayer.onDurationChanged.listen((d) {
      duration = d;
      notifyListeners();
    });
    _audioPlayer.onPlayerComplete.listen((_) {
      if (isRepeat && currentSong != null) {
        playSong(currentSong!);
      } else {
        next();
      }
    });
  }

  Future<void> playSong(Song song) async {
    if (song.localPath == null) return;
    await _audioPlayer.play(DeviceFileSource(song.localPath!));
    currentSong = song;
    isPlaying = true;
    notifyListeners();
  }

  Future<void> pauseResume() async {
    if (isPlaying) {
      await _audioPlayer.pause();
      isPlaying = false;
    } else {
      await _audioPlayer.resume();
      isPlaying = true;
    }
    notifyListeners();
  }

  Future<void> seek(Duration d) async {
    await _audioPlayer.seek(d);
  }

  void toggleShuffle() {
    isShuffle = !isShuffle;
    notifyListeners();
  }

  void toggleRepeat() {
    isRepeat = !isRepeat;
    notifyListeners();
  }

  void next() {
    if (queue.isEmpty || currentSong == null) return;
    final idx = queue.indexOf(currentSong!);
    final nextIdx = (idx + 1) % queue.length;
    playSong(queue[nextIdx]);
  }

  void previous() {
    if (queue.isEmpty || currentSong == null) return;
    final idx = queue.indexOf(currentSong!);
    final prevIdx = (idx - 1 + queue.length) % queue.length;
    playSong(queue[prevIdx]);
  }

  void toggleFavorite(Song song) {
    song.isFavorite = !song.isFavorite;
    notifyListeners();
  }

  List<Song> get favorites => allSongs.where((s) => s.isFavorite).toList();

  void addToQueue(Song song) {
    if (!queue.contains(song)) queue.add(song);
    notifyListeners();
  }

  void addToPlaylist(String name, Song song) {
    final found = playlists.where((p) => p.name == name).toList();
    if (found.isEmpty) {
      playlists.add(Playlist(id: DateTime.now().millisecondsSinceEpoch.toString(), name: name, songIds: [song.id]));
    } else {
      final p = found.first;
      if (!p.songIds.contains(song.id)) p.songIds.add(song.id);
    }
    notifyListeners();
  }

  Playlist createPlaylist(String name) {
    final pl = Playlist(id: DateTime.now().millisecondsSinceEpoch.toString(), name: name, songIds: []);
    playlists.add(pl);
    notifyListeners();
    return pl;
  }

  List<Song> songsInPlaylist(Playlist p) =>
      allSongs.where((s) => p.songIds.contains(s.id)).toList();

  Future<void> downloadSong(Song song, {String apiUrl = serverApiUrl}) async {
    song.isDownloading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'youtube_url': song.youtubeUrl, 'song_id': song.id}),
      );

      if (response.statusCode == 200) {
        final mp3Url = jsonDecode(response.body)['mp3_url'];
        final mp3Data = await http.get(Uri.parse(mp3Url));
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/${song.id}.mp3');
        await file.writeAsBytes(mp3Data.bodyBytes);
        song.localPath = file.path;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Download failed: $e');
      }
    } finally {
      song.isDownloading = false;
      notifyListeners();
    }
  }
}
