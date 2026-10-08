import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Purpose of this class is to calculate the offset of each tile in the board.
/// This will help us to animate the line when a player wins.
class BoardOffsets {
  BoardOffsets({required this.boardSize});

  final int boardSize; // grid dimension N, for an N x N board

  final List<Offset> offsets =
      []; // tile-center offsets, row-major, filled by _calculateOffsets

  /// This method will collect the offsets from the grid view as Sliver multi
  /// box adaptor element. This will save the data in [offsets] list.
  void _calculateOffsets(BuildContext context, RenderBox? referenceBox) {
    final element = context as SliverMultiBoxAdaptorElement;
    final renderObject = element.renderObject;
    if (renderObject is RenderSliverGrid) {
      element.visitChildren((childElement) {
        final renderBox = childElement.renderObject as RenderBox?;
        if (renderBox != null) {
          final childCenter = renderBox.size.center(Offset.zero);
          // Tile centre in global coordinates, then converted into
          // [referenceBox]'s local space — that box is the winning-line
          // overlay, so its local space *is* the paint canvas. This makes the
          // line land exactly on the tiles without guessing any SafeArea /
          // status-bar / notch inset.
          final global = renderBox.localToGlobal(childCenter);
          offsets.add(referenceBox?.globalToLocal(global) ?? global);
        }
      });
    }
  }

  ///This will be only fill the offsets if it is empty
  ///If the offsets is not empty it will clear the offsets and then fill it if they are more than the board size
  ///[referenceBox] is the render box of the winning-line overlay; tile centres
  ///are expressed in its local space so the painted line aligns with the tiles.
  void fillOffsetIfEmpty(BuildContext context, RenderBox? referenceBox) {
    if (offsets.length < boardSize * boardSize) {
      _calculateOffsets(context, referenceBox);
    } else if (offsets.length > boardSize * boardSize) {
      offsets.clear();
      _calculateOffsets(context, referenceBox);
    }
  }

  /// The X is winner so we will need the first position of that column and the last one, so these below methods are helper which will help us retrieve that position
  /// [ - , X , 0 ]
  /// [ 0 , X , - ]
  /// [ - , X , 0 ]

  ///This will return last element for that particular column like we have to draw line to start from end so we will provide it the start index of column and it will return us the last of column
  Offset getColumnEndOffset(int column) {
    return offsets[(boardSize - 1) * boardSize + column];
  }

  ///This will return last element for that particular row like we have to draw line to start from end so we will provide it the start index of row and it will return us the last of row
  Offset getRowEndOffset(int row) {
    return offsets[row * boardSize + (boardSize - 1)];
  }

  ///This will return first element for that particular column like we have to draw line to start from start so we will provide it the start index of column and it will return us the first of column
  Offset getRowStartOffset(int row) {
    return offsets[row * boardSize];
  }

  /// First (top) cell of [column] — the start point for a column win line.
  Offset getColumnStartOffset(int column) {
    return offsets[column];
  }

  /// Main diagonal (top-left → bottom-right).
  Offset getMainDiagonalStart() => offsets.first;
  Offset getMainDiagonalEnd() => offsets.last;

  /// Anti diagonal (top-right → bottom-left).
  Offset getAntiDiagonalStart() => offsets[boardSize - 1];
  Offset getAntiDiagonalEnd() => offsets[(boardSize - 1) * boardSize];
}
