import 'package:country_picker/country_picker.dart';
import 'package:country_picker/src/utils.dart';
import 'package:flutter/material.dart';

import 'country.dart';
import 'res/country_codes.dart';

class CountryListView extends StatefulWidget {
  /// Called when a country is select.
  ///
  /// The country picker passes the new value to the callback.
  final ValueChanged<Country> onSelect;

  /// An optional [showPhoneCode] argument can be used to show phone code.
  final bool showPhoneCode;

  final bool showGroup;

  final bool trFirst;

  /// An optional [exclude] argument can be used to exclude(remove) one ore more
  /// country from the countries list. It takes a list of country code(iso2).
  /// Note: Can't provide both [exclude] and [countryFilter]
  final List<String> exclude;

  /// An optional [countryFilter] argument can be used to filter the
  /// list of countries. It takes a list of country code(iso2).
  /// Note: Can't provide both [countryFilter] and [exclude]
  final List<String> countryFilter;

  const CountryListView({
    Key key,
    @required this.onSelect,
    this.exclude,
    this.countryFilter,
    this.showPhoneCode = false,
    this.showGroup = true,
    this.trFirst = false,
  })
      : assert(onSelect != null),
        assert(exclude == null || countryFilter == null,
        'Cannot provide both exclude and countryFilter'),
        super(key: key);

  @override
  _CountryListViewState createState() => _CountryListViewState();
}

class _CountryListViewState extends State<CountryListView> {
  List<Country> _countryList;
  List<Country> _filteredList;
  TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _initCodes();
  }

  void _initCodes() {
    Future.delayed(const Duration(milliseconds: 10), () {
      print('future.delayed');
      _countryList =
          countryCodes.map((country) {
            Country countryObj = Country.from(json: country);

            var cName = CountryLocalizations.of(context)
                ?.countryName(countryCode: countryObj.countryCode) ??
                countryObj.name;
            countryObj.name = cName;

            return countryObj;
          }).toList();

      _countryList.sort((a, b) {
        String s1 = a.name
            .replaceAll("Å", "Aa")
            .replaceAll("Ç", "Czzz")
            .replaceAll("Ö", "Ozzz")
            .replaceAll("Ü", "Uzzz")
            .replaceAll("İ", "Izzz")
            .replaceAll("Ş", "Szzz");

        String s2 = b.name
            .replaceAll("Å", "Aa")
            .replaceAll("Ç", "Czzz")
            .replaceAll("Ö", "Ozzz")
            .replaceAll("Ü", "Uzzz")
            .replaceAll("İ", "Izzz")
            .replaceAll("Ş", "Szzz");

        if (widget.trFirst) {
          if (b.countryCode == 'TR') {
            s2 = "AAAAAAA";
          }
          if (a.countryCode == 'TR') {
            s1 = "AAAAAAA";
          }
        }

        return s1.compareTo(s2);
      });

      //Remove duplicates country if not use phone code
      if (!widget.showPhoneCode) {
        final ids = _countryList.map((e) => e.countryCode).toSet();
        _countryList.retainWhere((country) => ids.remove(country.countryCode));
      }

      if (widget.exclude != null) {
        _countryList.removeWhere(
                (element) => widget.exclude.contains(element.countryCode));
      }
      if (widget.countryFilter != null) {
        _countryList.removeWhere(
                (element) => !widget.countryFilter.contains(element.countryCode));
      }

      _filteredList = <Country>[];
      _filteredList.addAll(_countryList);
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final String searchLabel =
        CountryLocalizations.of(context)?.countryName(countryCode: 'search') ??
            'Search';

    if (_countryList == null || _countryList.isEmpty) {
      return Container();
    }

    return Column(
      children: <Widget>[
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: searchLabel,
              hintText: searchLabel,
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderSide: BorderSide(
                  color: const Color(0xFF8C98A8).withOpacity(0.2),
                ),
              ),
            ),
            onChanged: _filterSearchResults,
          ),
        ),
        Expanded(
          child: ListView(
            children: _filteredList
                .map<Widget>((country) => _listRow(country))
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _listRow(Country country) {
    return Material(
      // Add Material Widget with transparent color
      // so the ripple effect of InkWell will show on tap
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          widget.onSelect(country);
//          Navigator.pop(context);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5.0),
          child: Row(
            children: <Widget>[
              const SizedBox(width: 20),
              (country.countryCode != "TRK") ?
              Text(
                Utils.countryCodeToEmoji(country.countryCode),
                style: const TextStyle(fontSize: 25),
              ) :
              Image.network("https://www.seyahatsagligi.gov.tr/Content/Theme/images/flags/flag_KTC.png", width: 32,)
              ,
              if (widget.showPhoneCode) ...[
                const SizedBox(width: 15),
                Container(
                  width: 45,
                  child: Text(
                    '+${country.phoneCode}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(width: 5),
              ] else
                const SizedBox(width: 15),
              Expanded(
                child: Text(country.name,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              if (widget.showGroup) ...[
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                  width: 45,
                  child: Text(
                    country.group != null ? '${country.group}' : "D",
                    style: TextStyle(fontSize: 16, color: country.group != null ? Colors.blueGrey : Colors.black12),
                    textAlign: TextAlign.right,
                  ),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }

  void _filterSearchResults(String query) {
    List<Country> _searchResult = <Country>[];
    final CountryLocalizations localizations = CountryLocalizations.of(context);

    if (query.isEmpty) {
      _searchResult.addAll(_countryList);
    } else {
      _searchResult = _countryList
          .where((c) => c.startsWith(query, localizations))
          .toList();
    }

    setState(() => _filteredList = _searchResult);
  }
}
