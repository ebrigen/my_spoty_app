import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/playlists_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/youtube_search_pagestate.dart';
import 'widgets/now_playing_bar.dart';

class MusicApp extends StatelessWidget {
  const MusicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Spotify Music App',
      theme: ThemeData.dark(useMaterial3: true),
      home: const MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final _screens = const [
    HomeScreen(),
    PlaylistsScreen(),
    FavoritesScreen(),
    YoutubeSearchPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.playlist_play_outlined),
              selectedIcon: Icon(Icons.playlist_play),
              label: 'Playlists'),
          NavigationDestination(
              icon: Icon(Icons.favorite_border),
              selectedIcon: Icon(Icons.favorite),
              label: 'Favorites'),
          NavigationDestination(
              icon: Icon(Icons.search),
              selectedIcon: Icon(Icons.favorite),
              label: 'Search'),
        ],
      ),
      bottomSheet: const NowPlayingBar(),
    );
  }
}
