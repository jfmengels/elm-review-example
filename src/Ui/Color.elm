module Ui.Color exposing (black, blue, red)

import Css


{-| This is the collection of colors of our application. It is useful for us to
have all colors defined in one location, as it makes it much easier to reuse
colors, and find out where they are used.

It would really be a shame if somewhere in the application, there happened to be
a definition of a stray color...

-}
black : Css.Color
black =
    Css.hex "000000"


red : Css.Color
red =
    Css.hex "FF0000"


blue : Css.Color
blue =
    Css.hex "0000FF"
