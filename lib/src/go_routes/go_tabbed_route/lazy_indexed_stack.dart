import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import '../../../go_router.dart';
import '../../go_router.dart';

/// An [IndexedStack] which builds its children lazily (i.e. only
/// when they need to be displayed)
///
///
/// This implementation has been tailored to work with [GoTabbedRoute],
/// ideally the logic between the two should be extracted
class LazyIndexedStack extends StatefulWidget {
  /// An [IndexedStack] which builds its children lazily (i.e. only
  /// when they need to be displayed)
  const LazyIndexedStack({
    required this.pages,
    required this.currentIndex,
    required this.itemCount,
    required this.onPopped,
    this.alignment = AlignmentDirectional.topStart,
    this.textDirection,
    this.fit = StackFit.loose,
    this.tabController,
    Key? key,
  }) : super(key: key);

  /// A controller of the associated [LazyIndexedStack]
  final GoTabbedRouteController? tabController;

  /// The index of the child to show.
  final int currentIndex;

  /// The number of items in the stack
  final int itemCount;

  /// The pages of the current index
  final List<Page> pages;

  /// A callback used to notify the top navigator that a pop happened
  final VoidCallback onPopped;

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
      ..add(IntProperty('currentIndex', currentIndex))
      ..add(IntProperty('itemCount', itemCount))
      ..add(EnumProperty<TextDirection?>('textDirection', textDirection))
      ..add(
        ObjectFlagProperty<List<Page>>.has('itemBuilder', pages),
      )
      ..add(DiagnosticsProperty<AlignmentGeometry>('alignment', alignment))
      ..add(EnumProperty<StackFit>('fit', fit))
      ..add(DiagnosticsProperty<GoTabbedRouteController?>('tabController', tabController))
      ..add(ObjectFlagProperty<VoidCallback>.has('onPopped', onPopped));
  }
}

class _LazyIndexedStackState extends State<LazyIndexedStack> {
  /// The keys of the associated navigators
  late final _navigatorsKeys = List.generate(
    widget.itemCount,
    (_) => GlobalKey<NavigatorState>(),
  );

  /// The back button dispatchers associated with each routers
  ///
  ///
  /// They are used to handle the android back button on the visible
  /// navigator
  late final _backButtonDispatchers = List.generate(
    widget.itemCount,
    (_) => ChildBackButtonDispatcher(Router.of(context).backButtonDispatcher!),
  );

  /// The list of children
  ///
  ///
  /// If the children is not yet loaded, a [SizedBox] is used as
  /// a placeholder
  late final List<Widget> _children = List.filled(
    widget.itemCount,
    const SizedBox.shrink(),
  );

  /// The list of location associated with each tab
  ///
  ///
  /// If the tab is not yet loaded, a null value is used
  late final List<String?> _tabsLocations = List.filled(
    widget.itemCount,
    null,
  );

  /// Switches from the current tab to the tab at [index]
  ///
  ///
  /// If the tab at [index] has never been used: [initialLocationBuilder] will
  /// be used to determine the location to use
  ///
  /// If the tab at [index] has already been used: its url will be restored to
  /// the last visited one
  void go(
    int index,
    String Function(BuildContext context, int index) initialLocationBuilder,
  ) {
    context.go(_tabsLocations[index] ?? initialLocationBuilder(context, index));
  }

  /// Build the navigator at the current index with the current pages
  Router _navigatorRouterBuilder() {
    final currentIndex = widget.currentIndex;
    final _backButtonDispatcher = _backButtonDispatchers[widget.currentIndex]..takePriority();

    return Router<void>(
      backButtonDispatcher: _backButtonDispatcher,
      routerDelegate: _NavigatorRouter(
        isVisible: () => widget.currentIndex == currentIndex,
        navigatorKey: _navigatorsKeys[widget.currentIndex],
        pages: widget.pages,
        onPopped: widget.onPopped,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    widget.tabController?._state = this;
  }

  @override
  void dispose() {
    widget.tabController?._state = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _children[widget.currentIndex] = _navigatorRouterBuilder();
    _tabsLocations[widget.currentIndex] = GoRouter.of(context).location;

    return IndexedStack(
      index: widget.currentIndex,
      alignment: widget.alignment,
      textDirection: widget.textDirection,
      sizing: widget.fit,
      children: _children,
    );
  }
}

/// The router associated with a single navigator of [LazyIndexedStack]
class _NavigatorRouter<T> extends RouterDelegate<T>
    with
        ChangeNotifier, // ignore: prefer_mixin
        PopNavigatorRouterDelegateMixin<T> {
  _NavigatorRouter({
    required this.isVisible,
    required this.navigatorKey,
    required this.pages,
    required this.onPopped,
  });

  /// Whether the associated Navigator is the one being visible
  ///
  ///
  /// This is used to know whether this RouterDelegate should handle
  /// back button events
  final bool Function() isVisible;

  /// The key of the navigator
  @override
  final GlobalKey<NavigatorState> navigatorKey;

  /// The pages to use in the navigator
  final List<Page> pages;

  /// A callback used to notify the top navigator that a pop happened
  final VoidCallback onPopped;

  @override
  Widget build(BuildContext context) => Navigator(
        key: navigatorKey,
        pages: pages,
        onPopPage: (route, dynamic result) {
          if (!route.didPop(result)) return false;

          // Notify the navigator above, maybe we should wait 1 frame?
          onPopped();

          return true;
        },
      );

  @override
  Future<void> setNewRoutePath(T configuration) async {}

  @override
  Future<bool> popRoute() {
    if (!isVisible()) {
      return SynchronousFuture(false);
    }

    return super.popRoute();
  }
}

/// A controller of a [GoTabbedRoute]
class GoTabbedRouteController {
  /// A controller of a [GoTabbedRoute]
  ///
  ///
  /// This can be used to switch between tabs
  GoTabbedRouteController({
    required this.initialLocationBuilder,
  });

  /// The initial location to use if a tab has never been access and [go] is
  /// used
  ///
  ///
  /// The index given the the callback is the index used in [go]
  final String Function(BuildContext context, int index) initialLocationBuilder;

  /// The current active index
  ///
  ///
  /// This controller must be associated with the [GoTabbedRoute] before this
  /// can be accessed
  late int currentIndex;

  /// Switches from the current tab to the tab at [index]
  ///
  ///
  /// If the tab at [index] has never been used: [initialLocationBuilder] will
  /// be used to determine the location to use
  ///
  /// If the tab at [index] has already been used: its url will be restored to
  /// the last visited one
  void go(int index) {
    _state!.go(index, initialLocationBuilder);
  }

  /// Whether the current controller is active, if it's not it can't be used
  /// to navigate
  ///
  ///
  /// A controller is active when its associated [GoTabbedRoute] is in the
  /// current route stack
  bool get active => _state != null;

  /// The state of the associated [LazyIndexedStack]
  ///
  /// A controller can only be associated to one [LazyIndexedStack]
  late _LazyIndexedStackState? _state;
}
