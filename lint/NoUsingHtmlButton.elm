module NoUsingHtmlButton exposing (rule)

import Elm.Syntax.Exposing as Exposing
import Elm.Syntax.Expression as Expression exposing (Expression)
import Elm.Syntax.Import exposing (Import)
import Elm.Syntax.Module as Module exposing (Module)
import Elm.Syntax.Node as Node exposing (Node(..))
import Lint.Rule as Rule exposing (Direction, Error, Rule)


type Context
    = AllowedToUseHtmlButton
    | ForbiddenToUseHtmlButton
        { hasImportedButtonInGlobalScope : Bool
        , htmlModules : List (List String)
        }


rule : Rule
rule =
    Rule.newSchema "NoUsingHtmlButton"
        |> Rule.withInitialContext
            (ForbiddenToUseHtmlButton
                { hasImportedButtonInGlobalScope = False
                , htmlModules =
                    [ [ "Html" ]
                    , [ "Html", "Styled" ]
                    ]
                }
            )
        |> Rule.withImportVisitor importVisitor
        |> Rule.withModuleDefinitionVisitor moduleDefinitionVisitor
        |> Rule.withExpressionVisitor expressionVisitor
        |> Rule.fromSchema


moduleDefinitionVisitor : Node Module -> Context -> ( List Error, Context )
moduleDefinitionVisitor (Node range moduleDefinition) context =
    case Module.moduleName moduleDefinition of
        [ "Ui", "Button" ] ->
            -- If the analyzed file is Ui.Button, then we don't want to report anything.
            -- This is the sole location where we are allowed to use the native `button` function.
            ( [], AllowedToUseHtmlButton )

        _ ->
            ( [], context )


importVisitor : Node Import -> Context -> ( List Error, Context )
importVisitor node context =
    case context of
        AllowedToUseHtmlButton ->
            ( [], context )

        ForbiddenToUseHtmlButton contextData ->
            let
                importedModuleName : List String
                importedModuleName =
                    Node.value node
                        |> .moduleName
                        |> Node.value

                importAlias : () -> List (List String)
                importAlias () =
                    case Node.value node |> .moduleAlias |> Maybe.map Node.value of
                        Nothing ->
                            []

                        Just alias_ ->
                            [ alias_ ]
            in
            if importedModuleName == [ "Html", "Styled" ] || importedModuleName == [ "Html" ] then
                case Node.value node |> .exposingList |> Maybe.map Node.value of
                    Just (Exposing.All _) ->
                        ( []
                        , ForbiddenToUseHtmlButton
                            { contextData
                                | hasImportedButtonInGlobalScope = True
                                , htmlModules = List.concat [ importAlias (), contextData.htmlModules ]
                            }
                        )

                    Just (Exposing.Explicit importedElements) ->
                        ( []
                        , ForbiddenToUseHtmlButton
                            { contextData
                                | hasImportedButtonInGlobalScope = containsButton importedElements
                                , htmlModules = List.concat [ importAlias (), contextData.htmlModules ]
                            }
                        )

                    _ ->
                        ( [], context )

            else
                ( [], context )


containsButton : List (Node Exposing.TopLevelExpose) -> Bool
containsButton importedElements =
    case importedElements of
        [] ->
            False

        (Node range (Exposing.FunctionExpose "button")) :: _ ->
            True

        _ :: restOfImportedElements ->
            containsButton restOfImportedElements


expressionVisitor : Node Expression -> Direction -> Context -> ( List Error, Context )
expressionVisitor node direction context =
    case ( direction, context ) of
        ( Rule.OnEnter, ForbiddenToUseHtmlButton { hasImportedButtonInGlobalScope, htmlModules } ) ->
            case Node.value node of
                Expression.FunctionOrValue moduleName "button" ->
                    if moduleName == [] && hasImportedButtonInGlobalScope then
                        ( [ error node ], context )

                    else if List.member moduleName htmlModules then
                        ( [ error node ], context )

                    else
                        ( [], context )

                _ ->
                    ( [], context )

        _ ->
            ( [], context )


error : Node Expression -> Error
error node =
    Rule.error
        { message = "Use Ui.Button instead of the native Html.button"
        , details =
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
        }
        (Node.range node)
