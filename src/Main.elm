module Main exposing (main)

-- Press buttons to increment and decrement a counter.
--
-- Read how it works:
--   https://guide.elm-lang.org/architecture/buttons.html
--

import Browser
import Css
import Helpers.Regex
import Html
import Html.Styled exposing (button, div, text)
import Html.Styled.Attributes as Attr
import Html.Styled.Events exposing (onClick)
import Regex exposing (Regex)
import Ui.Button as Button
import Ui.Color as Color


main : Program () Model Msg
main =
    Browser.sandbox { init = init, update = update, view = view }



-- MODEL


type alias Model =
    Int


init : Model
init =
    0



-- UPDATE


type Msg
    = UserClickedOnRemoveButton
    | UserAddedItem


update : Msg -> Model -> Model
update msg model =
    model



-- VIEW


view : Model -> Html.Html Msg
view model =
    div []
        [ button
            [ Attr.css
                [ Css.height (Css.px 34)
                , Css.fontSize (Css.px 16)
                , Css.color Color.red
                ]
            , onClick UserClickedOnRemoveButton
            ]
            [ text "Remove" ]
        , div [] [ text (String.fromInt model) ]
        , Button.button UserAddedItem "Add"
            |> Button.withColor (Css.hex "00FF00")
            |> Button.toHtml
        ]
        |> Html.Styled.toUnstyled


validRegex : Regex
validRegex =
    Helpers.Regex.fromLiteral "(abc|def)"


invalidRegex : Regex
invalidRegex =
    Helpers.Regex.fromLiteral "(abc|"
