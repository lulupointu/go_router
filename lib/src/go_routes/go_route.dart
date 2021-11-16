import 'package:flutter/widgets.dart';

import '../custom_transition_page.dart';
import '../go_router_state.dart';
import '../typedefs.dart';
import 'go_route_interface.dart';

/// A declarative mapping between a route path and a page builder.
class GoRoute extends GoRouteInterface {
  /// Default constructor used to create mapping between a
  /// route path and a page builder.
  GoRoute({
    required String path,
    String? name,
    this.pageBuilder = _builder,
    List<GoRouteInterface> routes = const [],
    GoRouterRedirect redirect = _redirect,
  }) : super(path: path, name: name, redirect: redirect, routes: routes);

  /// A page builder for this route.
  ///
  /// Typically a MaterialPage, as in:
  /// ```
  /// GoRoute(
  ///   path: '/',
  ///   pageBuilder: (context, state) => MaterialPage<void>(
  ///   key: state.pageKey,
  ///   child: HomePage(families: Families.data),
  /// ),
  /// ```
  ///
  /// You can also use CupertinoPage, and for a custom page builder to use
  /// custom page transitions, you can use [CustomTransitionPage].
  final GoRouterPageBuilder pageBuilder;

  /// Returns the stack of pages which should be used in the main navigator
  @override
  List<Page> pageStackBuilder(
    BuildContext context,
    GoRouterState state,
    List<Page> subRoutePageStack,
  ) =>
      [
        pageBuilder(context, state),
        ...subRoutePageStack,
      ];

  static String? _redirect(GoRouterState state) => null;

  static Page<dynamic> _builder(BuildContext context, GoRouterState state) =>
      throw Exception('GoRoute builder parameter not set');
}
