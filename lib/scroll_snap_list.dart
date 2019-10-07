library scroll_snap_list;

import 'package:flutter/material.dart';

///A ListView widget that able to "snap" or focus to an item whenever user scrolls.
///
///Allows unrestricted scroll speed. Snap/focus event done on every `ScrollEndNotification`.
///
///Contains `ScrollNotification` widget, so might be incompatible with other scroll notification.
class ScrollSnapList extends StatefulWidget {
  ///List background
  final Color background;

  ///Widget builder.
  final Widget Function(BuildContext, int) buildListItem;

  ///Animation curve
  final Curve curve;

  ///Animation duration in milliseconds (ms)
  final int duration;

  ///Focus to an item when user tap on it. Inactive if the list-item have its own onTap detector (use state-key to help focusing instead).
  final bool focusOnItemTap;

  ///Method to manually trigger focus to an item. Call with help of `GlobalKey<ScrollSnapListState>`.
  final void Function(int) focusToItem;

  ///Container's margin
  final EdgeInsetsGeometry margin;

  ///Number of item in this list
  final int itemCount;

  ///Composed of the size of each item + its margin/padding.
  ///Size used is width if `scrollDirection` is `Axis.horizontal`, height if `Axis.vertical`.
  ///
  ///Example:
  ///- Horizontal list
  ///- Card with `width` 100
  ///- Margin is `EdgeInsets.symmetric(horizontal: 5)`
  ///- itemSize is `100+5+5 = 110`
  final double itemSize;

  ///Global key that's used to call `focusToItem` method to manually trigger focus event.
  final Key key;

  ///Callback function when list snaps/focuses to an item
  final void Function(int) onItemFocus;

  ///Callback function when user reach end of list.
  ///
  ///Can be used to load more data from database.
  final Function onReachEnd;

  ///Container's padding
  final EdgeInsetsGeometry padding;

  ///Reverse scrollDirection
  final bool reverse;

  final Axis scrollDirection;

  ScrollSnapList({
    this.background,
    @required this.buildListItem,
    this.curve = Curves.ease,
    this.duration = 500,
    this.focusOnItemTap = true,
    this.focusToItem,
    this.itemCount = 0,
    @required this.itemSize,
    this.key,
    this.margin,
    @required this.onItemFocus,
    this.onReachEnd,
    this.padding,
    this.reverse = false,
    this.scrollDirection = Axis.horizontal,
  }) : super(key: key);

  @override
  ScrollSnapListState createState() => ScrollSnapListState();
}

class ScrollSnapListState extends State<ScrollSnapList> {
  ScrollController _listController = ScrollController();

  ///Scroll list to an offset
  void _animateScroll(double location) {
    Future.delayed(Duration.zero, () {
      _listController.animateTo(
        location,
        duration: new Duration(milliseconds: widget.duration),
        curve: widget.curve,
      );
    });
  }

  Widget _buildListItem(BuildContext context, int index) {
    if (widget.focusOnItemTap)
      return GestureDetector(
        onTap: () => focusToItem(index),
        child: widget.buildListItem(context, index),
      );

    return widget.buildListItem(context, index);
  }

  ///Calculates target pixel for scroll animation
  double _calcCardLocation({double pixel, @required double itemSize, int index}) {
    //current pixel: pixel
    //listPadding is not considered as moving pixel by scroll (0.0 is after padding)
    //substracted by itemSize/2 (to center the item)
    //divided by pixels taken by each item
    int cardIndex = index != null ? index : ((pixel - itemSize / 2) / itemSize).ceil();

    if (widget.onItemFocus!=null)
      widget.onItemFocus(cardIndex);

    //target position
    return (cardIndex * itemSize);
  }

  /// Trigger focus to an item inside the list
  /// Will trigger scoll animation to focused item
  void focusToItem(int index) {
    double targetLoc = _calcCardLocation(index: index, itemSize: widget.itemSize);
    _animateScroll(targetLoc);
  }

  ///Trigger callback on reach end-of-list
  void _onReachEnd() {
    if (widget.onReachEnd != null) widget.onReachEnd();
  }

  @override
  void dispose() {
    _listController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: widget.padding,
      margin: widget.margin,
      child: LayoutBuilder(
        builder: (BuildContext ctx, BoxConstraints constraint) {
          double _listPadding = (widget.scrollDirection==Axis.horizontal?constraint.maxWidth:constraint.maxHeight) / 2 - widget.itemSize / 2;
          return NotificationListener<ScrollNotification>(
            onNotification: (ScrollNotification scrollInfo) {
              if (scrollInfo is ScrollEndNotification) {
                if (scrollInfo.metrics.pixels >=
                    scrollInfo.metrics.maxScrollExtent - widget.itemSize / 2) {
                  _onReachEnd();
                }

                //snap the selecton
                _animateScroll(_calcCardLocation(
                  pixel: scrollInfo.metrics.pixels,
                  itemSize: widget.itemSize,
                ));
              }
              return true;
            },
            child: ListView.builder(
              controller: _listController,
              padding: widget.scrollDirection==Axis.horizontal?EdgeInsets.symmetric(
                horizontal: _listPadding
              ):EdgeInsets.symmetric(
                vertical: _listPadding,
              ),
              reverse: widget.reverse,
              scrollDirection: widget.scrollDirection,
              itemBuilder: _buildListItem,
              itemCount: widget.itemCount,
            ),
          );
        },
      ),
    );
  }
}