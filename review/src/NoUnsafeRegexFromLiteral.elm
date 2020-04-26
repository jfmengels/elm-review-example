module NoUnsafeRegexFromLiteral exposing (rule)

{-| Forbids misusing the unsafe function `Helpers.Regex.fromLiteral`.

**Note**: This version is too simplistic to be used. Check out the `master` branch
for the final and safe version.

-}

import Elm.Syntax.Exposing as Exposing
import Elm.Syntax.Expression as Expression exposing (Expression)
import Elm.Syntax.Import exposing (Import)
import Elm.Syntax.ModuleName exposing (ModuleName)
import Elm.Syntax.Node as Node exposing (Node)
import Elm.Syntax.Range exposing (Range)
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
    , allowedFunctionOrValues : List Range
    }


initialContext : Context
initialContext =
    { scope = Scope.initialModuleContext
    , fromLiteralWasExposed = False
    , allowedFunctionOrValues = []
    }


isTargetFunction : Context -> ModuleName -> String -> Bool
isTargetFunction context moduleName functionName =
    if functionName /= targetFunctionName then
        False

    else
        (Scope.realModuleName context.scope targetFunctionName moduleName == targetModuleName)
            || (List.isEmpty moduleName && context.fromLiteralWasExposed)


targetModuleName : List String
targetModuleName =
    [ "Helpers", "Regex" ]


targetFunctionName : String
targetFunctionName =
    "fromLiteral"


importVisitor : Node Import -> Context -> ( List nothing, Context )
importVisitor (Node.Node _ { moduleName, exposingList }) context =
    if Node.value moduleName == targetModuleName then
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
                Expression.FunctionOrValue moduleName functionName ->
                    if isTargetFunction context moduleName functionName then
                        let
                            errors : List (Error {})
                            errors =
                                case Node.value argument of
                                    Expression.Literal string ->
                                        case Regex.fromString string of
                                            Just _ ->
                                                []

                                            Nothing ->
                                                [ Rule.error invalidRegex (Node.range node) ]

                                    _ ->
                                        [ Rule.error nonLiteralValue (Node.range node) ]
                        in
                        ( errors
                        , { context | allowedFunctionOrValues = Node.range function :: context.allowedFunctionOrValues }
                        )

                    else
                        ( [], context )

                _ ->
                    ( [], context )

        ( Rule.OnEnter, Expression.FunctionOrValue moduleName functionName ) ->
            if
                isTargetFunction context moduleName functionName
                    && not (List.member (Node.range node) context.allowedFunctionOrValues)
            then
                ( [ Rule.error notUsedAsFunction (Node.range node) ]
                , context
                )

            else
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


notUsedAsFunction : { message : String, details : List String }
notUsedAsFunction =
    { message = "Helpers.Regex.fromLiteral must be called directly."
    , details =
        [ "This function serves to give you more guarantees about creating regular expressions, but I can't determine how it is used if you do something else than calling it directly."
        ]
    }
