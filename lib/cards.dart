import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tinder_last/layout_core.dart';
import 'package:tinder_last/layout_overlays.dart';
import 'package:tinder_last/matches.dart';
import 'package:tinder_last/photos.dart';
import 'package:tinder_last/profiles.dart';

class CardStack extends StatefulWidget {
  final MatchEngine matchEngine;

  CardStack({
    this.matchEngine,
  });

  @override
  _CardStackState createState() => _CardStackState();
}

class _CardStackState extends State<CardStack> {
  DateMatch _currentMatch;
  // Key _frontCard;
  double _nextCardScale = 0.9;

  @override
  void initState() {
    super.initState();
    widget.matchEngine.addListener(_onMatchEngineChange);

    _currentMatch = widget.matchEngine.currentMatch;
    _currentMatch.addListener(_onMatchChange);

    // _frontCard = new Key(_currentMatch.profile.name);
  }

  @override
  void dispose() {
    if (_currentMatch != null) {
      _currentMatch.removeListener(_onMatchChange);
    }

    widget.matchEngine.removeListener(_onMatchEngineChange);
    super.dispose();
  }

  void _onMatchEngineChange() {
    if (_currentMatch != null) {
      _currentMatch.removeListener(_onMatchChange);
    }
    _currentMatch = widget.matchEngine.currentMatch;
    if (_currentMatch != null) {
      _currentMatch.addListener(_onMatchChange);
    }

    // final matchEngine = Provider.of<MatchEngine>(context);

    // _frontCard = new Key(_currentMatch.profile.name);
    // _frontCard = new Key(matchEngine.currentMatch.profile.name);

    // setState(() {});
  }

  void _onMatchChange() {
    setState(() {/* current match may have changed state, re-render */});
  }

  SlideDirection _desiredSlideOutDirection() {
    switch (widget.matchEngine.currentMatch.decision) {
      case Decision.nope:
        return SlideDirection.left;
      case Decision.like:
        return SlideDirection.right;
      case Decision.superLike:
        return SlideDirection.up;
      default:
        return null;
    }
  }

  void _onSlideUpdate(double distance) {
    setState(() {
      _nextCardScale = 0.9 + (0.1 * (distance / 100.0)).clamp(0.0, 0.1);
    });
  }

  void _onSlideOutComplete(SlideDirection direction) {
    DateMatch currentMatch = widget.matchEngine.currentMatch;

    switch (direction) {
      case SlideDirection.left:
        currentMatch.nope();
        break;
      case SlideDirection.right:
        currentMatch.like();
        break;
      case SlideDirection.up:
        currentMatch.superLike();
        break;
    }
    widget.matchEngine.cycleMatch();
  }

  Widget _buildBackCard() {
    return Transform(
      transform: Matrix4.identity()..scale(_nextCardScale, _nextCardScale),
      child: ProfileCard(
        profile: widget.matchEngine.nextMatch.profile,
      ),
    );
  }

  Widget _buildFrontCard(Key key) {
    return ProfileCard(
      key: key,
      profile: widget.matchEngine.currentMatch.profile,
    );
  }

  @override
  Widget build(BuildContext context) {
    final matchEngine = Provider.of<MatchEngine>(context);
    final key = Key(matchEngine.currentMatch.profile.name);

    return Stack(
      children: <Widget>[
        DraggableCard(
          card: _buildBackCard(),
          isDraggable: false,
        ),
        DraggableCard(
          card: _buildFrontCard(key),
          slideTo: _desiredSlideOutDirection(),
          onSlideUpdate: _onSlideUpdate,
          onSlideOutComplete: _onSlideOutComplete,
        ),
      ],
    );
  }
}

enum SlideDirection {
  left,
  right,
  up,
}

class DraggableCard extends StatefulWidget {
  final Widget card;
  final bool isDraggable;
  final Function(SlideDirection direction) onSlideOutComplete;
  final Function(double distance) onSlideUpdate;
  final SlideDirection slideTo;

