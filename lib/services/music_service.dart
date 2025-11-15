import 'dart:io';
import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import 'package:ffmpeg_kit_min_gpl/ffmpeg_kit.dart';
import 'package:path_provider/path_provider.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt;

import '../models/playlist.dart';
import '../models/song.dart';
import '../models/youtube_search_result.dart';
import 'dart:convert';

import 'package:http/http.dart' as http;

const String backendBaseUrl = 'http://localhost:8000';

// ⬆️ in produzione metti l’URL del tuo server
class MusicService extends ChangeNotifier {
  static final MusicService _instance = MusicService._internal();
  factory MusicService() => _instance;
  MusicService._internal() {
    _log('MusicService initialized, seeding demo songs');
    allSongs.addAll([
      Song(
          id: '1',
          title: 'Lush Life',
          artist: 'Zara Larsson',
          youtubeUrl: 'https://www.youtube.com/watch?v=tD4HCZe-tew'),
      Song(
          id: '2',
          title: 'Faded',
          artist: 'Alan Walker',
          youtubeUrl: 'https://www.youtube.com/watch?v=60ItHLz5WEA'),
      Song(
          id: '3',
          title: 'Believer',
          artist: 'Imagine Dragons',
          youtubeUrl: 'https://www.youtube.com/watch?v=7wtfhZwyrcc'),
    ]);
  }

  // Simple log helper
  void _log(String msg) {
    if (kDebugMode) {
      // ignore: avoid_print
      print('[MusicService] $msg');
    }
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
    _log('Attaching audio listeners');
    _audioPlayer.onPositionChanged.listen((p) {
      position = p;
      // Avoid spamming logs: log only occasionally
      if (p.inSeconds % 5 == 0) {
        _log('Position changed: ${p.inSeconds}s');
      }
      notifyListeners();
    });
    _audioPlayer.onDurationChanged.listen((d) {
      duration = d;
      _log('Duration set: ${d.inSeconds}s');
      notifyListeners();
    });
    _audioPlayer.onPlayerComplete.listen((_) {
      _log('Playback complete');
      if (isRepeat && currentSong != null) {
        _log('Repeat is ON, replaying current song: ${currentSong!.title}');
        playSong(currentSong!);
      } else {
        _log('Going to next()');
        next();
      }
    });
  }

  Future<List<YoutubeSearchResult>> searchOnYoutube(String query) async {
    final uri = Uri.parse(
        '$backendBaseUrl/search?q=${Uri.encodeQueryComponent(query)}');
    _log('Calling backend search: $uri');

    final resp = await http.get(uri);
    if (resp.statusCode != 200) {
      _log('Search error: statusCode=${resp.statusCode}, body=${resp.body}');
      throw Exception('Search failed: ${resp.statusCode}');
    }

    final List<dynamic> data = jsonDecode(resp.body) as List<dynamic>;
    final results = data
        .map((e) => YoutubeSearchResult.fromJson(e as Map<String, dynamic>))
        .toList();

    _log('Search returned ${results.length} results');
    return results;
  }

  Future<void> playSong(Song song) async {
    _log(
        'playSong called for "${song.title}" (id=${song.id}), localPath=${song.localPath}');
    if (song.localPath == null) {
      _log('Cannot play song, localPath is null');
      return;
    }
    try {
      await _audioPlayer.play(DeviceFileSource(song.localPath!));
      currentSong = song;
      isPlaying = true;
      _log('Playback started for "${song.title}"');
      notifyListeners();
    } catch (e) {
      _log('Error in playSong: $e');
    }
  }

  Future<void> pauseResume() async {
    _log('pauseResume called, isPlaying=$isPlaying');
    if (isPlaying) {
      await _audioPlayer.pause();
      isPlaying = false;
      _log('Playback paused');
    } else {
      await _audioPlayer.resume();
      isPlaying = true;
      _log('Playback resumed');
    }
    notifyListeners();
  }

  Future<void> seek(Duration d) async {
    _log('Seeking to ${d.inSeconds}s');
    await _audioPlayer.seek(d);
  }

  void toggleShuffle() {
    isShuffle = !isShuffle;
    _log('Shuffle toggled: $isShuffle');
    notifyListeners();
  }

