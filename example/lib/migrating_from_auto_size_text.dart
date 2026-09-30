// The "after" side of doc/migrating-from-auto_size_text.md.
//
// The code below started as a screen written against auto_size_text. Two lines
// changed: the import, and `textScaleFactor: 1.2` became
// `textScaler: const TextScaler.linear(1.2)`.
import 'package:flutter/material.dart';
import 'package:text_autosize/text_autosize.dart';

void main() {
  runApp(
    const MaterialApp(
      home: Scaffold(body: Center(child: MenuTile())),
    ),
  );
}

/// A tile with two labels that share one font size.
class MenuTile extends StatefulWidget {
  /// Creates the tile.
  const MenuTile({super.key});

  @override
  State<MenuTile> createState() => _MenuTileState();
}

class _MenuTileState extends State<MenuTile> {
  // The group lives on the State so it survives rebuilds.
  final _group = AutoSizeGroup();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 40,
            child: AutoSizeText(
              'Kitchen & Dining',
              style: const TextStyle(fontSize: 30),
              maxLines: 1,
              minFontSize: 12,
              group: _group,
              textScaler: const TextScaler.linear(1.2),
            ),
          ),
          SizedBox(
            height: 40,
            child: AutoSizeText(
              'Home',
              style: const TextStyle(fontSize: 30),
              maxLines: 1,
              minFontSize: 12,
              group: _group,
              textScaler: const TextScaler.linear(1.2),
            ),
          ),
        ],
      ),
    );
  }
}
