# CustardKit

## 互換性方針

azooKeyはiOSのアプリで、iOSのアプリでは基本的に常にユーザが最新アプリケーションを利用することを仮定できます。
したがって、旧仕様のJSONが新仕様のAppで読める必要はありますが、新仕様のJSONを旧仕様のAppで読める必要はありません。

## QWERTY専用system key

`qwerty_language_switch`、`qwerty_shift`、`qwerty_dynamic_change`、
`qwerty_space`は、`pc_style`かつ`grid_fit`のインターフェースでのみ
利用できます。その他の組み合わせはencode・decode時の検証で拒否されます。