  void toggleRepeat() {
    isRepeat = !isRepeat;
    _log('Repeat toggled: $isRepeat');
    notifyListeners();
  }

  void next() {
    _log('next() called');
    if (queue.isEmpty || currentSong == null) {
      _log('Cannot go next: queue empty or currentSong is null');
      return;
    }
    final idx = queue.indexOf(currentSong!);
    final nextIdx = (idx + 1) % queue.length;
    _log('Next index: $nextIdx (from $idx)');
    playSong(queue[nextIdx]);
  }

  void previous() {
    _log('previous() called');
    if (queue.isEmpty || currentSong == null) {
      _log('Cannot go previous: queue empty or currentSong is null');
      return;
    }
    final idx = queue.indexOf(currentSong!);
    final prevIdx = (idx - 1 + queue.length) % queue.length;
    _log('Previous index: $prevIdx (from $idx)');
    playSong(queue[prevIdx]);
  }

  void toggleFavorite(Song song) {
    song.isFavorite = !song.isFavorite;
    _log('Favorite toggled for "${song.title}": ${song.isFavorite}');
    notifyListeners();
  }

  List<Song> get favorites => allSongs.where((s) => s.isFavorite).toList();

  void addToQueue(Song song) {
    if (!queue.contains(song)) {
      queue.add(song);
      _log('Added "${song.title}" to queue. Queue length: ${queue.length}');
    } else {
      _log('"${song.title}" already in queue');
    }
    notifyListeners();
  }

  void addToPlaylist(String name, Song song) {
    _log('addToPlaylist called: playlist="$name", song="${song.title}"');
    final found = playlists.where((p) => p.name == name).toList();
    if (found.isEmpty) {
      _log('Playlist not found, creating new');
      playlists.add(Playlist(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        songIds: [song.id],
      ));
    } else {
      final p = found.first;
      if (!p.songIds.contains(song.id)) {
        p.songIds.add(song.id);
        _log('Added song to existing playlist "$name"');
      } else {
        _log('Song already in playlist "$name"');
      }
    }
    notifyListeners();
  }

  Playlist createPlaylist(String name) {
    _log('createPlaylist called: "$name"');
    final pl = Playlist(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      songIds: [],
    );
    playlists.add(pl);
    notifyListeners();
    return pl;
  }

  List<Song> songsInPlaylist(Playlist p) =>
      allSongs.where((s) => p.songIds.contains(s.id)).toList();

