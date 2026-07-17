import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class FullscreenImageViewer extends StatefulWidget {
  const FullscreenImageViewer({super.key, required this.imageUrls, this.initialIndex = 0});

  final List<String> imageUrls;
  final int initialIndex;

  @override
  State<FullscreenImageViewer> createState() => _FullscreenImageViewerState();
}

class _FullscreenImageViewerState extends State<FullscreenImageViewer> {
  late final PageController _controller;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _controller = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text('${_index + 1} / ${widget.imageUrls.length}', style: const TextStyle(color: Colors.white)),
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: widget.imageUrls.length,
        onPageChanged: (i) => setState(() => _index = i),
        itemBuilder: (context, i) => InteractiveViewer(
          minScale: 1,
          maxScale: 4,
          child: Center(
            child: CachedNetworkImage(imageUrl: widget.imageUrls[i], fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}