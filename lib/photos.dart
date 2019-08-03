import 'package:flutter/material.dart';

class PhotoBrowser extends StatefulWidget {
  final List<String> photoAssetPaths;
  final int visiblePhotoIndex;

  PhotoBrowser({
    this.photoAssetPaths,
    this.visiblePhotoIndex,
  });

  @override
  _PhotoBrowserState createState() => _PhotoBrowserState();
}

class _PhotoBrowserState extends State<PhotoBrowser> {
  int visiblePhotoIndex;

  @override
  void initState() {
    super.initState();
    visiblePhotoIndex = widget.visiblePhotoIndex;
  }

  @override
  void didChangeDependencies() {
    widget.photoAssetPaths.asMap().forEach((i, value) {
      precacheImage(NetworkImage(widget.photoAssetPaths[i]), context);
    });
    super.didChangeDependencies();
  }

  void _prevImage() {
    setState(() {
      visiblePhotoIndex = visiblePhotoIndex > 0 ? visiblePhotoIndex - 1 : 0;
    });
  }

  void _nextImage() {
    setState(() {
      visiblePhotoIndex = visiblePhotoIndex < widget.photoAssetPaths.length - 1
          ? visiblePhotoIndex + 1
          : visiblePhotoIndex;
    });
  }

  Widget _buildPhotoControls() {
    return Row(
      children: <Widget>[
        Expanded(
          child: GestureDetector(
            onTap: _prevImage,
            child: Container(
              color: Colors.transparent,
            ),
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: _nextImage,
            child: Container(
              color: Colors.transparent,
            ),
          ),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        FadeInImage.assetNetwork(
          placeholder: 'assets/loading.gif',
          image: widget.photoAssetPaths[visiblePhotoIndex],
          fadeInDuration: const Duration(milliseconds: 100),
          fadeOutDuration: const Duration(milliseconds: 100),
          fit: BoxFit.cover,
        ),
        // Image.network(
        //   widget.photoAssetPaths[visiblePhotoIndex],
        //   fit: BoxFit.cover,
        // ),
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          child: SelectedPhotoIndicator(
            photoCount: widget.photoAssetPaths.length,
            visiblePhotoIndex: visiblePhotoIndex,
          ),
        ),
        _buildPhotoControls(),
      ],
    );
  }
}

class SelectedPhotoIndicator extends StatelessWidget {
  final int photoCount;
  final int visiblePhotoIndex;

  SelectedPhotoIndicator({
    this.photoCount,
    this.visiblePhotoIndex,
  });

  Widget _buildInaciveIndicator() {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.only(left: 2.0, right: 2.0),
        child: Container(
          height: 3.0,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.2),
            borderRadius: BorderRadius.circular(2.5),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveIndicator() {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.only(left: 2.0, right: 2.0),
        child: Container(
          height: 3.0,
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(2.5),
              boxShadow: [
                BoxShadow(
                  color: Color(0x22000000),
                  spreadRadius: 0.0,
                  blurRadius: 2.0,
                  offset: Offset(0.0, 1.0),
                ),
              ]),
        ),
      ),
    );
  }

  List<Widget> _buildIndicators() {
    List<Widget> indicators = [];
    for (int i = 0; i < photoCount; i++) {
      indicators.add(
        i == visiblePhotoIndex
            ? _buildActiveIndicator()
            : _buildInaciveIndicator(),
      );
    }
    return indicators;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(children: _buildIndicators()),
    );
  }
}
