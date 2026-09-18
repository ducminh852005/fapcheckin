import 'package:flutter/material.dart';
import 'package:fapcheckin/core/constants/app_spacing.dart';
import 'package:fapcheckin/views/teacher/settings/components/settings_header.dart';
import 'package:fapcheckin/views/teacher/settings/components/settings_sidebar.dart';
import 'package:fapcheckin/views/teacher/settings/components/settings_section_qr.dart';
import 'package:fapcheckin/views/teacher/settings/components/settings_section_security.dart';
import 'package:fapcheckin/views/teacher/settings/components/settings_section_sync.dart';
import 'package:fapcheckin/views/teacher/settings/components/settings_section_alerts.dart';
import 'package:fapcheckin/views/teacher/settings/components/settings_section_profile.dart';
import 'package:fapcheckin/views/teacher/settings/components/settings_footer.dart';

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
        duration: const Duration(milliseconds: 300),
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
              padding: const EdgeInsets.only(
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                top: AppSpacing.lg,
                bottom: 100, // Padding for sticky footer
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SettingsHeader(),
                  const SizedBox(height: AppSpacing.lg),
                  
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
                        const SizedBox(width: AppSpacing.lg),
                        // Content
                        Expanded(
                          child: _buildSectionsList(),
                        ),
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
                        const SizedBox(height: AppSpacing.lg),
                        _buildSectionsList(),
                      ],
                    ),
                ],
              ),
            ),
            
            // Sticky Footer
            const Positioned(
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              bottom: AppSpacing.lg,
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
        const SizedBox(height: AppSpacing.lg),
        SettingsSectionSecurity(key: _sectionKeys['security']),
        const SizedBox(height: AppSpacing.lg),
        SettingsSectionSync(key: _sectionKeys['sync']),
        const SizedBox(height: AppSpacing.lg),
        SettingsSectionAlerts(key: _sectionKeys['alerts']),
        const SizedBox(height: AppSpacing.lg),
        SettingsSectionProfile(key: _sectionKeys['profile']),
      ],
    );
  }
}
