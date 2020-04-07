module NoDefiningColorsOutsideOfUiColor exposing (rule)

{-| This rule is a tiny bit simplified. It does not check for

    import Css exposing (hex)
    hex "FF0000"

nor

    import Css as C
    C.hex "FF0000"

This is done to simplify the rule a bit, but if you do want to see how to forbid
that behavior, you could take a look at the NoUsingHtmlButton example, which
does that (although it does even more).

-}

import Elm.Syntax.Expression as Expression exposing (Expression)
import Elm.Syntax.Module as Module exposing (Module)
import Elm.Syntax.Node as Node exposing (Node(..))
import Review.Rule as Rule exposing (Direction, Error, Rule)


type Context
    = AllowedToDefineColors
    | ForbiddenToDefineColors


rule : Rule
rule =
    Rule.newModuleRuleSchema "NoDefiningColorsOutsideOfUiColor" ()
        |> Rule.withExpressionVisitor expressionVisitor
        |> Rule.fromModuleRuleSchema
        |> Rule.ignoreErrorsForModules [ "Ui.Color" ]


expressionVisitor : Node Expression -> List (Error {})
expressionVisitor node =
    case Node.value node of
        Expression.Application (function :: arguments) ->
            case Node.value function of
                Expression.FunctionOrValue [ "Css" ] "hex" ->
                    [ Rule.error
                        { message = "Do not define colors outside of Ui.Color"
                        , details =
                            [ "At fruits.com, we try to have all the colors in our application defined in the Ui.Color file. This helps us to have a consistent color palette across the application."
                            , "You should define this color in the Ui.Color module, and import it to use it at this location. Do check whether the color does not already exist though."
                            ]
                        }
                        (Node.range node)
                    ]

                _ ->
                    []

        _ ->
            []
