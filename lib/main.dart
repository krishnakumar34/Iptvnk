import 'package:flutter/material.dart';
import 'package:better_player/better_player.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const IPTVApp());
}

class IPTVApp extends StatelessWidget {
  const IPTVApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "IPTV Player",
      theme: ThemeData.dark(),
      home: const IPTVHome(),
    );
  }
}

class IPTVHome extends StatefulWidget {
  const IPTVHome({super.key});

  @override
  State<IPTVHome> createState() => _IPTVHomeState();
}

class Channel {
  final String name;
  final String url;
  Channel(this.name, this.url);
}

class _IPTVHomeState extends State<IPTVHome> {
  List<Channel> channels = [];
  List<Channel> filtered = [];
  String? selectedUrl;
  final TextEditingController searchCtrl = TextEditingController();
  Set<String> favorites = {};

  @override
  void initState() {
    super.initState();
    loadM3U();
    loadFavs();
  }

  Future<void> loadFavs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      favorites = prefs.getStringList('favorites')?.toSet() ?? {};
    });
  }

  Future<void> toggleFav(String url) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (favorites.contains(url)) favorites.remove(url);
      else favorites.add(url);
      prefs.setStringList('favorites', favorites.toList());
    });
  }

  Future<void> loadM3U() async {
    // Sample public M3U. Replace with your own URL or file picker.
    final url = "https://raw.githubusercontent.com/iptv-org/iptv/master/streams/eng.m3u";
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final lines = response.body.split('\n');
        final urls = <Channel>[];
        String name = '';
        for (var line in lines) {
          line = line.trim();
          if (line.startsWith('#EXTINF')) {
            // try to extract channel name
            final parts = line.split(',');
            name = parts.length > 1 ? parts.sublist(1).join(',').trim() : 'Channel';
          } else if (line.isNotEmpty && (line.startsWith('http') || line.contains('.m3u8'))) {
            urls.add(Channel(name.isEmpty ? 'Channel ${urls.length+1}' : name, line));
            name = '';
          }
        }
        setState(() {
          channels = urls;
          filtered = List.from(channels);
          selectedUrl = channels.isNotEmpty ? channels.first.url : null;
        });
      } else {
        debugPrint('Failed to load M3U: HTTP ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error loading M3U: $e');
    }
  }

  void onSearch(String q) {
    setState(() {
      filtered = channels.where((c) => c.name.toLowerCase().contains(q.toLowerCase())).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("IPTV Player - Flutter"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: loadM3U,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: searchCtrl,
              onChanged: onSearch,
              decoration: const InputDecoration(
                hintText: 'Search channels',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                // Channel list
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final ch = filtered[index];
                            final isFav = favorites.contains(ch.url);
                            return ListTile(
                              title: Text(ch.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                              subtitle: Text(ch.url, maxLines: 1, overflow: TextOverflow.ellipsis),
                              trailing: IconButton(
                                icon: Icon(isFav ? Icons.favorite : Icons.favorite_border),
                                onPressed: () => toggleFav(ch.url),
                              ),
                              selected: selectedUrl == ch.url,
                              onTap: () => setState(() => selectedUrl = ch.url),
                            );
                          },
                        ),
                      ),
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.all(6.0),
                        child: Row(
                          children: [
                            ElevatedButton.icon(
                              icon: const Icon(Icons.star),
                              label: const Text('Favorites'),
                              onPressed: () {
                                setState(() {
                                  filtered = channels.where((c) => favorites.contains(c.url)).toList();
                                });
                              },
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.list),
                              label: const Text('All'),
                              onPressed: () { setState(() { filtered = List.from(channels); }); },
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.add),
                              label: const Text('Add URL'),
                              onPressed: () => showAddUrlDialog(),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),

                // Player area
                Expanded(
                  flex: 2,
                  child: selectedUrl == null
                      ? const Center(child: Text('Select a channel'))
                      : Column(
                          children: [
                            AspectRatio(
                              aspectRatio: 16 / 9,
                              child: BetterPlayer.network(
                                selectedUrl!,
                                betterPlayerConfiguration: const BetterPlayerConfiguration(
                                  autoPlay: true,
                                  aspectRatio: 16 / 9,
                                  controlsConfiguration: BetterPlayerControlsConfiguration(
                                    enableFullscreen: true,
                                    enablePlayPause: true,
                                    enableSkips: false,
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(selectedUrl!, style: const TextStyle(fontSize: 12)),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void showAddUrlDialog() {
    final urlCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add channel URL'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(hintText: 'Channel name')),
            TextField(controller: urlCtrl, decoration: const InputDecoration(hintText: 'Stream URL')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final name = nameCtrl.text.isEmpty ? 'Custom' : nameCtrl.text.trim();
              final url = urlCtrl.text.trim();
              if (url.isNotEmpty) {
                setState(() {
                  channels.add(Channel(name, url));
                  filtered = List.from(channels);
                  selectedUrl = url;
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
