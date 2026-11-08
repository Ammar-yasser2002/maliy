import 'package:flutter/material.dart';
import 'dart:typed_data';
import '../models/theme_preset.dart';
import '../screens/profile_screen.dart';

class Header extends StatefulWidget {
  final ThemePreset preset;
  final String title;
  final String subtitle;
  final VoidCallback? onMenu;
  final ValueChanged<String>? onSearch;
  final Uint8List? avatarBytes;
  final VoidCallback? onProfileChanged;

  const Header({
    super.key,
    required this.preset,
    this.title = 'مرحبا',
    this.subtitle = '',
    this.onMenu,
    this.onSearch,
    this.avatarBytes,
    this.onProfileChanged,
  });

  @override
  State<Header> createState() => _HeaderState();
}

class _HeaderState extends State<Header> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _clear() {
    _controller.clear();
    if (widget.onSearch != null) widget.onSearch!('');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final preset = widget.preset;
    return Container(
      height: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [preset.primary, preset.primary.withOpacity(0.7)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      padding: EdgeInsets.only(top: 20, left: 16, right: 16, bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.subtitle.isEmpty ? 'مرحباً،' : widget.subtitle, style: TextStyle(color: Colors.white70, fontSize: 16)),
                  SizedBox(height: 6),
                  Text(widget.title, style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                ],
              ),
              GestureDetector(
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => Directionality(
                        textDirection: TextDirection.rtl,
                        child: ProfileScreen(
                          name: widget.title,
                          phone: '',
                          imageUrl: '',
                        ),
                      ),
                    ),
                  );
                  if (widget.onProfileChanged != null) widget.onProfileChanged!();
                },
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white,
                  backgroundImage: widget.avatarBytes != null ? MemoryImage(widget.avatarBytes!) : null,
                  child: widget.avatarBytes == null ? Icon(Icons.person, color: preset.primary, size: 32) : null,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          // overlapping card like search/info
          Container(
            margin: EdgeInsets.only(top: 8),
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)]),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration.collapsed(hintText: 'ابحث...', filled: false),
                    onChanged: (v) {
                      setState(() {});
                      if (widget.onSearch != null) widget.onSearch!(v);
                    },
                  ),
                ),
                if (_controller.text.isNotEmpty)
                  IconButton(icon: Icon(Icons.close, color: Colors.grey), onPressed: _clear),
                Icon(Icons.search, color: preset.primary),
              ],
            ),
          )
        ],
      ),
    );
  }
}
