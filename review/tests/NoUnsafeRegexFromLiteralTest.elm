module NoUnsafeRegexFromLiteralTest exposing (all)

import Elm.Project
import Expect exposing (Expectation)
import Json.Decode as Decode
import NoUnsafeRegexFromLiteral exposing (rule)
import Review.Project as Project exposing (Project)
import Review.Test
import Test exposing (Test, describe, test)


helpersRegexSourceCode : String
helpersRegexSourceCode =
    """module Helpers.Regex exposing (fromLiteral)
import Regex exposing (Regex)
fromLiteral : String -> Regex
fromLiteral = something
"""


expectErrors : List Review.Test.ExpectedError -> Review.Test.ReviewResult -> Expectation
expectErrors expectedErrors =
    Review.Test.expectErrorsForModules [ ( "A", expectedErrors ) ]


all : Test
all =
    describe "NoUnsafeRegexFromLiteral"
        [ test "should not report calls to Helpers.Regex.fromLiteral with a valid literal regex" <|
            \_ ->
                [ """module A exposing (..)
import Helpers.Regex
a = Helpers.Regex.fromLiteral "^abc$"
""", helpersRegexSourceCode ]
                    |> Review.Test.runOnModulesWithProjectData project rule
                    |> Review.Test.expectNoErrors
        , test "should report calls to Helpers.Regex.fromLiteral with an invalid literal regex" <|
            \_ ->
                [ """module A exposing (..)
import Helpers.Regex
a = Helpers.Regex.fromLiteral "^ab($cd"
""", helpersRegexSourceCode ]
                    |> Review.Test.runOnModulesWithProjectData project rule
                    |> expectErrors
                        [ Review.Test.error
                            { message = "Helpers.Regex.fromLiteral needs to be called with a valid regex."
                            , details =
                                [ "This function serves to give you more guarantees about creating regular expressions, but if the argument is dynamic or too complex, I won't be able to tell you."
                                ]
                            , under = """Helpers.Regex.fromLiteral "^ab($cd\""""
                            }
                        ]
        , test "should not report calls to Helpers.Regex.fromLiteral with an valid literal regex containing back-slashes" <|
            \_ ->
                [ """module A exposing (..)
import Helpers.Regex
a = Helpers.Regex.fromLiteral "\\\\s"
""", helpersRegexSourceCode ]
                    |> Review.Test.runOnModulesWithProjectData project rule
                    |> Review.Test.expectNoErrors
        , test "should report calls to Helpers.Regex.fromLiteral with a non-literal value" <|
            \_ ->
                [ """module A exposing (..)
import Helpers.Regex
a = Helpers.Regex.fromLiteral dynamicValue
""", helpersRegexSourceCode ]
                    |> Review.Test.runOnModulesWithProjectData project rule
                    |> expectErrors
                        [ Review.Test.error
                            { message = "Helpers.Regex.fromLiteral needs to be called with a static string literal."
                            , details =
                                [ "This function serves to give you more guarantees about creating regular expressions, but if the argument is dynamic or too complex, I won't be able to tell you."
                                , "Either make the argument static or use Regex.fromString instead."
                                ]
                            , under = "Helpers.Regex.fromLiteral dynamicValue"
                            }
                        ]
        , test "should report invalid calls if the function is called through a module alias" <|
            \_ ->
                [ """module A exposing (..)
import Helpers.Regex as R
a = R.fromLiteral dynamicValue
""", helpersRegexSourceCode ]
                    |> Review.Test.runOnModulesWithProjectData project rule
                    |> expectErrors
                        [ Review.Test.error
                            { message = "Helpers.Regex.fromLiteral needs to be called with a static string literal."
                            , details =
                                [ "This function serves to give you more guarantees about creating regular expressions, but if the argument is dynamic or too complex, I won't be able to tell you."
                                , "Either make the argument static or use Regex.fromString instead."
                                ]
                            , under = "R.fromLiteral dynamicValue"
                            }
                        ]
        , test "should report invalid calls if the function is called through a direct import" <|
            \_ ->
                [ """module A exposing (..)
import Helpers.Regex exposing (fromLiteral)
a = fromLiteral dynamicValue
""", helpersRegexSourceCode ]
                    |> Review.Test.runOnModulesWithProjectData project rule
                    |> expectErrors
                        [ Review.Test.error
                            { message = "Helpers.Regex.fromLiteral needs to be called with a static string literal."
                            , details =
                                [ "This function serves to give you more guarantees about creating regular expressions, but if the argument is dynamic or too complex, I won't be able to tell you."
                                , "Either make the argument static or use Regex.fromString instead."
                                ]
                            , under = "fromLiteral dynamicValue"
                            }
                        ]
        , test "should report invalid calls if the function is called through an import that exposes all" <|
            \_ ->
                [ """module A exposing (..)
import Helpers.Regex exposing (..)
a = fromLiteral dynamicValue
""", helpersRegexSourceCode ]
                    |> Review.Test.runOnModulesWithProjectData project rule
                    |> expectErrors
                        [ Review.Test.error
                            { message = "Helpers.Regex.fromLiteral needs to be called with a static string literal."
                            , details =
                                [ "This function serves to give you more guarantees about creating regular expressions, but if the argument is dynamic or too complex, I won't be able to tell you."
                                , "Either make the argument static or use Regex.fromString instead."
                                ]
                            , under = "fromLiteral dynamicValue"
                            }
                        ]
        , test "should not report invalid calls if the function was not imported" <|
            \_ ->
                [ """module A exposing (..)
import Helpers.Regex
a = fromLiteral dynamicValue
""", helpersRegexSourceCode ]
                    |> Review.Test.runOnModulesWithProjectData project rule
                    |> Review.Test.expectNoErrors
        , test "should report when function is used is used in a non 'function call' context" <|
            \_ ->
                [ """module A exposing (..)
import Helpers.Regex
fromLiteralAlias = Helpers.Regex.fromLiteral
""", helpersRegexSourceCode ]
                    |> Review.Test.runOnModulesWithProjectData project rule
                    |> expectErrors
                        [ Review.Test.error
                            { message = "Helpers.Regex.fromLiteral must be called directly."
                            , details =
                                [ "This function serves to give you more guarantees about creating regular expressions, but I can't determine how it is used if you do something else than calling it directly."
                                ]
                            , under = "Helpers.Regex.fromLiteral"
                            }
                        ]
        , test "should report a global error when the target function could not be found in the project" <|
            \_ ->
                """module A exposing (..)
import Helpers.Regex
a = Helpers.Regex.fromLiteral "^abc$"
"""
                    |> Review.Test.runWithProjectData project rule
                    |> Review.Test.expectErrorsForElmJson
                        [ Review.Test.error
                            { message = "Could not find Helpers.Regex.fromLiteral."
                            , details =
                                [ "I want to provide guarantees on the use of this function, but I can't find it. It is likely that it was renamed, which prevents me from giving you these guarantees."
                                , "You should rename it back or update this rule to the new name. If you do not use the function anymore, remove the rule."
                                ]
                            , under = "{"
                            }
                            |> Review.Test.atExactly { start = { row = 1, column = 1 }, end = { row = 1, column = 2 } }
                        ]
        ]



-- PROJECT DATA


project : Project
project =
    Project.new
        |> Project.addElmJson (createElmJson applicationElmJson)


createElmJson : String -> { path : String, raw : String, project : Elm.Project.Project }
createElmJson rawElmJson =
    case Decode.decodeString Elm.Project.decoder rawElmJson of
        Ok elmJson ->
            { path = "elm.json"
            , raw = rawElmJson
            , project = elmJson
            }

        Err _ ->
            Debug.todo "Invalid elm.json supplied to test"


applicationElmJson : String
applicationElmJson =
    """{
    "type": "application",
    "source-directories": [
        "src"
    ],
    "elm-version": "0.19.1",
    "dependencies": {
        "direct": {
            "elm/core": "1.0.0"
        },
        "indirect": {}
    },
    "test-dependencies": {
        "direct": {},
        "indirect": {}
    }
}"""
