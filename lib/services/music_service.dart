import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import 'package:ffmpeg_kit_min_gpl/ffmpeg_kit.dart';
import 'package:path_provider/path_provider.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt;

import '../models/playlist.dart';
import '../models/song.dart';

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

  Future<void> downloadSong(Song song) async {
    song.isDownloading = true;
    song.downloadProgress = 0.0;
    notifyListeners();

    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final outPath = '${docsDir.path}/${song.id}.mp3';

      if (File(outPath).existsSync()) {
        song.localPath = outPath;
        song.isDownloading = false;
        song.downloadProgress = 1.0;
        notifyListeners();
        return;
      }

      final uri = Uri.parse(song.youtubeUrl);
      late final String downloadedPath;

      if (uri.host.contains('youtube.com') || uri.host.contains('youtu.be')) {
        downloadedPath = await _downloadFromYoutube(song);
      } else {
        downloadedPath = await _downloadDirect(uri, song);
      }

      if (!File(downloadedPath).existsSync()) {
        throw Exception('Failed to download source media.');
      }

      final cmd = '-y -i "$downloadedPath" -vn -acodec libmp3lame -b:a 192k "$outPath"';
      final session = await FFmpegKit.execute(cmd);
      final rc = await session.getReturnCode();
      if (rc == null || !rc.isValueSuccess()) {
        throw Exception('FFmpeg conversion failed (code: ${rc?.getValue()}).');
      }

      try {
        File(downloadedPath).deleteSync();
      } catch (_) {
        // best-effort cleanup
      }

      song.localPath = outPath;
      song.downloadProgress = 1.0;
      song.isDownloading = false;
      notifyListeners();
    } catch (e) {
      song.isDownloading = false;
      song.downloadProgress = 0.0;
      notifyListeners();
      if (kDebugMode) {
        // ignore: avoid_print
        print('Download/convert error: $e');
      }
    }
  }

  Future<String> _downloadFromYoutube(Song song) async {
    final youtube = yt.YoutubeExplode();
    try {
      final videoId = yt.VideoId(song.youtubeUrl);
      final manifest = await youtube.videos.streamsClient.getManifest(videoId);
      final audioOnly = manifest.audioOnly;
      if (audioOnly.isEmpty) {
        throw Exception('No audio stream available for this URL.');
      }
      final bestAudio = audioOnly.withHighestBitrate();

      final tmpDir = await getTemporaryDirectory();
      final ext = bestAudio.container.name;
      final tmpAudioPath = '${tmpDir.path}/${song.id}_audio.$ext';

      final audioStream = youtube.videos.streamsClient.get(bestAudio);
      final file = File(tmpAudioPath);
      final sink = file.openWrite();
      final total = bestAudio.size.totalBytes;
      var received = 0;

      await for (final data in audioStream) {
        sink.add(data);
        received += data.length;
        if (total > 0) {
          song.downloadProgress = received / total * 0.85;
          notifyListeners();
        }
      }
      await sink.close();
      return tmpAudioPath;
    } finally {
      youtube.close();
    }
  }

  Future<String> _downloadDirect(Uri uri, Song song) async {
    final tmpDir = await getTemporaryDirectory();
    final tmpVideoPath = '${tmpDir.path}/${song.id}_source';
    final request = await HttpClient().getUrl(uri);
    final response = await request.close();

    final file = File(tmpVideoPath);
    final sink = file.openWrite();
    final total = response.contentLength;
    var received = 0;

    await for (final data in response) {
      sink.add(data);
      received += data.length;
      if (total > 0) {
        song.downloadProgress = received / total * 0.85;
        notifyListeners();
      }
    }
    await sink.close();
    return tmpVideoPath;
  }
}
