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
  late final ManualLocationLookup _lookup;
  String? _countryCode;
  String? _languageCode;
  ManualLocationCandidate? _selected;

  @override
  void initState() {
    super.initState();
    _lookup = widget.lookup ?? ManualLocationLookup();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final String language = AppStrings.of(context).locale.languageCode;
    if (_languageCode != null && _languageCode != language) {
      _selected = null;
    }
    _languageCode = language;
  }

  String _countryName(String code) =>
      countryNames[_languageCode]?[code] ?? countryNames['en']![code]!;

  Future<void> _chooseCountry() async {
    final String? code = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => const _CountryPicker(),
    );
    if (!mounted || code == null || code == _countryCode) return;
    setState(() {
      _countryCode = code;
      _selected = null;
    });
  }

  Future<void> _chooseCity() async {
    final String? countryCode = _countryCode;
    final String? languageCode = _languageCode;
    if (countryCode == null || languageCode == null) return;
    final ManualLocationCandidate? candidate =
        await showDialog<ManualLocationCandidate>(
          context: context,
          builder: (BuildContext context) => _CityPicker(
            lookup: _lookup,
            countryCode: countryCode,
            countryName: _countryName(countryCode),
            timezoneId: widget.timezoneId,
            languageCode: languageCode,
            initialCity: _selected?.location.city,
            onEdited: () {
              if (mounted && _selected != null) {
                setState(() => _selected = null);
              }
            },
          ),
        );
    if (!mounted || candidate == null || countryCode != _countryCode) return;
    setState(() => _selected = candidate);
  }

  @override
  Widget build(BuildContext context) {
    final AppStrings s = AppStrings.of(context);
    return AlertDialog(
      scrollable: true,
      title: Text(s.t('selectLocation')),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(s.t('country')),
            const SizedBox(height: 6),
            _DropdownButton(
              key: const Key('manual-country-dropdown'),
              onPressed: _chooseCountry,
              text: _countryCode == null
                  ? s.t('searchCountry')
                  : _countryName(_countryCode!),
            ),
            const SizedBox(height: 16),
            Text(s.t('city')),
            const SizedBox(height: 6),
            _DropdownButton(
              key: const Key('manual-city-dropdown'),
              onPressed: _countryCode == null ? null : _chooseCity,
              text: _selected?.location.city ?? s.t('searchCity'),
            ),
            const SizedBox(height: 16),
            DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Icon(
                      Icons.info_outline_rounded,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        s.t('automaticLocationRecommended'),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          key: const Key('manual-location-cancel'),
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

class _DropdownButton extends StatelessWidget {
  const _DropdownButton({
    required this.onPressed,
    required this.text,
    super.key,
  });

  final VoidCallback? onPressed;
  final String text;

  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: onPressed,
    style: OutlinedButton.styleFrom(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 10, 14),
      alignment: AlignmentDirectional.centerStart,
    ),
    child: Row(
      children: <Widget>[
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.start,
          ),
        ),
        const SizedBox(width: 8),
        const Icon(Icons.arrow_drop_down),
      ],
    ),
  );
}

class _CityPicker extends StatefulWidget {
  const _CityPicker({
    required this.lookup,
    required this.countryCode,
    required this.countryName,
    required this.timezoneId,
    required this.languageCode,
    required this.onEdited,
    this.initialCity,
  });

  final ManualLocationLookup lookup;
  final String countryCode;
  final String countryName;
  final String timezoneId;
  final String languageCode;
  final String? initialCity;
  final VoidCallback onEdited;

  @override
  State<_CityPicker> createState() => _CityPickerState();
}

class _CityPickerState extends State<_CityPicker> {
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;
  int _generation = 0;
  List<ManualLocationCandidate> _suggestions = const [];
  String? _messageKey;
  bool _searching = false;
  bool _notifiedEdit = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialCity ?? '');
  }

  @override
  void dispose() {
    _generation++;
    _debounce?.cancel();
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _queryChanged(String value) {
    _generation++;
    _debounce?.cancel();
    if (!_notifiedEdit && value != (widget.initialCity ?? '')) {
      _notifiedEdit = true;
      widget.onEdited();
    }
    setState(() {
      _suggestions = const [];
      _messageKey = null;
      _searching = false;
    });
    if (value.trim().length < 2) return;
    _debounce = Timer(const Duration(milliseconds: 400), _search);
  }

  Future<void> _search() async {
    final String query = _controller.text.trim();
    if (query.length < 2) return;
    final int request = ++_generation;
    setState(() {
      _searching = true;
      _messageKey = null;
    });
    try {
      final List<ManualLocationCandidate> results = await widget.lookup
          .search(
            query: query,
            countryCode: widget.countryCode,
            countryName: widget.countryName,
            timezoneId: widget.timezoneId,
            languageCode: widget.languageCode,
          )
          .timeout(const Duration(seconds: 12));
      if (!mounted || request != _generation) return;
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
      _suggestions = const [];
      _searching = false;
      _messageKey = key;
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppStrings s = AppStrings.of(context);
    final double availableHeight =
        MediaQuery.sizeOf(context).height -
        MediaQuery.viewInsetsOf(context).bottom -
        MediaQuery.paddingOf(context).vertical;
    final double contentHeight = math.max(
      96,
      math.min(380, availableHeight - 205),
    );
    return AlertDialog(
      scrollable: true,
      title: Text(s.t('city')),
      content: SizedBox(
        width: 400,
        height: contentHeight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextField(
              key: const Key('manual-city-search-field'),
              controller: _controller,
              focusNode: _focusNode,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                hintText: s.t('searchCity'),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searching
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : null,
              ),
              onChanged: _queryChanged,
              onSubmitted: (_) {
                _debounce?.cancel();
                _search();
              },
            ),
            const SizedBox(height: 6),
            if (_searching)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(s.t('searchingPlace')),
              ),
            Expanded(
              child: _messageKey != null
                  ? Center(
                      child: Text(
                        s.t(_messageKey!),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : _suggestions.isEmpty
                  ? const SizedBox.shrink()
                  : ListView.separated(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      itemCount: _suggestions.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (BuildContext context, int index) {
                        final ManualLocationCandidate candidate =
                            _suggestions[index];
                        return ListTile(
                          key: ValueKey<String>(
                            'city-suggestion-${candidate.location.latitude}-'
                            '${candidate.location.longitude}',
                          ),
                          contentPadding: EdgeInsets.zero,
                          title: Text(candidate.location.city),
                          subtitle: candidate.subtitle.isEmpty
                              ? null
                              : Text(candidate.subtitle),
                          onTap: () => Navigator.of(context).pop(candidate),
                        );
                      },
                    ),
            ),
            const Divider(height: 1),
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text(
                '© OpenStreetMap contributors',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11),
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          key: const Key('manual-city-cancel'),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(s.t('cancel')),
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
          children: <Widget>[
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
                      itemBuilder: (BuildContext context, int index) {
                        final MapEntry<String, String> entry = matches[index];
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
      actions: <Widget>[
        TextButton(
          key: const Key('manual-country-cancel'),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(s.t('cancel')),
        ),
      ],
    );
  }
}
