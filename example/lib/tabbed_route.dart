import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'cupertino.dart';

void main() {
  runApp(const MyApp());
}

/// Sample app which uses the [GoTabbedRoute]
class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  /// A controller on [GoTabbedRoute], indicating the current index would be
  /// useful
  TabItem get _currentTab {
    if (tabbedRouteController.currentIndex == 0) {
      return TabItem.red;
    } else if (tabbedRouteController.currentIndex == 1) {
      return TabItem.green;
    } else {
      return TabItem.blue;
    }
  }

  final GoTabbedRouteController tabbedRouteController = GoTabbedRouteController(
    initialLocationBuilder: (context, index) => ['/red', '/green', '/blue'][index],
  );

  // This is bad, navigatorKey would be much easier, people are lost when it
  // comes to context (even more than keys)
  late BuildContext nestedNavigatorContext;

  // TODO: navigatorKey to make this possible without nestedNavigatorContext
  void _selectTab(BuildContext context, int index) {
    final activeIndex = tabbedRouteController.currentIndex;
    if (index == activeIndex) {
      // pop to first route
      Navigator.of(nestedNavigatorContext).popUntil(
        (route) => route.isFirst,
      );
    } else {
      tabbedRouteController.go(index);
    }
  }

  @override
  Widget build(BuildContext context) => MaterialApp.router(
        routeInformationParser: _router.routeInformationParser,
        routerDelegate: _router.routerDelegate,
        title: 'GoRouter Example: Sub-routes',
      );

  late final _router = GoRouter(
    initialLocation: '/red',
    navigatorBuilder: (context, child) => Navigator(
      pages: [
        MaterialPage<void>(
          child: Scaffold(
            body: child,
            bottomNavigationBar: BottomNavigation(
              currentTab: _currentTab,
              onSelectTab: _selectTab,
            ),
          ),
        ),
      ],
      onPopPage: (a, dynamic b) => a.didPop(b),
    ),
    routes: [
      GoTabbedRoute(
        path: '/',
        controller: tabbedRouteController,
        routes: TabItem.values.map(_coloredRoute).toList(),
        pageBuilder: (context, state, child) => MaterialPage<void>(
          key: state.pageKey,
          child: child,
        ),
      ),
    ],
    errorPageBuilder: (context, state) => MaterialPage<void>(
      key: state.pageKey,
      child: ErrorPage(state.error),
    ),
  );

  GoRoute _coloredRoute(TabItem tabItem) => GoRoute(
          path: tabName[tabItem]!,
          pageBuilder: (context, state) => MaterialPage<void>(
                key: state.pageKey,
                child: Builder(builder: (context) {
                  nestedNavigatorContext = context;
                  return ColorsListScreen(
                    color: activeTabColor[tabItem]!,
                    title: tabName[tabItem]!,
                    onPush: (materialIndex) {
                      context.go('/${tabName[tabItem]!}/details_$materialIndex');
                    },
                  );
                }),
              ),
          routes: [
            GoRoute(
              path: 'details_:materialIndex',
              pageBuilder: (context, state) => MaterialPage<void>(
                key: state.pageKey,
                child: ColorDetailScreen(
                  color: activeTabColor[tabItem]!,
                  title: tabName[tabItem]!,
                  materialIndex: int.parse(state.params['materialIndex']!),
                ),
              ),
            ),
          ]);
}

class BottomNavigation extends StatelessWidget {
  const BottomNavigation({
    required this.currentTab,
    required this.onSelectTab,
    Key? key,
  }) : super(key: key);

  final TabItem currentTab;
  final void Function(BuildContext context, int index) onSelectTab;

  @override
  Widget build(BuildContext context) => BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: [
          _buildItem(TabItem.red),
          _buildItem(TabItem.green),
          _buildItem(TabItem.blue),
        ],
        onTap: (index) => onSelectTab(context, index),
        currentIndex: currentTab.index,
        selectedItemColor: activeTabColor[currentTab],
      );

  BottomNavigationBarItem _buildItem(TabItem tabItem) => BottomNavigationBarItem(
        icon: Icon(
          Icons.layers,
          color: _colorTabMatching(tabItem),
        ),
        label: tabName[tabItem],
      );

  Color _colorTabMatching(TabItem item) =>
      currentTab == item ? activeTabColor[item]! : Colors.grey;
}

class ColorDetailScreen extends StatelessWidget {
  const ColorDetailScreen({
    required this.color,
    required this.title,
    Key? key,
    this.materialIndex = 500,
  }) : super(key: key);

  final MaterialColor color;
  final String title;
  final int materialIndex;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          backgroundColor: color,
          title: Text(
            '$title[$materialIndex]',
          ),
        ),
        body: Container(
          color: color[materialIndex],
        ),
      );
}

class ColorsListScreen extends StatelessWidget {
  ColorsListScreen({
    required this.color,
    required this.title,
    this.onPush,
    Key? key,
  }) : super(key: key);

  final MaterialColor color;
  final String title;
  final ValueChanged<int>? onPush;

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
        title: Text(
          title,
        ),
        backgroundColor: color,
      ),
      body: Container(
        color: Colors.white,
        child: _buildList(),
      ));

  final List<int> materialIndices = [900, 800, 700, 600, 500, 400, 300, 200, 100, 50];

  Widget _buildList() => ListView.builder(
      itemCount: materialIndices.length,
      itemBuilder: (content, index) {
        final materialIndex = materialIndices[index];
        return Container(
          color: color[materialIndex],
          child: ListTile(
            title: Text('$materialIndex', style: const TextStyle(fontSize: 24)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => onPush?.call(materialIndex),
          ),
        );
      });
}

enum TabItem { red, green, blue }

const Map<TabItem, String> tabName = {
  TabItem.red: 'red',
  TabItem.green: 'green',
  TabItem.blue: 'blue',
};

const Map<TabItem, MaterialColor> activeTabColor = {
  TabItem.red: Colors.red,
  TabItem.green: Colors.green,
  TabItem.blue: Colors.blue,
};
