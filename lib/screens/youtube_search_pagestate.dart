import 'package:flutter/material.dart';
import '../models/song.dart';
import '../services/music_service.dart';
import '../models/youtube_search_result.dart';

class YoutubeSearchPage extends StatefulWidget {
  const YoutubeSearchPage({super.key});

  @override
  State<YoutubeSearchPage> createState() => _YoutubeSearchPageState();
}

class _YoutubeSearchPageState extends State<YoutubeSearchPage> {
  final TextEditingController _controller = TextEditingController();
  final MusicService _musicService = MusicService();

  bool _isSearching = false;
  List<YoutubeSearchResult> _results = [];
  String? _error;

  Future<void> _doSearch() async {
    final query = _controller.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
      _error = null;
      _results = [];
    });

    try {
      final res = await _musicService.searchOnYoutube(query);
      setState(() {
        _results = res;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  Future<void> _downloadResult(YoutubeSearchResult r) async {
    // crea un Song “dinamico” usando il videoId
    final song = Song(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: r.title,
      artist: r.channel ?? 'Unknown',
      youtubeUrl: 'https://www.youtube.com/watch?v=${r.videoId}',
    );

    // opzionale: aggiungi alla lista canzoni/queue
    _musicService.allSongs.add(song);
    _musicService.addToQueue(song);

    await _musicService.downloadSong(song);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Download completato: ${song.title}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cerca su YouTube'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      labelText: 'Titolo canzone / artista',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _doSearch(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _isSearching ? null : _doSearch,
                ),
              ],
            ),
          ),
          if (_isSearching) const LinearProgressIndicator(),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: _results.length,
              itemBuilder: (context, index) {
                final r = _results[index];
                final duration = r.durationSeconds != null
                    ? Duration(seconds: r.durationSeconds!)
                    : null;
                final durationText = duration != null
                    ? '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}'
                    : '';

                return ListTile(
                  leading: r.thumbnail != null
                      ? Image.network(r.thumbnail!,
                          width: 56, height: 56, fit: BoxFit.cover)
                      : const Icon(Icons.music_note),
                  title: Text(r.title),
                  subtitle: Text(
                    [
                      if (r.channel != null) r.channel,
                      if (durationText.isNotEmpty) durationText,
                    ].whereType<String>().join(' • '),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.download),
                    onPressed: () => _downloadResult(r),
                  ),
                  onTap: () => _downloadResult(r), // tap = scarica
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
