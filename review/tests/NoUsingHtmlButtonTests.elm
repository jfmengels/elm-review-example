module NoUsingHtmlButtonTests exposing (all)

import NoUsingHtmlButton exposing (rule)
import Review.Test
import Test exposing (Test, describe, test)


message : String
message =
    "Use Ui.Button instead of the native Html.button"


details : List String
details =
    [ "At fruits.com, we try to have a consistent UI across the application, and one of the ways we do that is by having a single great module to create buttons, named Ui.Button."
    , "Here, you defined a button using `Html.button` or `Html.Styled.button`, which is likely not to have the consistent UI we aim for or some of the guarantees we created around our buttons."
    , "Instead, you should use the Ui.Button module. I suggest reading the documentation in that module, but here is what it would kind of look like:"
    , """    import Ui.Button as Button

    myButton =
        Button.button UserClickedOnButton "Button text"
            |> Button.withColor Color.red
            |> Button.toHtml
"""
    ]


tests : List Test
tests =
    [ test "should not report the use of a local `button` function" <|
        \() ->
            """module A exposing (..)
button = foo
a = button 1"""
                |> Review.Test.run rule
                |> Review.Test.expectNoErrors
    , test "should not report the use of a `button` function imported from a package that is not Html or Html.Styled" <|
        \() ->
            """module A exposing (..)
import Foo exposing (button)
a = button 1"""
                |> Review.Test.run rule
                |> Review.Test.expectNoErrors
    , test "should not report the use of a `button` function that may be imported from a package that is not Html or Html.Styled" <|
        \() ->
            """module A exposing (..)
import Foo exposing (..)
a = button 1"""
                |> Review.Test.run rule
                |> Review.Test.expectNoErrors
    , test "should not report the use of `Ui.Button.button` (unqualified)" <|
        \() ->
            """module A exposing (..)
import Ui.Button exposing (button)
a = button 1"""
                |> Review.Test.run rule
                |> Review.Test.expectNoErrors
    , test "should not report the use of `Ui.Button.button` (qualified)" <|
        \() ->
            """module A exposing (..)
import Ui.Button as Button
a = Button.button 1
"""
                |> Review.Test.run rule
                |> Review.Test.expectNoErrors

    -- FAILING TESTS
    , test "should report the use of `Html.button` outside of the `Ui.Button` module (qualified)" <|
        \() ->
            """module A exposing (..)
import Html
a = Html.button 1
"""
                |> Review.Test.run rule
                |> Review.Test.expectErrors
                    [ Review.Test.error
                        { message = message
                        , details = details
                        , under = "Html.button"
                        }
                    ]
    , test "should report the use of `Html.button` outside of the `Ui.Button` module (unqualified)" <|
        \() ->
            """module A exposing (..)
import Html exposing (button)
a = button 1
"""
                |> Review.Test.run rule
                |> Review.Test.expectErrors
                    [ Review.Test.error
                        { message = message
                        , details = details
                        , under = "button"
                        }
                        |> Review.Test.atExactly { start = { row = 3, column = 5 }, end = { row = 3, column = 11 } }
                    ]
    , test "should report the use of `Html.Styled.button` outside of the `Ui.Button` module (qualified)" <|
        \() ->
            """module A exposing (..)
import Html.Styled
a = Html.Styled.button 1
"""
                |> Review.Test.run rule
                |> Review.Test.expectErrors
                    [ Review.Test.error
                        { message = message
                        , details = details
                        , under = "Html.Styled.button"
                        }
                    ]
    , test "should report the use of `Html.Styled.button` outside of the `Ui.Button` module (unqualified)" <|
        \() ->
            """module A exposing (..)
import Html.Styled exposing (button)
a = button 1
"""
                |> Review.Test.run rule
                |> Review.Test.expectErrors
                    [ Review.Test.error
                        { message = message
                        , details = details
                        , under = "button"
                        }
                        |> Review.Test.atExactly { start = { row = 3, column = 5 }, end = { row = 3, column = 11 } }
                    ]
    , test "should report the use of `Html.Styled.button` outside of the `Ui.Button` module (alias imported and qualified)" <|
        \() ->
            """module A exposing (..)
import Html.Styled as Html
a = Html.button 1
"""
                |> Review.Test.run rule
                |> Review.Test.expectErrors
                    [ Review.Test.error
                        { message = message
                        , details = details
                        , under = "Html.button"
                        }
                    ]
    , test "should report the use of `Html.Styled.button` outside of the `Ui.Button` module (alias imported and unqualified)" <|
        \() ->
            """module A exposing (..)
import Html.Styled as Html exposing (button)
a = button 1
"""
                |> Review.Test.run rule
                |> Review.Test.expectErrors
                    [ Review.Test.error
                        { message = message
                        , details = details
                        , under = "button"
                        }
                        |> Review.Test.atExactly { start = { row = 3, column = 5 }, end = { row = 3, column = 11 } }
                    ]
    ]


all : Test
all =
    describe "NoUsingHtmlButton" tests
