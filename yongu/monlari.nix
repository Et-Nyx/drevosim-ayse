{ lib, ...}:
rec
{
  monlari = attrs: lib.concatLists (lib.mapAttrsToList (
    name: value:
    if lib.isFunction value then [ value ]
    else if lib.isAttrs value then monlari value
    else [ ]
  ) attrs);
}
