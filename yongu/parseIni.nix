{ lib }:
let
  inherit (lib.strings) trim;
  inherit (lib) hasPrefix hasSuffix stringLength substring foldl' splitString;

  # Drop inline comments (anything after an unquoted # or ;).
  stripInlineComment = value:
    let
      chars = lib.stringToCharacters value;
      step = state: c:
        if state.done then
          state
        else if state.escaped then
          {
            result = state.result + c;
            inSingle = state.inSingle;
            inDouble = state.inDouble;
            escaped = false;
            done = false;
          }
        else if c == "\\" then
          {
            result = state.result + c;
            inherit (state) inSingle inDouble;
            escaped = true;
            done = false;
          }
        else if c == "'" && !state.inDouble then
          {
            result = state.result + c;
            inSingle = !state.inSingle;
            inDouble = false;
            escaped = false;
            done = false;
          }
        else if c == "\"" && !state.inSingle then
          {
            result = state.result + c;
            inSingle = false;
            inDouble = !state.inDouble;
            escaped = false;
            done = false;
          }
        else if (c == "#" || c == ";") && !state.inSingle && !state.inDouble then
          {
            inherit (state) result inSingle inDouble escaped;
            done = true;
          }
        else
          {
            result = state.result + c;
            inherit (state) inSingle inDouble;
            escaped = false;
            done = false;
          };
      final = foldl' step {
        result = "";
        inSingle = false;
        inDouble = false;
        escaped = false;
        done = false;
      } chars;
    in
    final.result;

  # Strip matching surrounding quotes from a value.
  stripQuotes = value:
    let
      len = stringLength value;
      first = if len > 0 then substring 0 1 value else "";
      last = if len > 0 then substring (len - 1) 1 value else "";
    in
    if len >= 2 && ((first == "\"" && last == "\"") || (first == "'" && last == "'")) then
      substring 1 (len - 2) value
    else
      value;

  parseValue = v: trim (stripQuotes (trim (stripInlineComment v)));

  isCommentLine = line:
    let t = trim line;
    in t == "" || hasPrefix "#" t || hasPrefix ";" t;

  isSection = line:
    let t = trim line;
    in hasPrefix "[" t && hasSuffix "]" t;

  sectionName = line:
    let t = trim line;
    in substring 1 (stringLength t - 2) t;
in
{
  # Parse an INI file into a Nix attrset.
  #
  # file: path to the INI file
  # flat: when true, ignore section headers and return a flat key/value attrset.
  #       when false, keys before the first section are top-level and each
  #       [section] becomes a nested attrset.
  parseIni = { file, flat ? false }:
    let
      content = builtins.readFile file;
      lines = splitString "\n" content;

      step = state: line:
        let
          t = trim line;
        in
        if isCommentLine t then
          state
        else if isSection t then
          if flat then
            state
          else
            state // { currentSection = sectionName t; }
        else
          let
            parts = splitString "=" t;
            key = trim (lib.head parts);
            rawValue = lib.concatStringsSep "=" (lib.tail parts);
            value = parseValue rawValue;
          in
          if flat then
            state // { result = state.result // { ${key} = value; }; }
          else if state.currentSection == "" then
            state // { result = state.result // { ${key} = value; }; }
          else
            state // {
              result = state.result // {
                ${state.currentSection} = (state.result.${state.currentSection} or {}) // { ${key} = value; };
              };
            };

      final = foldl' step { currentSection = ""; result = {}; } lines;
    in
    final.result;
}
