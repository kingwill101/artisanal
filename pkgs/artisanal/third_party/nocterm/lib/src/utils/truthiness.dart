bool truthy(String value) {
  return value == '1' || value == 'true' || value == 'yes' || value == 'on';
}

bool falsey(String value) {
  return value == '0' ||
      value == 'false' ||
      value == 'no' ||
      value == 'off' ||
      value.isEmpty;
}
