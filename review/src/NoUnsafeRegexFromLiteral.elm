module NoUnsafeRegexFromLiteral exposing (rule)

{-| Forbids misusing the unsafe function `Helpers.Regex.fromLiteral`.

**Note**: This version is too simplistic to be used. Check out the `master` branch
for the final and safe version.

-}

import Elm.Syntax.Expression as Expression exposing (Expression)
import Elm.Syntax.Node as Node exposing (Node)
import Regex
import Review.Rule as Rule exposing (Error, Rule)


rule : Rule
rule =
    Rule.newModuleRuleSchema "NoUnsafeRegexFromLiteral" ()
        |> Rule.withSimpleExpressionVisitor expressionVisitor
        |> Rule.fromModuleRuleSchema


expressionVisitor : Node Expression -> List (Error {})
expressionVisitor node =
    case Node.value node of
        Expression.Application (function :: argument :: []) ->
            case Node.value function of
                Expression.FunctionOrValue [ "Helpers", "Regex" ] "fromLiteral" ->
                    case Node.value argument of
                        Expression.Literal string ->
                            case Regex.fromString string of
                                Just _ ->
                                    []

                                Nothing ->
                                    [ Rule.error invalidRegex (Node.range node)
                                    ]

                        _ ->
                            [ Rule.error nonLiteralValue (Node.range node) ]

                _ ->
                    []

        _ ->
            []


invalidRegex : { message : String, details : List String }
invalidRegex =
    { message = "Helpers.Regex.fromLiteral needs to be called with a valid regex."
    , details =
        [ "The regex you passed does not evaluate to a valid regex. Please fix it or use `Regex.fromString`."
        ]
    }


nonLiteralValue : { message : String, details : List String }
nonLiteralValue =
    { message = "Helpers.Regex.fromLiteral needs to be called with a static string literal."
    , details =
        [ "This function serves to give you more guarantees about creating regular expressions, but if the argument is dynamic or too complex, I won't be able to tell you."
        , "Either make the argument static or use Regex.fromString."
        ]
    }
