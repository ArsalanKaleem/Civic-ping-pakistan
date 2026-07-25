import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../widgets/badges.dart';
import 'authorities_screen.dart';
import 'dashboard_screen.dart';
import 'email_logs_screen.dart';
import 'reports_screen.dart';
import 'social_queue_screen.dart';

/// Desktop console shell: navigation rail + content pane.
class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;

  static const _pages = [
    DashboardScreen(),
    SocialQueueScreen(),
    ReportsScreen(),
    AuthoritiesScreen(),
    EmailLogsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Row(children: [
        NavigationRail(
          extended: MediaQuery.sizeOf(context).width > 1100,
          minExtendedWidth: 220,
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          leading: const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: BrandMark(size: 18),
          ),
          trailing: Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(
                    auth.displayName,
                    style: TextStyle(
                        fontSize: 11, color: scheme.onSurfaceVariant),
                    overflow: TextOverflow.ellipsis,
                  ),
                  IconButton(
                    tooltip: 'Sign out',
                    icon: const Icon(Icons.logout, size: 20),
                    onPressed: auth.signOut,
                  ),
                ]),
              ),
            ),
          ),
          destinations: const [
            NavigationRailDestination(
                icon: Icon(Icons.dashboard_outlined),
                label: Text('Dashboard')),
            NavigationRailDestination(
                icon: Icon(Icons.campaign_outlined),
                label: Text('Social queue')),
            NavigationRailDestination(
                icon: Icon(Icons.report_outlined),
                label: Text('Reports')),
            NavigationRailDestination(
                icon: Icon(Icons.account_balance_outlined),
                label: Text('Authorities')),
            NavigationRailDestination(
                icon: Icon(Icons.mail_outline),
                label: Text('Email logs')),
          ],
        ),
        VerticalDivider(width: 1, color: scheme.outline),
        Expanded(child: _pages[_index]),
      ]),
    );
  }
}
