import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// An [IndexedStack] which builds its children lazily (i.e. only
/// when they need to be displayed)
class LazyIndexedStack extends StatefulWidget {
  /// An [IndexedStack] which builds its children lazily (i.e. only
  /// when they need to be displayed)
  const LazyIndexedStack({
    required this.currentIndex,
    required this.itemBuilder,
    required this.itemCount,
    this.alignment = AlignmentDirectional.topStart,
    this.textDirection,
    this.fit = StackFit.loose,
    Key? key,
  }) : super(key: key);

  /// Build the widget that is at the index [currentIndex]
  final Widget Function(BuildContext context, int index) itemBuilder;

  /// The index of the current child to show.
  final int currentIndex;

  /// The number of items in the stack
  final int itemCount;

  /// How to align the children in the stack
  ///
  /// Defaults to [AlignmentDirectional.topStart]
  final AlignmentGeometry alignment;

  /// The text direction with which to resolve [alignment].
  ///
  /// Defaults to the ambient [Directionality].
  final TextDirection? textDirection;

  /// How to size the children
  ///
  /// Defaults to [StackFit.loose]
  final StackFit fit;

  @override
  // ignore: library_private_types_in_public_api
  _LazyIndexedStackState createState() => _LazyIndexedStackState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IntProperty('itemCount', itemCount))
      ..add(EnumProperty<TextDirection?>('textDirection', textDirection))
      ..add(IntProperty('index', currentIndex))
      ..add(
        ObjectFlagProperty<Widget Function(BuildContext context, int index)>.has(
            'itemBuilder', itemBuilder),
      )
      ..add(DiagnosticsProperty<AlignmentGeometry>('alignment', alignment))
      ..add(EnumProperty<StackFit>('fit', fit));
  }
}

class _LazyIndexedStackState extends State<LazyIndexedStack> {
  /// The list of children
  ///
  ///
  /// If the children is not yet loaded, a [SizedBox] is used as
  /// a placeholder
  late final List<Widget> _children = List.filled(
    widget.itemCount,
    const SizedBox.shrink(),
  );

  /// Whether the widgets are loaded
  ///
  /// This is a one to one mapping to [_children]
  late final List<bool> _loaded = List.filled(widget.itemCount, false);

  @override
  void didChangeDependencies() {
    _updateChildren();
    super.didChangeDependencies();
  }

  @override
  void didUpdateWidget(covariant LazyIndexedStack oldWidget) {
    _updateChildren();
    super.didUpdateWidget(oldWidget);
  }

  void _updateChildren() {
    // Load the widget at the current index if it is not already
    // loaded or [reuse] is false
    final _index = widget.currentIndex;
    _children[_index] = widget.itemBuilder(context, _index);
    _loaded[_index] = true;
  }

  @override
  Widget build(BuildContext context) => IndexedStack(
        index: widget.currentIndex,
        alignment: widget.alignment,
        textDirection: widget.textDirection,
        sizing: widget.fit,
        children: _children,
      );
}
