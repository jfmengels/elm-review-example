module Ui.Button exposing (button, toHtml, withBoldText, withColor)

import Css
import Html.Styled as Html exposing (Html)
import Html.Styled.Attributes as Attr
import Html.Styled.Events as Events
import Ui.Color as Color


{-| This is our great Button module. By using this module all over our
application, we are sure to have a consistent UI.

It would really be a shame if somewhere in the application, there happened to be
a regular Html button instead of this module...

-}
type Font
    = NormalFont
    | BoldFont


type Button msg
    = Button
        { color : Css.Color
        , font : Font
        , onClick : msg
        , text : String
        }


button : msg -> String -> Button msg
button onClick text =
    Button
        { color = Color.black
        , font = NormalFont
        , onClick = onClick
        , text = text
        }


withColor : Css.Color -> Button msg -> Button msg
withColor color (Button button_) =
    Button { button_ | color = color }


withBoldText : Button msg -> Button msg
withBoldText (Button button_) =
    Button { button_ | font = BoldFont }


toHtml : Button msg -> Html msg
toHtml (Button button_) =
    Html.button
        [ Attr.css
            [ Css.color button_.color
            , case button_.font of
                NormalFont ->
                    Css.fontWeight Css.normal

                BoldFont ->
                    Css.fontWeight Css.bold
            ]
        , Events.onClick button_.onClick
        ]
        [ Html.text button_.text ]
