import 'package:flutter/material.dart';

class BottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const BottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.search),
          label: 'Search',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.camera),
          label: 'Live',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.videocam),
          label: 'Video',
        ),
      ],
      currentIndex: selectedIndex,
      selectedItemColor: Colors.blue[800],
      onTap: onItemTapped,
      type: BottomNavigationBarType.fixed,
    );
  }
}