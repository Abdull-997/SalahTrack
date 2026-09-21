import 'package:flutter/material.dart';
import 'package:salah_focus/app/localization/app_strings.dart';
import 'package:salah_focus/features/settings/data/problem_report_service.dart';
import 'package:salah_focus/features/settings/domain/problem_report.dart';

class ReportProblemScreen extends StatefulWidget {
  const ReportProblemScreen({this.service, super.key});

  final ProblemReportService? service;

  @override
  State<ReportProblemScreen> createState() => _ReportProblemScreenState();
}

class _ReportProblemScreenState extends State<ReportProblemScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _stepsController = TextEditingController();
  late final ProblemReportService _service;
  ProblemCategory? _category;
  ProblemTechnicalInfo? _technicalInfo;
  String? _loadedLanguage;
  bool _loadingTechnicalInfo = true;
  bool _technicalInfoFailed = false;
  bool _openingEmail = false;
  int _loadGeneration = 0;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? PlatformProblemReportService();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final String language = AppStrings.of(context).locale.languageCode;
    if (_loadedLanguage != language) {
      _loadedLanguage = language;
      _loadTechnicalInfo(language);
    }
  }

  @override
  void dispose() {
    _loadGeneration++;
    _descriptionController.dispose();
    _stepsController.dispose();
    super.dispose();
  }

  Future<void> _loadTechnicalInfo(String language) async {
    final int request = ++_loadGeneration;
    if (mounted) {
      setState(() {
        _loadingTechnicalInfo = true;
        _technicalInfoFailed = false;
      });
    }
    try {
      final ProblemTechnicalInfo info = await _service.loadTechnicalInfo(
        language,
      );
      if (!mounted || request != _loadGeneration) return;
      setState(() {
        _technicalInfo = info;
        _loadingTechnicalInfo = false;
      });
    } on Object {
      if (!mounted || request != _loadGeneration) return;
      setState(() {
        _technicalInfo = ProblemTechnicalInfo(languageCode: language);
        _technicalInfoFailed = true;
        _loadingTechnicalInfo = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppStrings s = AppStrings.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(s.t('reportProblem'))),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            key: const ValueKey<String>('problem-report-list'),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 32),
            children: <Widget>[
              Text(
                s.t('reportProblemIntro'),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 18),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      DropdownButtonFormField<ProblemCategory>(
                        key: const ValueKey<String>('problem-category-field'),
                        initialValue: _category,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: s.t('reportProblemCategory'),
                          hintText: s.t('reportSelectCategory'),
                          prefixIcon: const Icon(Icons.bug_report_outlined),
                        ),
                        items: ProblemCategory.values
                            .map(
                              (ProblemCategory category) => DropdownMenuItem(
                                value: category,
                                child: Text(s.t(category.localizationKey)),
                              ),
                            )
                            .toList(),
                        onChanged: (ProblemCategory? value) {
                          setState(() => _category = value);
                        },
                        validator: (ProblemCategory? value) => value == null
                            ? s.t('reportCategoryRequired')
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        key: const ValueKey<String>(
                          'problem-description-field',
                        ),
                        controller: _descriptionController,
                        minLines: 4,
                        maxLines: 8,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          labelText: s.t('reportWhatHappened'),
                          hintText: s.t('reportDescriptionHint'),
                          alignLabelWithHint: true,
                        ),
                        validator: (String? value) =>
                            value == null || value.trim().isEmpty
                            ? s.t('reportDescriptionRequired')
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        key: const ValueKey<String>('problem-steps-field'),
                        controller: _stepsController,
                        minLines: 4,
                        maxLines: 8,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          labelText: s.t('reportStepsOptional'),
                          hintText: s.t('reportStepsHint'),
                          alignLabelWithHint: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              _TechnicalInformationCard(
                info: _technicalInfo,
                loading: _loadingTechnicalInfo,
                failed: _technicalInfoFailed,
                onRetry: () => _loadTechnicalInfo(s.locale.languageCode),
              ),
              const SizedBox(height: 14),
              Card(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Icon(
                        Icons.privacy_tip_outlined,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(s.t('reportPrivacyNotice'))),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                key: const ValueKey<String>('review-problem-report-button'),
                onPressed:
                    _loadingTechnicalInfo ||
                        _openingEmail ||
                        _technicalInfo == null
                    ? null
                    : _reviewReport,
                icon: _openingEmail
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.rate_review_outlined),
                label: Text(
                  _openingEmail
                      ? s.t('reportOpeningEmail')
                      : s.t('reportReviewButton'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _reviewReport() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final ProblemCategory? category = _category;
    final ProblemTechnicalInfo? technicalInfo = _technicalInfo;
    if (category == null || technicalInfo == null) return;
    final AppStrings s = AppStrings.of(context);
    final ProblemReport report = ProblemReport(
      category: category,
      description: _descriptionController.text,
      steps: _stepsController.text,
      technicalInfo: technicalInfo,
    );
    final bool openEmail =
        await showDialog<bool>(
          context: context,
          builder: (BuildContext dialogContext) => AlertDialog(
            title: Text(s.t('reportReviewTitle')),
            content: SizedBox(
              width: 520,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(s.t('reportReviewIntro')),
                    const SizedBox(height: 14),
                    SelectableText(
                      report.copyText(s),
                      key: const ValueKey<String>('problem-report-preview'),
                    ),
                  ],
                ),
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(s.t('cancel')),
              ),
              FilledButton.icon(
                key: const ValueKey<String>('open-email-app-button'),
                onPressed: () => Navigator.of(dialogContext).pop(true),
                icon: const Icon(Icons.email_outlined),
                label: Text(s.t('reportOpenEmailApp')),
              ),
            ],
          ),
        ) ??
        false;
    if (!openEmail || !mounted) return;

    setState(() => _openingEmail = true);
    final bool opened = await _service.openEmail(report.emailUri(s));
    if (!mounted) return;
    setState(() => _openingEmail = false);
    if (!opened) await _showMailUnavailable(report);
  }

  Future<void> _showMailUnavailable(ProblemReport report) async {
    final AppStrings s = AppStrings.of(context);
    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(s.t('reportMailUnavailableTitle')),
        content: Text(s.t('reportMailUnavailableBody')),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(s.t('close')),
          ),
          FilledButton.icon(
            key: const ValueKey<String>('copy-problem-report-button'),
            onPressed: () async {
              final ScaffoldMessengerState messenger = ScaffoldMessenger.of(
                context,
              );
              try {
                await _service.copyText(report.copyText(s));
              } on Object {
                if (dialogContext.mounted) {
                  messenger.showSnackBar(
                    SnackBar(content: Text(s.t('genericError'))),
                  );
                }
                return;
              }
              if (!dialogContext.mounted) return;
              Navigator.of(dialogContext).pop();
              messenger.showSnackBar(
                SnackBar(content: Text(s.t('reportCopied'))),
              );
            },
            icon: const Icon(Icons.copy_rounded),
            label: Text(s.t('reportCopyButton')),
          ),
        ],
      ),
    );
  }
}

