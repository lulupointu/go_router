import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'cupertino.dart';

void main() {
  runApp(MyApp());
}

/// Sample app which uses the [GoTabbedRoute]
class MyApp extends StatefulWidget {
  MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();

  static GoRoute _coloredRoute(TabItem tabItem) => GoRoute(
          path: tabName[tabItem]!,
          pageBuilder: (context, state) => MaterialPage<void>(
                key: state.pageKey,
                child: Builder(
                    builder: (context) => ColorsListScreen(
                          color: activeTabColor[tabItem]!,
                          title: tabName[tabItem]!,
                          onPush: (materialIndex) {
                            print('Go to ${'/${tabName[tabItem]!}/details_$materialIndex'}');
                            context.go('/${tabName[tabItem]!}/details_$materialIndex');
                          },
                        )),
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

class _MyAppState extends State<MyApp> {
  /// A controller on [GoTabbedRoute], indicating the current index would be
  /// useful
  TabItem _currentTab(String location) {
    if (location.startsWith('/red')) {
      return TabItem.red;
    } else if (location.startsWith('/blue')) {
      return TabItem.blue;
    } else {
      return TabItem.green;
    }
  }

  int _currentIndex(String location) {
    switch (_currentTab(location)) {
      case TabItem.red:
        return 0;
      case TabItem.green:
        return 1;
      case TabItem.blue:
        return 2;
    }
  }

  final _navigatorKeys = {
    TabItem.red: GlobalKey<NavigatorState>(),
    TabItem.green: GlobalKey<NavigatorState>(),
    TabItem.blue: GlobalKey<NavigatorState>(),
  };

  /// This could be made useless by the controller mentioned bellow
  Map<TabItem, String> tabsLastVisitedUrl = {
    TabItem.red: '/red',
    TabItem.blue: '/blue',
    TabItem.green: '/green',
  };

  /// A controller to switch between tabs would be great. However this would
  /// mean remembering the previous path, ie storing some state in a route,
  /// which is not currently possible
  void _selectTab(BuildContext context, String location, TabItem tabItem) {
    if (tabItem == _currentTab(location)) {
      // pop to first route
      _navigatorKeys[tabItem]!.currentState!.popUntil((route) => route.isFirst);
    } else {
      print('Go to ${tabsLastVisitedUrl[tabItem]}');
      context.go(tabsLastVisitedUrl[tabItem]!);
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
    navigatorBuilder: (context, child) {
      final location = GoRouter.of(context).location;
      tabsLastVisitedUrl[_currentTab(location)] = location;

      return Navigator(
        pages: [
          MaterialPage<void>(
            child: Scaffold(
              body: child,
              bottomNavigationBar: BottomNavigation(
                currentTab: _currentTab(location),
                onSelectTab: (idx) => _selectTab(context, location, idx),
              ),
            ),
          ),
        ],
        onPopPage: (a, dynamic b) => a.didPop(b),
      );
    },
    routes: [
      GoTabbedRoute(
        path: '/',
        currentIndex: (_, state) => _currentIndex(state.location),
        routes: TabItem.values.map(MyApp._coloredRoute).toList(),
        pageBuilder: (context, state, child) =>
            MaterialPage<void>(key: state.pageKey, child: child),
      ),
    ],
    errorPageBuilder: (context, state) => MaterialPage<void>(
      key: state.pageKey,
      child: ErrorPage(state.error),
    ),
  );
}

class BottomNavigation extends StatelessWidget {
  BottomNavigation({required this.currentTab, required this.onSelectTab});

  final TabItem currentTab;
  final ValueChanged<TabItem> onSelectTab;

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      items: [
        _buildItem(TabItem.red),
        _buildItem(TabItem.green),
        _buildItem(TabItem.blue),
      ],
      onTap: (index) => onSelectTab(TabItem.values[index]),
      currentIndex: currentTab.index,
      selectedItemColor: activeTabColor[currentTab]!,
    );
  }

  BottomNavigationBarItem _buildItem(TabItem tabItem) {
    return BottomNavigationBarItem(
      icon: Icon(
        Icons.layers,
        color: _colorTabMatching(tabItem),
      ),
      label: tabName[tabItem],
    );
  }

  Color _colorTabMatching(TabItem item) {
    return currentTab == item ? activeTabColor[item]! : Colors.grey;
  }
}

class ColorDetailScreen extends StatelessWidget {
  ColorDetailScreen({required this.color, required this.title, this.materialIndex: 500});

  final MaterialColor color;
  final String title;
  final int materialIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
}

class ColorsListScreen extends StatelessWidget {
  ColorsListScreen({required this.color, required this.title, this.onPush});

  final MaterialColor color;
  final String title;
  final ValueChanged<int>? onPush;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
  }

  final List<int> materialIndices = [900, 800, 700, 600, 500, 400, 300, 200, 100, 50];

  Widget _buildList() {
    return ListView.builder(
        itemCount: materialIndices.length,
        itemBuilder: (BuildContext content, int index) {
          int materialIndex = materialIndices[index];
          return Container(
            color: color[materialIndex],
            child: ListTile(
              title: Text('$materialIndex', style: TextStyle(fontSize: 24.0)),
              trailing: Icon(Icons.chevron_right),
              onTap: () => onPush?.call(materialIndex),
            ),
          );
        });
  }
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
