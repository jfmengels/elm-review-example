module NoUsingHtmlButton exposing (rule)

import Elm.Syntax.Exposing as Exposing
import Elm.Syntax.Expression as Expression exposing (Expression)
import Elm.Syntax.Import exposing (Import)
import Elm.Syntax.Module as Module exposing (Module)
import Elm.Syntax.Node as Node exposing (Node(..))
import Review.Rule as Rule exposing (Direction, Error, Rule)


type alias Context =
    { hasImportedButtonInGlobalScope : Bool
    , htmlModules : List (List String)
    }


rule : Rule
rule =
    Rule.newModuleRuleSchema "NoUsingHtmlButton" initialContext
        |> Rule.withImportVisitor importVisitor
        |> Rule.withExpressionVisitor expressionVisitor
        |> Rule.fromModuleRuleSchema
        |> Rule.ignoreErrorsForFiles [ "src/Ui/Button.elm" ]


initialContext : Context
initialContext =
    { hasImportedButtonInGlobalScope = False
    , htmlModules =
        [ [ "Html" ]
        , [ "Html", "Styled" ]
        ]
    }


importVisitor : Node Import -> Context -> ( List (Error {}), Context )
importVisitor node context =
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
                , { context
                    | hasImportedButtonInGlobalScope = True
                    , htmlModules = List.concat [ importAlias (), context.htmlModules ]
                  }
                )

            Just (Exposing.Explicit importedElements) ->
                ( []
                , { context
                    | hasImportedButtonInGlobalScope = containsButton importedElements
                    , htmlModules = List.concat [ importAlias (), context.htmlModules ]
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


expressionVisitor : Node Expression -> Direction -> Context -> ( List (Error {}), Context )
expressionVisitor node direction context =
    case direction of
        Rule.OnEnter ->
            case Node.value node of
                Expression.FunctionOrValue moduleName "button" ->
                    if moduleName == [] && context.hasImportedButtonInGlobalScope then
                        ( [ error node ], context )

                    else if List.member moduleName context.htmlModules then
                        ( [ error node ], context )

                    else
                        ( [], context )

                _ ->
                    ( [], context )

        _ ->
            ( [], context )


error : Node Expression -> Error {}
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
