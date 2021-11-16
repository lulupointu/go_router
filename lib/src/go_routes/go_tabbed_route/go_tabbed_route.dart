import 'package:flutter/widgets.dart';
import 'package:go_router/src/go_routes/go_tabbed_route/lazy_indexed_stack.dart';

import '../../custom_transition_page.dart';
import '../../go_router_state.dart';
import '../go_route.dart';
import '../go_route_interface.dart';

///
class GoTabbedRoute extends GoRouteInterface {
  /// TODO: create a mechanism by which this path can't be matched if its children aren't
  GoTabbedRoute({
    required String path,
    required List<GoRoute> routes,
    required this.currentIndex,
    required this.pageBuilder,
    this.alignment = AlignmentDirectional.topStart,
    this.textDirection,
    this.fit = StackFit.loose,
  }) : super(path: path, routes: routes);

  /// The index of the current child to show.
  ///
  ///
  /// TODO: remove the builder and deduce the index from the active route
  /// somehow
  final int Function(BuildContext context, GoRouterState state) currentIndex;

  /// A page builder for this route.
  ///
  /// Typically a MaterialPage, as in:
  /// ```
  /// GoTabbedRoute(
  ///   path: '/',
  ///   currentIndex: 0,
  ///   routes: [...],
  ///   pageBuilder: (context, state, child) => MaterialPage<void>(
  ///   key: state.pageKey,
  ///   child: child,
  /// ),
  /// ```
  ///
  /// You can also use CupertinoPage, and for a custom page builder to use
  /// custom page transitions, you can use [CustomTransitionPage].
  final Page<dynamic> Function(
    BuildContext context,
    GoRouterState state,
    Widget child,
  ) pageBuilder;

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
  List<Page> pageStackBuilder(
    BuildContext context,
    GoRouterState state,
    List<Page> subRoutePageStack,
  ) =>
      [
        pageBuilder(
          context,
          state,
          _buildNavigator(context, state, subRoutePageStack),
        ),
      ];

  /// Builds the navigator corresponding to a stack given a set of pages
  ///
  ///
  /// TODO: add other navigator properties?
  /// TODO: Pass the onPopPage up
  /// TODO: Pass the android back button down
  Widget _buildNavigator(
    BuildContext context,
    GoRouterState state,
    List<Page> pages,
  ) => LazyIndexedStack(
        currentIndex: currentIndex(context, state),
        itemCount: routes.length,
        alignment: alignment,
        fit: fit,
        itemBuilder: (context, index) => Navigator(
          pages: pages,
          onPopPage: (route, dynamic result) => route.didPop(result),
        ),
      );
}
