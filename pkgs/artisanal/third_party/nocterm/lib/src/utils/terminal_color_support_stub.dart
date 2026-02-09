bool? _overrideTruecolor;

bool supportsTruecolor() {
  return _overrideTruecolor ?? true;
}

void setSupportsTruecolorForTesting(bool? value) {
  _overrideTruecolor = value;
}
