{ lib }:
{
  # Parse a swaylock-style key-value config file into a Nix attrset.
  #
  # Each non-empty, non-comment line becomes one attribute:
  #   - Bare keys become boolean true.
  #     Example: "show-failed-attempts" -> { show-failed-attempts = true; }
  #   - "key=value" pairs become strings.
  #     Example: "color=1e1e1e" -> { color = "1e1e1e"; }
  #
  # Only the first '=' on a line is treated as the separator, so values may
  # contain additional '=' characters.
  parseSwaylock =
    { file }:
    let
      raw = builtins.readFile file;
      lines = lib.splitString "\n" raw;

      isCommentOrEmpty = line:
        let
          trimmed = lib.trim line;
        in
        trimmed == "" || lib.hasPrefix "#" trimmed;

      parseLine = line:
        let
          trimmed = lib.trim line;
          m = builtins.match "([^=]+)(=(.*))?" trimmed;
          key = lib.trim (lib.elemAt m 0);
          rawValue = lib.elemAt m 2;
        in
        lib.nameValuePair key (if rawValue == null then true else lib.trim rawValue);
    in
    lib.listToAttrs (map parseLine (lib.filter (l: !isCommentOrEmpty l) lines));
}
