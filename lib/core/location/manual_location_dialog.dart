import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:salah_focus/app/localization/app_strings.dart';
import 'package:salah_focus/core/location/country_names.dart';
import 'package:salah_focus/core/location/manual_location_lookup.dart';
import 'package:salah_focus/features/prayer_times/domain/user_location.dart';

class ManualLocationDialog extends StatefulWidget {
  const ManualLocationDialog({
    required this.timezoneId,
    this.lookup,
    super.key,
  });

  final String timezoneId;
  final ManualLocationLookup? lookup;

  @override
  State<ManualLocationDialog> createState() => _ManualLocationDialogState();
}

class _ManualLocationDialogState extends State<ManualLocationDialog> {
  final TextEditingController _cityController = TextEditingController();
  Timer? _debounce;
  int _generation = 0;
  String? _countryCode;
  String? _languageCode;
  List<ManualLocationCandidate> _suggestions = const [];
  ManualLocationCandidate? _selected;
  String? _messageKey;
  bool _searching = false;
  bool _validating = false;

  ManualLocationLookup get _lookup => widget.lookup ?? ManualLocationLookup();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final String language = AppStrings.of(context).locale.languageCode;
    if (_languageCode != null && _languageCode != language) {
      _generation++;
      _debounce?.cancel();
      _suggestions = const [];
      _selected = null;
      _searching = false;
      _validating = false;
      if (_countryCode != null && _cityController.text.trim().isNotEmpty) {
        _scheduleSearch();
      }
    }
    _languageCode = language;
  }

  @override
  void dispose() {
    _generation++;
    _debounce?.cancel();
    _cityController.dispose();
    super.dispose();
  }

  String _countryName(String code) =>
      countryNames[_languageCode]?[code] ?? countryNames['en']![code]!;

  Future<void> _chooseCountry() async {
    final String? code = await showDialog<String>(
      context: context,
      builder: (context) => const _CountryPicker(),
    );
    if (!mounted || code == null || code == _countryCode) return;
    _generation++;
    _debounce?.cancel();
    _cityController.clear();
    setState(() {
      _countryCode = code;
      _suggestions = const [];
      _selected = null;
      _messageKey = null;
      _searching = false;
      _validating = false;
    });
  }

  void _cityChanged(String value) {
    _generation++;
    _debounce?.cancel();
    setState(() {
      _selected = null;
      _suggestions = const [];
      _messageKey = null;
      _searching = false;
    });
    _scheduleSearch();
  }

  void _scheduleSearch() {
    if (_countryCode == null || _cityController.text.trim().isEmpty) return;
    _debounce = Timer(const Duration(milliseconds: 350), _search);
  }

  Future<void> _search() async {
    final String? code = _countryCode;
    if (code == null) return;
    final int request = ++_generation;
    final String language = _languageCode!;
    final String query = _cityController.text.trim();
    setState(() {
      _searching = true;
      _messageKey = null;
    });
    try {
      final List<ManualLocationCandidate> results = await _lookup
          .search(
            query: query,
            countryCode: code,
            countryName: _countryName(code),
            timezoneId: widget.timezoneId,
            languageCode: language,
          )
          .timeout(const Duration(seconds: 12));
      if (!mounted ||
          request != _generation ||
          language != _languageCode ||
          code != _countryCode) {
        return;
      }
      setState(() {
        _suggestions = results;
        _searching = false;
        _messageKey = results.isEmpty ? 'noPlaces' : null;
      });
    } on TimeoutException {
      _searchFailed(request, 'placeTimeout');
    } on Object {
      _searchFailed(request, 'placeError');
    }
  }

  void _searchFailed(int request, String key) {
    if (!mounted || request != _generation) return;
    setState(() {
      _searching = false;
      _messageKey = key;
    });
  }

  Future<void> _validate() async {
    final String? code = _countryCode;
    if (code == null || _cityController.text.trim().isEmpty) return;
    _debounce?.cancel();
    final int request = ++_generation;
    final String language = _languageCode!;
    final String query = _cityController.text.trim();
    setState(() {
      _validating = true;
      _searching = false;
      _messageKey = null;
    });
    try {
      final ManualLocationCandidate? candidate = await _lookup
          .nearby(
            query: query,
            countryCode: code,
            countryName: _countryName(code),
            timezoneId: widget.timezoneId,
            languageCode: language,
          )
          .timeout(const Duration(seconds: 12));
      if (!mounted ||
          request != _generation ||
          language != _languageCode ||
          code != _countryCode) {
        return;
      }
      if (candidate == null) {
        setState(() {
          _validating = false;
          _messageKey = 'placeNotFound';
        });
        return;
      }
      if (normalizedLocationText(candidate.location.city) ==
          normalizedLocationText(query)) {
        _select(candidate);
        return;
      }
      setState(() => _validating = false);
      final bool? accepted = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          final AppStrings s = AppStrings.of(dialogContext);
          final String city = candidate.location.label;
          return AlertDialog(
            title: Text(s.t('selectLocation')),
            content: Text(s.t('nearbyPlace', params: {'city': city})),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(s.t('chooseAnother')),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(
                  s.t('useNearby', params: {'city': candidate.location.city}),
                ),
              ),
            ],
          );
        },
      );
      if (mounted && request == _generation && accepted == true) {
        _select(candidate);
      }
    } on TimeoutException {
      _validationFailed(request, 'placeTimeout');
    } on Object {
      _validationFailed(request, 'placeError');
    }
  }

  void _validationFailed(int request, String key) {
    if (!mounted || request != _generation) return;
    setState(() {
      _validating = false;
      _messageKey = key;
    });
  }

  void _select(ManualLocationCandidate candidate) {
    _generation++;
    _debounce?.cancel();
    _cityController.text = candidate.location.city;
    setState(() {
      _selected = candidate;
      _suggestions = const [];
      _searching = false;
      _validating = false;
      _messageKey = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppStrings s = AppStrings.of(context);
    final double availableHeight =
        MediaQuery.sizeOf(context).height -
        MediaQuery.viewInsetsOf(context).bottom -
        MediaQuery.paddingOf(context).vertical;
    final double maxHeight = math.max(
      80,
      math.min(availableHeight * 0.45, availableHeight - 180),
    );
    return AlertDialog(
      scrollable: true,
      title: Text(s.t('selectLocation')),
      content: SizedBox(
        width: 400,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(s.t('country')),
                const SizedBox(height: 6),
                OutlinedButton.icon(
                  onPressed: _chooseCountry,
                  icon: const Icon(Icons.arrow_drop_down),
                  label: Text(
                    _countryCode == null
                        ? s.t('searchCountry')
                        : _countryName(_countryCode!),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  key: const Key('manual-city-field'),
                  controller: _cityController,
                  enabled: _countryCode != null,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: s.t('city'),
                    hintText: s.t('searchCity'),
                    suffixIcon: _searching || _validating
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : null,
                  ),
                  onChanged: _cityChanged,
                  onSubmitted: (_) => _validate(),
                ),
                if (_searching)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(s.t('searchingPlace')),
                  ),
                if (_messageKey != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(s.t(_messageKey!)),
                  ),
                for (final ManualLocationCandidate candidate in _suggestions)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(candidate.location.city),
                    subtitle: Text(candidate.subtitle),
                    onTap: () => _select(candidate),
                  ),
                if (_countryCode != null &&
                    _cityController.text.trim().isNotEmpty &&
                    _selected == null &&
                    !_validating)
                  TextButton(
                    onPressed: _validate,
                    child: Text(s.t('validatePlace')),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(s.t('cancel')),
        ),
        FilledButton(
          onPressed: _selected == null
              ? null
              : () =>
                    Navigator.of(context)
                        .pop<UserLocation>(_selected!.location),
          child: Text(s.t('save')),
        ),
      ],
    );
  }
}

