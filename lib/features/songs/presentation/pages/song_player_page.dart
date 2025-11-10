import 'package:flutter/material.dart';
import 'package:wereb/theme/theme.dart';

class SongPlayerPage extends StatefulWidget {
  const SongPlayerPage({super.key});

  @override
  State<SongPlayerPage> createState() => _SongPlayerPageState();
}

class _SongPlayerPageState extends State<SongPlayerPage> {
  double progress = 0.2;
  double playbackSpeed = 1.0; // add this as a state variable

  final List<Map<String, String>> songs = [
    {
      "title": "Believer",
      "artist": "Imagine Dragons",
      "cover":
          "https://res.cloudinary.com/dl6vahv6t/image/upload/v1750658598/profile_1625820611_e8ph6d.jpg",
    },
    {
      "title": "Thunder",
      "artist": "Imagine Dragons",
      "cover":
          "https://res.cloudinary.com/dl6vahv6t/image/upload/v1750658598/profile_1625820611_e8ph6d.jpg",
    },
    {
      "title": "Radioactive",
      "artist": "Imagine Dragons",
      "cover":
          "https://res.cloudinary.com/dl6vahv6t/image/upload/v1750658598/profile_1625820611_e8ph6d.jpg",
    },
    {
      "title": "Whatever It Takes",
      "artist": "Imagine Dragons",
      "cover":
          "https://res.cloudinary.com/dl6vahv6t/image/upload/v1750658598/profile_1625820611_e8ph6d.jpg",
    },
  ];

  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final currentSong = songs[currentIndex];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,

      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12,
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios_new,
                      color: theme.iconTheme.color,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                  Expanded(
                    child: Center(
                      child: Text("Playing Now", style: textTheme.titleLarge),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),

            // Album Art Scrollable
            imageWidget(theme, currentSong["title"]!),
            const SizedBox(height: 20),
            // Song Info
            Text(currentSong["title"]!, style: textTheme.displayMedium),
            const SizedBox(height: 5),

            // Slider
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Slider(
                          value: progress,
                          onChanged: (value) =>
                              setState(() => progress = value),
                          activeColor: theme.primaryColor,
                          inactiveColor: theme.primaryColor.withOpacity(0.4),
                        ),
                      ),
                      const SizedBox(
                        width: 8,
                      ), // small gap between slider and dropdown
                      DropdownButton<double>(
                        value: playbackSpeed,
                        dropdownColor: theme.scaffoldBackgroundColor,
                        iconEnabledColor: theme.iconTheme.color,
                        items: const [
                          DropdownMenuItem(value: 0.5, child: Text("0.5x")),
                          DropdownMenuItem(value: 1.0, child: Text("1x")),
                          DropdownMenuItem(value: 1.5, child: Text("1.5x")),
                          DropdownMenuItem(value: 2.0, child: Text("2x")),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              playbackSpeed = value;
                              // TODO: update your audio player speed here
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("0:50", style: textTheme.titleMedium),
                      Text("4:00", style: textTheme.titleMedium),
                    ],
                  ),
                ],
              ),
            ),

            // Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () {
                    setState(() {
                      currentIndex =
                          (currentIndex - 1 + songs.length) % songs.length;
                    });
                  },
                  icon: Icon(
                    Icons.skip_previous,
                    size: 40,
                    color: theme.iconTheme.color,
                  ),
                ),
                const SizedBox(width: 20),
                IconButton(
                  onPressed: () {},
                  icon: Icon(
                    Icons.play_arrow,
                    size: 50,
                    color: theme.iconTheme.color,
                  ),
                ),
                const SizedBox(width: 20),
                IconButton(
                  onPressed: () {
                    setState(() {
                      currentIndex = (currentIndex + 1) % songs.length;
                    });
                  },
                  icon: Icon(
                    Icons.skip_next,
                    size: 40,
                    color: theme.iconTheme.color,
                  ),
                ),
                const SizedBox(width: 20),
              ],
            ),

            // Scrollable Song List at Bottom
            Expanded(
              child: Container(
                padding: const EdgeInsets.only(left: 16, right: 16, top: 8),
                decoration: BoxDecoration(
                  color: theme.cardColor.withOpacity(0.2),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(30),
                  ),
                ),
                child: ListView.builder(
                  itemCount: songs.length,
                  itemBuilder: (context, index) {
                    final song = songs[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          "assets/kidus_yared.png",
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        ),
                      ),
                      title: Text(song["title"]!, style: textTheme.bodyLarge),
                      subtitle: Text("3:45", style: textTheme.titleMedium),
                      onTap: () => setState(() => currentIndex = index),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  SizedBox imageWidget(ThemeData theme, String title) {
    double height = MediaQuery.of(context).size.height;

    return SizedBox(
      height: height * 0.35,
      width: double.infinity,
      child: PageView.builder(
        controller: PageController(viewportFraction: 1.0),
        // optional: lock scroll if zoomed (you can manage this dynamically)
        physics: const BouncingScrollPhysics(),
        itemCount: songs.length,
        onPageChanged: (index) => setState(() => currentIndex = index),
        itemBuilder: (context, index) {
          bool isActive = index == currentIndex;
          return Stack(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: isActive ? 0 : 20,
                ),
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: InteractiveViewer(
                    panEnabled: true,
                    scaleEnabled: true,
                    minScale: 1,
                    maxScale: 4,
                    clipBehavior: Clip.none,
                    boundaryMargin: const EdgeInsets.all(double.infinity),
                    child: Image.asset(
                      "assets/kidus_yared.png",
                      fit: BoxFit.contain,
                      width: double.infinity,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 10,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.primaryColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: theme.shadowColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: IconButton(
                    tooltip: 'Upload',
                    icon: Icon(
                      Icons.cloud_upload_outlined,
                      color: theme.scaffoldBackgroundColor,
                    ),
                    onPressed: () => print(title),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
