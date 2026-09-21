import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:salah_focus/app/legal/legal_document.dart';
import 'package:salah_focus/app/legal/legal_documents.dart';
import 'package:salah_focus/app/legal/privacy_legal_config.dart';
import 'package:salah_focus/app/localization/app_strings.dart';
import 'package:url_launcher/url_launcher.dart';

class PrivacyLegalScreen extends StatefulWidget {
  const PrivacyLegalScreen({super.key});

  @override
  State<PrivacyLegalScreen> createState() => _PrivacyLegalScreenState();
}

class _PrivacyLegalScreenState extends State<PrivacyLegalScreen> {
  late final Future<_AppVersion> _appVersion = _loadVersion();

  Future<_AppVersion> _loadVersion() async {
    try {
      final PackageInfo info = await PackageInfo.fromPlatform();
      return _AppVersion(version: info.version, buildNumber: info.buildNumber);
    } on Object {
      return const _AppVersion();
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppStrings s = AppStrings.of(context);
    final String language = s.locale.languageCode;
    return Scaffold(
      appBar: AppBar(title: Text(s.t('privacyLegal'))),
      body: ListView(
        padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 32),
        children: <Widget>[
          Card(
            child: Column(
              children: <Widget>[
                ListTile(
                  key: const ValueKey<String>('privacy-policy-tile'),
                  leading: const Icon(Icons.shield_outlined),
                  title: Text(s.t('privacyPolicy')),
                  subtitle: Text(s.t('privacyPolicySubtitle')),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _openDocument(
                    PrivacyLegalDocuments.privacyPolicy(language),
                    showOnlinePolicy: true,
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  key: const ValueKey<String>('legal-notice-tile'),
                  leading: const Icon(Icons.gavel_outlined),
                  title: Text(s.t('legalNotice')),
                  subtitle: Text(s.t('legalNoticeSubtitle')),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _openDocument(
                    PrivacyLegalDocuments.legalNotice(language),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  key: const ValueKey<String>('open-source-licenses-tile'),
                  leading: const Icon(Icons.code_rounded),
                  title: Text(s.t('openSourceLicenses')),
                  subtitle: Text(s.t('openSourceLicensesSubtitle')),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: _showLicenses,
                ),
                const Divider(height: 1),
                FutureBuilder<_AppVersion>(
                  future: _appVersion,
                  builder:
                      (BuildContext context, AsyncSnapshot<_AppVersion> value) {
                        final String label =
                            value.data?.displayValue ??
                            s.t('versionUnavailable');
                        return ListTile(
                          key: const ValueKey<String>('app-version-tile'),
                          leading: const Icon(Icons.info_outline_rounded),
                          title: Text(s.t('appVersion')),
                          subtitle: Text(label),
                        );
                      },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openDocument(LegalDocument document, {bool showOnlinePolicy = false}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LegalDocumentScreen(
          document: document,
          showOnlinePolicy: showOnlinePolicy,
        ),
      ),
    );
  }

  Future<void> _showLicenses() async {
    final AppStrings s = AppStrings.of(context);
    final _AppVersion version = await _appVersion;
    if (!mounted) return;
    showLicensePage(
      context: context,
      applicationName: s.t('appName'),
      applicationVersion: version.displayValue,
    );
  }
}

class LegalDocumentScreen extends StatelessWidget {
  const LegalDocumentScreen({
    required this.document,
    this.showOnlinePolicy = false,
    super.key,
  });

  final LegalDocument document;
  final bool showOnlinePolicy;

  @override
  Widget build(BuildContext context) {
    final AppStrings s = AppStrings.of(context);
    final Uri? onlinePolicy = showOnlinePolicy
        ? PrivacyLegalConfig.privacyPolicyUri
        : null;
    return Scaffold(
      appBar: AppBar(title: Text(document.title)),
      body: SelectionArea(
        child: ListView(
          padding: const EdgeInsetsDirectional.fromSTEB(20, 12, 20, 36),
          children: <Widget>[
            Text(
              '${s.t('lastUpdatedLabel')}: ${document.lastUpdated}',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              document.introduction,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 22),
            for (final LegalSection section in document.sections) ...<Widget>[
              Text(
                section.title,
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              for (final String paragraph in section.paragraphs) ...<Widget>[
                Text(paragraph, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 8),
            ],
            _ContactCard(strings: s),
            if (onlinePolicy != null) ...<Widget>[
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  key: const ValueKey<String>('online-privacy-policy-link'),
                  leading: const Icon(Icons.open_in_new_rounded),
                  title: Text(s.t('onlinePrivacyPolicy')),
                  subtitle: Text(s.t('onlinePrivacyPolicySubtitle')),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _openOnlinePolicy(context, onlinePolicy),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _openOnlinePolicy(BuildContext context, Uri uri) async {
    bool opened = false;
    try {
      opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on Exception {
      // URL handlers can be missing or fail after the system accepts a launch.
    }
    if (opened || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppStrings.of(context).t('unableToOpenLink'))),
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({required this.strings});

  final AppStrings strings;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            strings.t('contactDetails'),
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          _ContactLine(
            label: strings.t('responsiblePerson'),
            value: PrivacyLegalConfig.controllerName,
          ),
          _ContactLine(
            label: strings.t('address'),
            value: PrivacyLegalConfig.controllerLocation,
          ),
          _ContactLine(
            label: strings.t('email'),
            value: PrivacyLegalConfig.contactEmail,
          ),
        ],
      ),
    ),
  );
}

class _ContactLine extends StatelessWidget {
  const _ContactLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.only(bottom: 8),
    child: Text.rich(
      TextSpan(
        children: <InlineSpan>[
          TextSpan(
            text: '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          TextSpan(text: value),
        ],
      ),
    ),
  );
}

class _AppVersion {
  const _AppVersion({this.version = '', this.buildNumber = ''});

  final String version;
  final String buildNumber;

  String? get displayValue {
    if (version.isEmpty) return null;
    return buildNumber.isEmpty ? version : '$version ($buildNumber)';
  }
}
