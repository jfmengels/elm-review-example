module Helpers.Regex exposing (fromLiteral)

import Regex exposing (Regex)


fromLiteral : String -> Regex
fromLiteral string =
    case Regex.fromString string of
        Just regex ->
            regex

        Nothing ->
            fromLiteral string
