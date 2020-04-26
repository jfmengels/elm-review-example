module NoUnsafeRegexFromLiteralTest exposing (all)

import NoUnsafeRegexFromLiteral exposing (rule)
import Review.Test
import Test exposing (Test, describe, test)


all : Test
all =
    describe "NoUnsafeRegexFromLiteral"
        [ test "should not report calls to Helpers.Regex.fromLiteral with a valid literal regex" <|
            \_ ->
                """module A exposing (..)
import Helpers.Regex
a = Helpers.Regex.fromLiteral "^abc$"
"""
                    |> Review.Test.run rule
                    |> Review.Test.expectNoErrors
        , test "should report calls to Helpers.Regex.fromLiteral with an invalid literal regex" <|
            \_ ->
                """module A exposing (..)
import Helpers.Regex
a = Helpers.Regex.fromLiteral "^ab($cd"
"""
                    |> Review.Test.run rule
                    |> Review.Test.expectErrors
                        [ Review.Test.error
                            { message = "Helpers.Regex.fromLiteral needs to be called with a valid regex."
                            , details =
                                [ "The regex you passed does not evaluate to a valid regex. Please fix it or use `Regex.fromString`."
                                ]
                            , under = """Helpers.Regex.fromLiteral "^ab($cd\""""
                            }
                        ]
        , test "should report calls to Helpers.Regex.fromLiteral with a non-literal value" <|
            \_ ->
                """module A exposing (..)
import Helpers.Regex
a = Helpers.Regex.fromLiteral dynamicValue
"""
                    |> Review.Test.run rule
                    |> Review.Test.expectErrors
                        [ Review.Test.error
                            { message = "Helpers.Regex.fromLiteral needs to be called with a static string literal."
                            , details =
                                [ "This function serves to give you more guarantees about creating regular expressions, but if the argument is dynamic or too complex, I won't be able to tell you."
                                , "Either make the argument static or use Regex.fromString."
                                ]
                            , under = "Helpers.Regex.fromLiteral dynamicValue"
                            }
                        ]
        , test "should report invalid calls if the function is called through a module alias" <|
            \_ ->
                """module A exposing (..)
import Helpers.Regex as R
a = R.fromLiteral dynamicValue
"""
                    |> Review.Test.run rule
                    |> Review.Test.expectErrors
                        [ Review.Test.error
                            { message = "Helpers.Regex.fromLiteral needs to be called with a static string literal."
                            , details =
                                [ "This function serves to give you more guarantees about creating regular expressions, but if the argument is dynamic or too complex, I won't be able to tell you."
                                , "Either make the argument static or use Regex.fromString."
                                ]
                            , under = "R.fromLiteral dynamicValue"
                            }
                        ]
        , test "should report invalid calls if the function is called through a direct import" <|
            \_ ->
                """module A exposing (..)
import Helpers.Regex exposing (fromLiteral)
a = fromLiteral dynamicValue
"""
                    |> Review.Test.run rule
                    |> Review.Test.expectErrors
                        [ Review.Test.error
                            { message = "Helpers.Regex.fromLiteral needs to be called with a static string literal."
                            , details =
                                [ "This function serves to give you more guarantees about creating regular expressions, but if the argument is dynamic or too complex, I won't be able to tell you."
                                , "Either make the argument static or use Regex.fromString."
                                ]
                            , under = "fromLiteral dynamicValue"
                            }
                        ]
        , test "should report invalid calls if the function is called through an import that exposes all" <|
            \_ ->
                """module A exposing (..)
import Helpers.Regex exposing (..)
a = fromLiteral dynamicValue
"""
                    |> Review.Test.run rule
                    |> Review.Test.expectErrors
                        [ Review.Test.error
                            { message = "Helpers.Regex.fromLiteral needs to be called with a static string literal."
                            , details =
                                [ "This function serves to give you more guarantees about creating regular expressions, but if the argument is dynamic or too complex, I won't be able to tell you."
                                , "Either make the argument static or use Regex.fromString."
                                ]
                            , under = "fromLiteral dynamicValue"
                            }
                        ]
        , test "should not report invalid calls if the function was not imported" <|
            \_ ->
                """module A exposing (..)
import Helpers.Regex
a = fromLiteral dynamicValue
"""
                    |> Review.Test.run rule
                    |> Review.Test.expectNoErrors
        , test "should report when function is used is used in a non 'function call' context" <|
            \_ ->
                """module A exposing (..)
import Helpers.Regex
fromLiteralAlias = Helpers.Regex.fromLiteral
"""
                    |> Review.Test.run rule
                    |> Review.Test.expectErrors
                        [ Review.Test.error
                            { message = "Helpers.Regex.fromLiteral must be called directly."
                            , details =
                                [ "This function serves to give you more guarantees about creating regular expressions, but I can't determine how it is used if you do something else than calling it directly."
                                ]
                            , under = "Helpers.Regex.fromLiteral"
                            }
                        ]
        ]
