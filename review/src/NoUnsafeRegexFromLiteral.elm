module NoUnsafeRegexFromLiteral exposing (rule)

{-| Forbids misusing the unsafe function `Helpers.Regex.fromLiteral`.

**Note**: This version is too simplistic to be used. Check out the `master` branch
for the final and safe version.

-}

import Elm.Syntax.Exposing as Exposing
import Elm.Syntax.Expression as Expression exposing (Expression)
import Elm.Syntax.Import exposing (Import)
import Elm.Syntax.Node as Node exposing (Node)
import Regex
import Review.Rule as Rule exposing (Error, Rule)
import Scope


rule : Rule
rule =
    Rule.newModuleRuleSchema "NoUnsafeRegexFromLiteral" initialContext
        |> Scope.addModuleVisitors
        |> Rule.withImportVisitor importVisitor
        |> Rule.withExpressionVisitor expressionVisitor
        |> Rule.fromModuleRuleSchema


type alias Context =
    { scope : Scope.ModuleContext
    , fromLiteralWasExposed : Bool
    }


initialContext : Context
initialContext =
    { scope = Scope.initialModuleContext
    , fromLiteralWasExposed = False
    }


importVisitor : Node Import -> Context -> ( List nothing, Context )
importVisitor (Node.Node _ { moduleName, exposingList }) context =
    if Node.value moduleName == [ "Helpers", "Regex" ] then
        case Maybe.map Node.value exposingList of
            Just (Exposing.All _) ->
                ( [], { context | fromLiteralWasExposed = True } )

            _ ->
                ( [], context )

    else
        ( [], context )


expressionVisitor : Node Expression -> Rule.Direction -> Context -> ( List (Error {}), Context )
expressionVisitor node direction context =
    case ( direction, Node.value node ) of
        ( Rule.OnEnter, Expression.Application (function :: argument :: []) ) ->
            case Node.value function of
                Expression.FunctionOrValue moduleName "fromLiteral" ->
                    if
                        (Scope.realModuleName context.scope "fromLiteral" moduleName == [ "Helpers", "Regex" ])
                            || (List.isEmpty moduleName && context.fromLiteralWasExposed)
                    then
                        case Node.value argument of
                            Expression.Literal string ->
                                case Regex.fromString string of
                                    Just _ ->
                                        ( [], context )

                                    Nothing ->
                                        ( [ Rule.error invalidRegex (Node.range node) ]
                                        , context
                                        )

                            _ ->
                                ( [ Rule.error nonLiteralValue (Node.range node) ]
                                , context
                                )

                    else
                        ( [], context )

                _ ->
                    ( [], context )

        _ ->
            ( [], context )


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
