import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class YoutubeSearchPage extends StatefulWidget {
  const YoutubeSearchPage({super.key});

  @override
  State<YoutubeSearchPage> createState() => _YoutubeSearchPageState();
}

class _YoutubeSearchPageState extends State<YoutubeSearchPage> {
  final TextEditingController _controller = TextEditingController();
  bool _loading = false;
  List<dynamic> _results = [];

  String backendBaseUrl = "http://192.168.1.66:8000"; // IP del tuo server

  Future<void> _search() async {
    final query = _controller.text.trim();
    if (query.isEmpty) return;

    setState(() => _loading = true);

    try {
      final url = Uri.parse("$backendBaseUrl/search?q=$query");
      final res = await http.get(url);

      if (res.statusCode == 200) {
        setState(() {
          _results = json.decode(res.body);
        });
      } else {
        print("SERVER ERROR: ${res.body}");
      }
    } catch (e) {
      print("SEARCH ERROR: $e");
    }

    setState(() => _loading = false);
  }

  Future<void> _download(String videoId) async {
    final url = Uri.parse("$backendBaseUrl/download/$videoId");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Starting download $videoId...")),
    );

    // lascia il download al MusicService nella tua app
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Search YouTube")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _controller,
              onSubmitted: (_) => _search(),
              decoration: InputDecoration(
                hintText: "Search for song or artist...",
                prefixIcon: const Icon(Icons.search),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          if (_loading) const LinearProgressIndicator(),
          Expanded(
            child: ListView.builder(
              itemCount: _results.length,
              itemBuilder: (context, i) {
                final item = _results[i];
                return ListTile(
                  leading: item["thumbnail"] != null
                      ? Image.network(item["thumbnail"], width: 60)
                      : const Icon(Icons.music_note, size: 40),
                  title: Text(item["title"] ?? "No title"),
                  subtitle: Text(item["channel"] ?? "Unknown channel"),
                  trailing: IconButton(
                    icon: const Icon(Icons.download),
                    onPressed: () => _download(item["video_id"]),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