  Future<void> downloadSong(Song song) async {
    _log('downloadSong called for "${song.title}" (id=${song.id})');
    song.isDownloading = true;
    song.downloadProgress = 0.0;
    notifyListeners();

    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final outPath = '${docsDir.path}/${song.id}.mp3';

      if (File(outPath).existsSync()) {
        _log('File already exists, skipping download. Marking song as ready.');
        song.localPath = outPath;
        song.isDownloading = false;
        song.downloadProgress = 1.0;
        notifyListeners();
        return;
      }

      // 👉 invece di _downloadFromYoutube:
      final videoId = Uri.parse(song.youtubeUrl).queryParameters['v'] ?? '';
      if (videoId.isEmpty) {
        throw Exception('Invalid YouTube URL: missing video id');
      }

      final downloadedPath = await _downloadFromBackend(videoId, song);

      song.localPath = downloadedPath;
      song.downloadProgress = 1.0;
      song.isDownloading = false;
      _log('Download completed successfully for "${song.title}"');
      notifyListeners();
    } catch (e) {
      song.isDownloading = false;
      song.downloadProgress = 0.0;
      notifyListeners();
      _log('Download error (backend): $e');
    }
  }

  Future<void> downloadSongYouTube(Song song) async {
    _log('downloadSong called for "${song.title}" (id=${song.id})');
    song.isDownloading = true;
    song.downloadProgress = 0.0;
    notifyListeners();

    try {
      final docsDir = await getApplicationDocumentsDirectory();
      _log('ApplicationDocumentsDirectory: ${docsDir.path}');
      final outPath = '${docsDir.path}/${song.id}.mp3';
      _log('Target mp3 path: $outPath');

      if (File(outPath).existsSync()) {
        _log('File already exists, skipping download. Marking song as ready.');
        song.localPath = outPath;
        song.isDownloading = false;
        song.downloadProgress = 1.0;
        notifyListeners();
        return;
      }

      final uri = Uri.parse(song.youtubeUrl);
      _log('Parsed URI: $uri');

      late final String downloadedPath;

      if (uri.host.contains('youtube.com') || uri.host.contains('youtu.be')) {
        _log('Detected YouTube URL, calling _downloadFromYoutube');
        downloadedPath = await _downloadFromYoutube(song);
      } else {
        _log('Detected direct URL, calling _downloadDirect');
        downloadedPath = await _downloadDirect(uri, song);
      }

      _log(
          'Download finished, path: $downloadedPath, exists=${File(downloadedPath).existsSync()}');

      if (!File(downloadedPath).existsSync()) {
        throw Exception(
            'Failed to download source media (file does not exist).');
      }

      final cmd =
          '-y -i "$downloadedPath" -vn -acodec libmp3lame -b:a 192k "$outPath"';
      _log('Starting FFmpeg conversion with command: $cmd');
      final session = await FFmpegKit.execute(cmd);
      final rc = await session.getReturnCode();
      _log('FFmpeg return code: ${rc?.getValue()}');
      if (rc == null || !rc.isValueSuccess()) {
        throw Exception('FFmpeg conversion failed (code: ${rc?.getValue()}).');
      }

      try {
        _log('Deleting temporary file: $downloadedPath');
        File(downloadedPath).deleteSync();
      } catch (e) {
        _log('Failed to delete temporary file: $e');
      }

      song.localPath = outPath;
      song.downloadProgress = 1.0;
      song.isDownloading = false;
      _log('Download + conversion completed successfully for "${song.title}"');
      notifyListeners();
    } catch (e) {
      song.isDownloading = false;
      song.downloadProgress = 0.0;
      notifyListeners();
      _log('Download/convert error: $e');
    }
  }

  Future<String> _downloadFromBackend(String videoId, Song song) async {
    final uri = Uri.parse('$backendBaseUrl/download/$videoId');
    _log('_downloadFromBackend: GET $uri');

    final docsDir = await getApplicationDocumentsDirectory();
    final outPath = '${docsDir.path}/${song.id}.mp3';

    final request = await HttpClient().getUrl(uri);
    final response = await request.close();

    if (response.statusCode != 200) {
      throw Exception('Backend returned status ${response.statusCode}');
    }

    final file = File(outPath);
    final sink = file.openWrite();

    final total = response.contentLength;
    var received = 0;

    await for (final chunk in response) {
      sink.add(chunk);
      received += chunk.length;
      if (total > 0) {
        song.downloadProgress = received / total;
        notifyListeners();
      }
    }

    await sink.close();

    _log('_downloadFromBackend completed, saved to $outPath');
    return outPath;
  }

  Future<String> _downloadFromYoutube(Song song) async {
    _log(
        '_downloadFromYoutube started for "${song.title}" (${song.youtubeUrl})');
    final youtube = yt.YoutubeExplode();
    try {
      final videoId = yt.VideoId(song.youtubeUrl);
      _log('Parsed VideoId: $videoId');

      final manifest = await youtube.videos.streamsClient.getManifest(videoId);
      _log(
          'Got manifest. AudioOnly streams count: ${manifest.audioOnly.length}');

      final audioOnly = manifest.audioOnly;
      if (audioOnly.isEmpty) {
        throw Exception('No audio stream available for this URL.');
      }

      // ✅ Prova prima a prendere un m4a (mp4a) se esiste, altrimenti il primo disponibile
      yt.AudioOnlyStreamInfo bestAudio;
      final m4aCandidates = audioOnly.where(
        (s) => s.audioCodec.toLowerCase().contains('mp4a'),
      );
      if (m4aCandidates.isNotEmpty) {
        bestAudio = m4aCandidates.reduce(
          (a, b) => a.bitrate.bitsPerSecond >= b.bitrate.bitsPerSecond ? a : b,
        );
      } else {
        // fallback: il migliore in generale
        bestAudio = audioOnly.withHighestBitrate();
      }

      final bitrateKbps = (bestAudio.bitrate.bitsPerSecond / 1000).round();
      _log(
        'Chosen audio stream: '
        'itag=${bestAudio.tag}, '
        'bitrate=${bitrateKbps}kbps, '
        'container=${bestAudio.container.name}, '
        'size=${bestAudio.size.totalMegaBytes.toStringAsFixed(2)}MB',
      );
      _log('Stream URL: ${bestAudio.url}');

      final tmpDir = await getTemporaryDirectory();
      _log('Temporary directory: ${tmpDir.path}');
      final ext = bestAudio.container.name;
      final tmpAudioPath = '${tmpDir.path}/${song.id}_audio.$ext';
      _log('Temporary audio file path: $tmpAudioPath');

      final rawStream = youtube.videos.streamsClient.get(bestAudio);

      // ⏱ Timeout di 20 secondi se non arrivano dati
      final timedStream = rawStream.timeout(
        const Duration(seconds: 20),
        onTimeout: (sink) {
          _log(
              'Timeout while downloading audio stream (no data received for 20s)');
          sink.close();
        },
      );

      final file = File(tmpAudioPath);
      final sink = file.openWrite();
      final total = bestAudio.size.totalBytes;
      var received = 0;

      _log('Starting to download audio stream...');
      var lastLoggedPercent = -1;

      try {
        await for (final data in timedStream) {
          received += data.length;
          sink.add(data);

          if (total > 0) {
            final progress = received / total;
            song.downloadProgress = progress * 0.85;
            notifyListeners();

            final percent = (progress * 100).floor();
            if (percent ~/ 10 != lastLoggedPercent ~/ 10) {
              lastLoggedPercent = percent;
              _log(
                'YouTube audio download progress: $percent% '
                '(received=$received / total=$total bytes)',
              );
            }
          } else {
            if (received ~/ (1024 * 1024) != lastLoggedPercent) {
              lastLoggedPercent = received ~/ (1024 * 1024);
              _log(
                'YouTube audio download received ~${lastLoggedPercent}MB '
                '(total unknown)',
              );
            }
          }
        }
        await sink.close();

        if (received == 0) {
          throw Exception(
              'No data received from audio stream (received=0 bytes)');
        }

        _log('YouTube audio download completed. Saved to $tmpAudioPath');
        return tmpAudioPath;
      } on TimeoutException catch (e) {
        _log('TimeoutException while reading audio stream: $e');
        try {
          await sink.close();
        } catch (_) {}
        rethrow;
      } catch (e, st) {
        _log('ERROR while reading audio stream: $e');
        _log('Stacktrace:\n$st');
        try {
          await sink.close();
        } catch (_) {}
        rethrow;
      }
    } finally {
      youtube.close();
      _log('_downloadFromYoutube finished for "${song.title}"');
    }
  }

  Future<String> _downloadDirect(Uri uri, Song song) async {
    _log('_downloadDirect started for "${song.title}" from $uri');
    final tmpDir = await getTemporaryDirectory();
    _log('Temporary directory: ${tmpDir.path}');
    final tmpVideoPath = '${tmpDir.path}/${song.id}_source';
    _log('Temporary source file path: $tmpVideoPath');

    final client = HttpClient();
    try {
      final request = await client.getUrl(uri);
      _log('HTTP GET sent');
      final response = await request.close();
      _log(
          'HTTP response status: ${response.statusCode}, contentLength: ${response.contentLength}');

      final file = File(tmpVideoPath);
      final sink = file.openWrite();
      final total = response.contentLength;
      var received = 0;
      var lastLoggedPercent = -1;

      await for (final data in response) {
        sink.add(data);
        received += data.length;
        if (total > 0) {
          final progress = received / total;
          song.downloadProgress = progress * 0.85;
          notifyListeners();

          // Log every 10%
          final percent = (progress * 100).floor();
          if (percent ~/ 10 != lastLoggedPercent ~/ 10) {
            lastLoggedPercent = percent;
            _log('Direct download progress: $percent%');
          }
        }
      }
      await sink.close();
      _log('Direct download completed. Saved to $tmpVideoPath');
      return tmpVideoPath;
    } finally {
      client.close();
      _log('_downloadDirect finished for "${song.title}"');
    }
  }
}
