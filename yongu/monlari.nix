{ lib, ...}:
rec
{
  monlari = value:
    if lib.isFunction value then
      [ value ]
    else if lib.isAttrs value && value._class or null == "nixosModule" then
      lib.concatMap monlari (value.imports or [ ])
    else if lib.isAttrs value then
      lib.concatLists (lib.mapAttrsToList (name: value: monlari value) value)
    else [ ];
}