class _CountryPicker extends StatefulWidget {
  const _CountryPicker();

  @override
  State<_CountryPicker> createState() => _CountryPickerState();
}

class _CountryPickerState extends State<_CountryPicker> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppStrings s = AppStrings.of(context);
    final double availableHeight =
        MediaQuery.sizeOf(context).height -
        MediaQuery.viewInsetsOf(context).bottom -
        MediaQuery.paddingOf(context).vertical;
    final Map<String, String> names =
        countryNames[s.locale.languageCode] ?? countryNames['en']!;
    final String query = normalizedLocationText(_searchController.text.trim());
    final List<MapEntry<String, String>> matches = names.entries.where((entry) {
      return normalizedLocationText(entry.value).contains(query) ||
          normalizedLocationText(countryNames['en']![entry.key] ?? '')
              .contains(query);
    }).toList()..sort((a, b) => a.value.compareTo(b.value));
    return AlertDialog(
      scrollable: true,
      title: Text(s.t('country')),
      content: SizedBox(
        width: 400,
        height: math.max(
          80,
          math.min(availableHeight * 0.55, availableHeight - 160),
        ),
        child: Column(
          children: [
            TextField(
              key: const Key('country-search-field'),
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: s.t('searchCountry'),
                prefixIcon: const Icon(Icons.search),
              ),
              onChanged: (_) => setState(() {}),
            ),
            Expanded(
              child: matches.isEmpty
                  ? Center(child: Text(s.t('noPlaces')))
                  : ListView.builder(
                      itemCount: matches.length,
                      itemBuilder: (context, index) {
                        final entry = matches[index];
                        return ListTile(
                          title: Text(entry.value),
                          onTap: () => Navigator.of(context).pop(entry.key),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(s.t('cancel')),
        ),
      ],
    );
  }
}
