module Main exposing (main)

-- Press buttons to increment and decrement a counter.
--
-- Read how it works:
--   https://guide.elm-lang.org/architecture/buttons.html
--

import Browser
import Css
import Html
import Html.Styled exposing (button, div, text)
import Html.Styled.Attributes as Attr
import Html.Styled.Events exposing (onClick)
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
    = Increment
    | Decrement


update : Msg -> Model -> Model
update msg model =
    case msg of
        Increment ->
            model + 1

        Decrement ->
            model - 1



-- VIEW


view : Model -> Html.Html Msg
view model =
    div []
        [ button
            [ Attr.css [ Css.color Color.red ]
            , onClick Decrement
            ]
            [ text "-" ]
        , div [] [ text (String.fromInt model) ]
        , Button.button Increment "+"
            |> Button.withBoldText
            |> Button.withColor (Css.hex "00FF00")
            |> Button.toHtml
        ]
        |> Html.Styled.toUnstyled
