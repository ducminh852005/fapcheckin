import 'package:flutter/material.dart';
import 'package:fapcheckin_core/constants/app_spacing.dart';
import './components/settings_header.dart';
import './components/settings_sidebar.dart';
import './components/settings_section_qr.dart';
import './components/settings_section_security.dart';
import './components/settings_section_sync.dart';
import './components/settings_section_alerts.dart';
import './components/settings_section_profile.dart';
import './components/settings_footer.dart';
import 'package:fapcheckin_core/responsive/breakpoints.dart';

class SettingsBody extends StatefulWidget {
  const SettingsBody({super.key});

  @override
  State<SettingsBody> createState() => _SettingsBodyState();
}

class _SettingsBodyState extends State<SettingsBody> {
  // Keys for each section to scroll to
  final Map<String, GlobalKey> _sectionKeys = {
    'qr': GlobalKey(),
    'security': GlobalKey(),
    'sync': GlobalKey(),
    'alerts': GlobalKey(),
    'profile': GlobalKey(),
  };

  // State to track the active tab
  String _activeTab = 'qr';

  void _scrollToSection(String sectionKey) {
    setState(() {
      _activeTab = sectionKey;
    });

    final key = _sectionKeys[sectionKey];
    if (key != null && key.currentContext != null) {
      Scrollable.ensureVisible(
        key.currentContext!,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        alignment: 0.05, // Slight padding from top
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 900;

        return Stack(
          children: [
            SingleChildScrollView(
              padding: EdgeInsets.only(
                left: context.pagePadding,
                right: context.pagePadding,
                top: context.pagePadding,
                bottom: context.isMobile
                    ? 160
                    : 100, // Padding for sticky footer
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SettingsHeader(),
                  SizedBox(height: AppSpacing.lg),

                  // Main layout: Sidebar + Content
                  if (isDesktop)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Sidebar
                        SizedBox(
                          width: 280,
                          child: SettingsSidebar(
                            activeTab: _activeTab,
                            onTabSelect: _scrollToSection,
                          ),
                        ),
                        SizedBox(width: AppSpacing.lg),
                        // Content
                        Expanded(child: _buildSectionsList()),
                      ],
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SettingsSidebar(
                          activeTab: _activeTab,
                          onTabSelect: _scrollToSection,
                        ),
                        SizedBox(height: AppSpacing.lg),
                        _buildSectionsList(),
                      ],
                    ),
                ],
              ),
            ),

            // Sticky Footer
            Positioned(
              left: context.pagePadding,
              right: context.pagePadding,
              bottom: context.pagePadding,
              child: SettingsFooter(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionsList() {
    return Column(
      children: [
        SettingsSectionQr(key: _sectionKeys['qr']),
        SizedBox(height: AppSpacing.lg),
        SettingsSectionSecurity(key: _sectionKeys['security']),
        SizedBox(height: AppSpacing.lg),
        SettingsSectionSync(key: _sectionKeys['sync']),
        SizedBox(height: AppSpacing.lg),
        SettingsSectionAlerts(key: _sectionKeys['alerts']),
        SizedBox(height: AppSpacing.lg),
        SettingsSectionProfile(key: _sectionKeys['profile']),
      ],
    );
  }
}
