/// Names that should be shown exactly like this in English mode.
const Map<String, String> _overrides = {'መዝገበ ስብሐት': 'Mezgebe Sibhat'};

String displayName(String raw, String langCode) {
  final s = raw.replaceAll('_', ' ').trim();
  if (langCode == 'am') return s;
  final o = _overrides[s];
  if (o != null) return o;
  return _translit(s);
}

// Consonant for each 8-codepoint block starting at U+1200.
const _bases = <int, String>{
  0x1200: 'h',
  0x1208: 'l',
  0x1210: 'h',
  0x1218: 'm',
  0x1220: 's',
  0x1228: 'r',
  0x1230: 's',
  0x1238: 'sh',
  0x1240: 'q',
  0x1248: 'qw',
  0x1250: 'q',
  0x1258: 'qw',
  0x1260: 'b',
  0x1268: 'v',
  0x1270: 't',
  0x1278: 'ch',
  0x1280: 'h',
  0x1288: 'hw',
  0x1290: 'n',
  0x1298: 'ny',
  0x12A0: '',
  0x12A8: 'k',
  0x12B0: 'kw',
  0x12B8: 'kh',
  0x12C0: 'kw',
  0x12C8: 'w',
  0x12D0: '',
  0x12D8: 'z',
  0x12E0: 'zh',
  0x12E8: 'y',
  0x12F0: 'd',
  0x12F8: 'j',
  0x1300: 'j',
  0x1308: 'g',
  0x1310: 'gw',
  0x1318: 'ng',
  0x1320: 't',
  0x1328: 'ch',
  0x1330: 'p',
  0x1338: 'ts',
  0x1340: 'ts',
  0x1348: 'f',
  0x1350: 'p',
};

// Blocks whose first-order vowel reads as "a" (ሀ ሐ ኀ አ ዐ).
const _aFirst = {0x1200, 0x1210, 0x1280, 0x12A0, 0x12D0};

// Orders: 1st, 2nd, 3rd, 4th, 5th, 6th, 7th, 8th(labialized)
const _vowels = ['e', 'u', 'i', 'a', 'e', '', 'o', 'wa'];

String _translit(String input) {
  final out = StringBuffer();
  var consonantRun = 0; // consonants written without a vowel in a row
  var atWordStart = true;

  for (final r in input.runes) {
    if (r >= 0x1200 && r <= 0x1357) {
      final base = r - ((r - 0x1200) % 8);
      final order = (r - 0x1200) % 8;
      final c = _bases[base];
      if (c != null) {
        var v = _vowels[order];
        if (order == 0 && _aFirst.contains(base)) v = 'a';
        if (order == 5) {
          // Sixth order: silent in most positions, but insert "i" at the
          // start of a word or to break up a run of consonants.
          if (atWordStart || consonantRun >= 2) {
            v = 'i';
          }
        }
        out.write('$c$v');
        consonantRun = v.isEmpty ? consonantRun + 1 : 0;
        atWordStart = false;
        continue;
      }
    }

    // Ge'ez punctuation
    if (r == 0x1361 || r == 0x1362) {
      out.write(r == 0x1362 ? '. ' : ' ');
      atWordStart = true;
      consonantRun = 0;
      continue;
    }
    if (r == 0x1363) {
      out.write(', ');
      atWordStart = true;
      consonantRun = 0;
      continue;
    }

    final ch = String.fromCharCode(r);
    out.write(ch);
    atWordStart = ch.trim().isEmpty || ch == '-' || ch == '.';
    consonantRun = 0;
  }

  final t = out.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
  if (t.isEmpty) return t;
  // Capitalize first letter of each word
  return t
      .split(' ')
      .map((w) {
        if (w.isEmpty) return w;
        final i = w.indexOf(RegExp(r'[A-Za-z]'));
        if (i < 0) return w;
        return w.substring(0, i) + w[i].toUpperCase() + w.substring(i + 1);
      })
      .join(' ');
}