  DraggableCard({
    this.card,
    this.slideTo,
    this.isDraggable = true,
    this.onSlideOutComplete,
    this.onSlideUpdate,
  });

  @override
  _DraggableCardState createState() => _DraggableCardState();
}

class _DraggableCardState extends State<DraggableCard>
    with TickerProviderStateMixin {
  Offset cardOffset = const Offset(0.0, 0.0);
  Offset dragStart;
  Offset dragPosition;
  Offset slideBackStart;
  AnimationController slideBackAnimation;
  Tween<Offset> slideOutTween;
  AnimationController slideOutAnimation;
  SlideDirection slideOutDirection;
  GlobalKey profileCardKey = GlobalKey(debugLabel: 'profile_card_key');

  @override
  void initState() {
    super.initState();
    slideBackAnimation = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )
      ..addListener(() {
        setState(() {
          cardOffset = Offset.lerp(
            slideBackStart,
            const Offset(0.0, 0.0),
            Curves.elasticOut.transform(slideBackAnimation.value),
          );
        });
      })
      ..addStatusListener((AnimationStatus status) {
        if (status == AnimationStatus.completed) {
          setState(() {
            dragStart = null;
            dragPosition = null;
            slideBackStart = null;
          });
        }
      });

    slideOutAnimation = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    )
      ..addListener(() {
        setState(() {
          cardOffset = slideOutTween.evaluate(slideOutAnimation);

          if (null != widget.onSlideUpdate) {
            widget.onSlideUpdate(cardOffset.distance);
          }
        });
      })
      ..addStatusListener((AnimationStatus status) {
        if (status == AnimationStatus.completed) {
          setState(() {
            dragStart = null;
            dragPosition = null;
            slideOutTween = null;
            // cardOffset = Offset(0.0, 0.0);
          });

          if (widget.onSlideOutComplete != null) {
            widget.onSlideOutComplete(slideOutDirection);
          }
        }
      });
  }

  @override
  void dispose() {
    slideBackAnimation.dispose();
    slideOutAnimation.dispose();
    super.dispose();
  }

  // build() 이후에 실행됨 => 이미지 깜빡이는거 해결
  @override
  void didUpdateWidget(DraggableCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.card.key != oldWidget.card.key) {
      cardOffset = const Offset(0.0, 0.0);
    }

    if (oldWidget.slideTo == null && widget.slideTo != null) {
      switch (widget.slideTo) {
        case SlideDirection.left:
          _slideLeft();
          break;
        case SlideDirection.right:
          _slideRight();
          break;
        case SlideDirection.up:
          _slideUp();
          break;
      }
    }
  }

  Offset _chooseRandomDragStart() {
    final cardContext = profileCardKey.currentContext;
    final cardTopLeft = (cardContext.findRenderObject() as RenderBox)
        .localToGlobal(const Offset(0.0, 0.0));
    final dragStartY =
        cardContext.size.height * (Random().nextDouble() < 0.5 ? 0.25 : 0.75) +
            cardTopLeft.dy;
    return Offset(cardContext.size.width / 2, dragStartY);
  }

  void _slideLeft() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final screenWidth = context.size.width;
      dragStart = _chooseRandomDragStart();
      slideOutTween = new Tween(
          begin: const Offset(0.0, 0.0),
          end: new Offset(-2 * screenWidth, 0.0));
      slideOutAnimation.forward(from: 0.0);
    });
  }

  void _slideRight() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final screenWidth = context.size.width;
      dragStart = _chooseRandomDragStart();
      slideOutTween = new Tween(
          begin: const Offset(0.0, 0.0), end: new Offset(2 * screenWidth, 0.0));
      slideOutAnimation.forward(from: 0.0);
    });
  }

  void _slideUp() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final screenHeight = context.size.height;
      dragStart = _chooseRandomDragStart();
      slideOutTween = new Tween(
          begin: const Offset(0.0, 0.0),
          end: new Offset(0.0, -2 * screenHeight));
      slideOutAnimation.forward(from: 0.0);
    });
  }

  void _onPanStart(DragStartDetails details) {
    if (!widget.isDraggable) {
      return;
    }
    dragStart = details.globalPosition;

    if (slideBackAnimation.isAnimating) {
      slideBackAnimation.stop(canceled: true);
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!widget.isDraggable) {
      return;
    }
    setState(() {
      dragPosition = details.globalPosition;
      cardOffset = dragPosition - dragStart;

      if (null != widget.onSlideUpdate) {
        widget.onSlideUpdate(cardOffset.distance);
      }
    });
  }

  void _onPanEnd(DragEndDetails details) {
    final dragVecor = cardOffset / cardOffset.distance;
    final isInLeftRegion = (cardOffset.dx / context.size.width) < -0.35;
    final isInRightRegion = (cardOffset.dx / context.size.width) > 0.35;
    final isInTopRegion = (cardOffset.dy / context.size.height) < -0.35;

    setState(() {
      if (isInLeftRegion || isInRightRegion) {
        slideOutTween =
            Tween(begin: cardOffset, end: dragVecor * (2 * context.size.width));
        slideOutAnimation.forward(from: 0.0);
        slideOutDirection =
            isInLeftRegion ? SlideDirection.left : SlideDirection.right;
      } else if (isInTopRegion) {
        slideOutTween = Tween(
            begin: cardOffset, end: dragVecor * (2 * context.size.height));
        slideOutAnimation.forward(from: 0.0);
        slideOutDirection = SlideDirection.up;
      } else {
        slideBackStart = cardOffset;
        slideBackAnimation.forward(from: 0.0);
      }
    });
  }

  double _rotation(Rect dragBounds) {
    if (dragStart != null) {
      final rotationCornerMultiplier =
          dragStart.dy >= dragBounds.top + (dragBounds.height / 2) ? -1 : 1;
      return (pi / 8) *
          (cardOffset.dx / dragBounds.width) *
          rotationCornerMultiplier;
    } else {
      return 0.0;
    }
  }

  Offset _rotationOrigin(Rect dragBounds) {
    if (dragStart != null) {
      return dragStart - dragBounds.topLeft;
    } else {
      return const Offset(0.0, 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnchoredOverlay(
      showOverlay: true,
      child: Container(),
      overlayBuilder: (BuildContext context, Rect anchorBounds, Offset anchor) {
        return CenterAbout(
          position: anchor,
          child: Transform(
            transform:
                Matrix4.translationValues(cardOffset.dx, cardOffset.dy, 0.0)
                  ..rotateZ(_rotation(anchorBounds)),
            origin: _rotationOrigin(anchorBounds),
            child: Container(
              key: profileCardKey,
              width: anchorBounds.width,
              height: anchorBounds.height,
              padding: EdgeInsets.all(16.0),
              child: GestureDetector(
                onPanStart: _onPanStart,
                onPanUpdate: _onPanUpdate,
                onPanEnd: _onPanEnd,
                child: widget.card,
              ),
            ),
          ),
        );
      },
    );
  }
}

class ProfileCard extends StatelessWidget {
  final Profile profile;

  ProfileCard({Key key, this.profile}) : super(key: key);

  Widget _buildBackground() {
    return PhotoBrowser(
      photoAssetPaths: profile.photos,
      visiblePhotoIndex: 0,
    );
  }

  Widget _buildProfilesSynopsis() {
    return Positioned(
      left: 0.0,
      right: 0.0,
      bottom: 0.0,
      child: Container(
        decoration: BoxDecoration(
            gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withOpacity(0.8),
          ],
        )),
        padding: const EdgeInsets.all(24.0),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    profile.name,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24.0,
                    ),
                  ),
                  Text(
                    profile.bio,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18.0,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.info, color: Colors.white),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: new BoxDecoration(
        borderRadius: new BorderRadius.circular(10.0),
        boxShadow: [
          new BoxShadow(
            color: new Color(0x1100000),
            blurRadius: 5.0,
            spreadRadius: 2.0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10.0),
        child: Material(
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              _buildBackground(),
              _buildProfilesSynopsis(),
            ],
          ),
        ),
      ),
    );
  }
}
