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
import Lint.Rule as Rule exposing (Direction, Error, Rule)


type Context
    = AllowedToDefineColors
    | ForbiddenToDefineColors


rule : Rule
rule =
    Rule.newSchema "NoDefiningColorsOutsideOfUiColor"
        |> Rule.withInitialContext ForbiddenToDefineColors
        |> Rule.withModuleDefinitionVisitor moduleDefinitionVisitor
        |> Rule.withExpressionVisitor expressionVisitor
        |> Rule.fromSchema


moduleDefinitionVisitor : Node Module -> context -> ( List Error, Context )
moduleDefinitionVisitor (Node range moduleDefinition) context =
    case Module.moduleName moduleDefinition of
        -- If the analyzed file is Ui.Color, then we don't want to report anything.
        -- This is the sole location where we are allowed to defined colors.
        [ "Ui", "Color" ] ->
            ( [], AllowedToDefineColors )

        _ ->
            ( [], ForbiddenToDefineColors )


expressionVisitor : Node Expression -> Direction -> Context -> ( List Error, Context )
expressionVisitor node direction context =
    case context of
        AllowedToDefineColors ->
            ( [], context )

        ForbiddenToDefineColors ->
            case ( direction, Node.value node ) of
                ( Rule.OnEnter, Expression.Application (function :: arguments) ) ->
                    case Node.value function of
                        Expression.FunctionOrValue [ "Css" ] "hex" ->
                            ( [ Rule.error
                                    { message = "Do not define colors outside of Ui.Color"
                                    , details =
                                        [ "At fruits.com, we try to have all the colors in our application defined in the Ui.Color file. This helps us to have a consistent color palette across the application."
                                        , "You should define this color in the Ui.Color module, and import it to use it at this location. Do check whether the color does not already exist though."
                                        ]
                                    }
                                    (Node.range node)
                              ]
                            , context
                            )

                        _ ->
                            ( [], context )

                _ ->
                    ( [], context )
