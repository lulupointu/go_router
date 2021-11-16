import 'package:flutter/widgets.dart';

import '../../custom_transition_page.dart';
import '../../go_router_state.dart';
import '../go_route.dart';
import '../go_route_interface.dart';
import 'lazy_indexed_stack.dart';

/// TODO: Add description
class GoTabbedRoute extends GoRouteInterface {
  /// TODO: create a mechanism by which this path can't be matched if its children aren't
  GoTabbedRoute({
    required String path,
    required List<GoRoute> routes,
    required this.pageBuilder,
    this.controller,
    this.alignment = AlignmentDirectional.topStart,
    this.textDirection,
    this.fit = StackFit.loose,
  }) : super(path: path, routes: routes);

  /// A controller of the associated [LazyIndexedStack]
  final GoTabbedRouteController? controller;

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
  Widget _buildNavigator(
  BuildContext context,
    GoRouterState state,
    List<Page> pages,
  ) {
    // We need the index here because it needs to be set before the build phase
    // since GoTabbedRoute are often wrapped into Scaffold with bottom
    // navigation bar (which need the index)
    //
    // Using [state.delegate.matches] might not be the best way though
    // TODO: check if there is a best way they using [state.delegate], passing the args manually for example?
    final currentIndex = routes.indexWhere(
      (e) =>
          // ignore: invalid_use_of_visible_for_testing_member, sorry but I need this
          state.delegate.matches
              .map((e) => e.route)
              .any((element) => element.hashCode == e.hashCode),
    );

    controller?.currentIndex = currentIndex;
    return LazyIndexedStack(
      itemCount: routes.length,
      currentIndex: currentIndex,
      alignment: alignment,
      fit: fit,
      tabController: controller,
      pages: pages,
      onPopped: () => state.delegate.onPop(),
    );
  }
}