class _TechnicalInformationCard extends StatelessWidget {
  const _TechnicalInformationCard({
    required this.info,
    required this.loading,
    required this.failed,
    required this.onRetry,
  });

  final ProblemTechnicalInfo? info;
  final bool loading;
  final bool failed;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final AppStrings s = AppStrings.of(context);
    return Card(
      key: const ValueKey<String>('problem-technical-information'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              s.t('reportTechnicalInformation'),
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              s.t('reportTechnicalIntro'),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            if (loading)
              const Center(child: CircularProgressIndicator())
            else ...<Widget>[
              if (failed)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: <Widget>[
                      Expanded(child: Text(s.t('reportTechnicalLoadFailed'))),
                      TextButton(onPressed: onRetry, child: Text(s.t('retry'))),
                    ],
                  ),
                ),
              _TechnicalLine(
                label: s.t('reportTechAppVersion'),
                value: _value(s, info?.appVersion),
              ),
              _TechnicalLine(
                label: s.t('reportTechBuild'),
                value: _value(s, info?.buildNumber),
              ),
              _TechnicalLine(
                label: s.t('reportTechPlatform'),
                value: _value(s, info?.platform),
              ),
              _TechnicalLine(
                label: s.t('reportTechOs'),
                value: _value(s, info?.osVersion),
              ),
              _TechnicalLine(
                label: s.t('reportTechDevice'),
                value: _value(s, info?.deviceModel),
              ),
              _TechnicalLine(
                label: s.t('reportTechLanguage'),
                value: _value(s, info?.languageCode),
                last: true,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _value(AppStrings strings, String? value) =>
      value == null || value.trim().isEmpty
      ? strings.t('reportNotAvailable')
      : value;
}

class _TechnicalLine extends StatelessWidget {
  const _TechnicalLine({
    required this.label,
    required this.value,
    this.last = false,
  });

  final String label;
  final String value;
  final bool last;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: last ? 0 : 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(value, textAlign: TextAlign.end)),
      ],
    ),
  );
}
