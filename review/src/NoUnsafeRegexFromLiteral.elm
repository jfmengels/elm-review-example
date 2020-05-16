module NoUnsafeRegexFromLiteral exposing (rule)

{-| Forbids misusing the unsafe function `Helpers.Regex.fromLiteral`.

@docs rule

-}

import Elm.Syntax.Declaration as Declaration exposing (Declaration)
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
    Rule.newProjectRuleSchema "NoUnsafeRegexFromLiteral" initialProjectContext
        |> Scope.addProjectVisitors
        |> Rule.withElmJsonProjectVisitor elmJsonVisitor
        |> Rule.withModuleVisitor moduleVisitor
        |> Rule.withModuleContext
            { fromProjectToModule = fromProjectToModule
            , fromModuleToProject = fromModuleToProject
            , foldProjectContexts = foldProjectContexts
            }
        |> Rule.withFinalProjectEvaluation finalProjectEvaluation
        |> Rule.fromProjectRuleSchema


moduleVisitor : Rule.ModuleRuleSchema {} ModuleContext -> Rule.ModuleRuleSchema { hasAtLeastOneVisitor : () } ModuleContext
moduleVisitor schema =
    schema
        |> Rule.withDeclarationListVisitor declarationListVisitor
        |> Rule.withExpressionVisitor expressionVisitor


targetModuleName : List String
targetModuleName =
    [ "Helpers", "Regex" ]


targetFunctionName : String
targetFunctionName =
    "fromLiteral"


type alias ProjectContext =
    { scope : Scope.ProjectContext
    , elmJsonKey : Maybe Rule.ElmJsonKey
    , foundTargetFunction : Bool
    }


type alias ModuleContext =
    { scope : Scope.ModuleContext
    , allowedFunctionOrValues : List Range
    , foundTargetFunction : Bool
    }


initialProjectContext : ProjectContext
initialProjectContext =
    { scope = Scope.initialProjectContext
    , elmJsonKey = Nothing
    , foundTargetFunction = False
    }


fromProjectToModule : Rule.ModuleKey -> Node ModuleName -> ProjectContext -> ModuleContext
fromProjectToModule _ _ projectContext =
    { scope = Scope.fromProjectToModule projectContext.scope
    , allowedFunctionOrValues = []
    , foundTargetFunction = False
    }


fromModuleToProject : Rule.ModuleKey -> Node ModuleName -> ModuleContext -> ProjectContext
fromModuleToProject _ moduleNameNode moduleContext =
    { scope = Scope.fromModuleToProject moduleNameNode moduleContext.scope
    , elmJsonKey = Nothing
    , foundTargetFunction = moduleContext.foundTargetFunction && (Node.value moduleNameNode == targetModuleName)
    }


foldProjectContexts : ProjectContext -> ProjectContext -> ProjectContext
foldProjectContexts newContext previousContext =
    { scope = Scope.foldProjectContexts newContext.scope previousContext.scope
    , elmJsonKey = previousContext.elmJsonKey
    , foundTargetFunction = previousContext.foundTargetFunction || newContext.foundTargetFunction
    }


elmJsonVisitor : Maybe { a | elmJsonKey : Rule.ElmJsonKey } -> ProjectContext -> ( List nothing, ProjectContext )
elmJsonVisitor elmJson projectContext =
    ( [], { projectContext | elmJsonKey = Maybe.map .elmJsonKey elmJson } )


finalProjectEvaluation : ProjectContext -> List (Error scope)
finalProjectEvaluation projectContext =
    if projectContext.foundTargetFunction then
        []

    else
        case projectContext.elmJsonKey of
            Just elmJsonKey ->
                [ Rule.errorForElmJson
                    elmJsonKey
                    (\_ ->
                        { message = "Could not find Helpers.Regex.fromLiteral."
                        , details =
                            [ "I want to provide guarantees on the use of this function, but I can't find it. It is likely that it was renamed, which prevents me from giving you these guarantees."
                            , "You should rename it back or update this rule to the new name. If you do not use the function anymore, remove the rule."
                            ]
                        , range =
                            { start = { row = 1, column = 1 }
                            , end = { row = 1, column = 2 }
                            }
                        }
                    )
                ]

            Nothing ->
                []


declarationListVisitor : List (Node Declaration) -> ModuleContext -> ( List nothing, ModuleContext )
declarationListVisitor nodes moduleContext =
    let
        foundTargetFunction : Bool
        foundTargetFunction =
            List.any
                (\node ->
                    case Node.value node of
                        Declaration.FunctionDeclaration function ->
                            targetFunctionName
                                == (function.declaration
                                        |> Node.value
                                        |> .name
                                        |> Node.value
                                   )

                        _ ->
                            False
                )
                nodes
    in
    ( [], { moduleContext | foundTargetFunction = foundTargetFunction } )


isTargetFunction : ModuleContext -> ModuleName -> String -> Bool
isTargetFunction moduleContext moduleName functionName =
    (functionName == targetFunctionName)
        && (Scope.moduleNameForValue moduleContext.scope targetFunctionName moduleName == targetModuleName)


expressionVisitor : Node Expression -> Rule.Direction -> ModuleContext -> ( List (Error {}), ModuleContext )
expressionVisitor node direction moduleContext =
    case ( direction, Node.value node ) of
        ( Rule.OnEnter, Expression.Application (function :: argument :: []) ) ->
            case Node.value function of
                Expression.FunctionOrValue moduleName functionName ->
                    if isTargetFunction moduleContext moduleName functionName then
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
                                        [ Rule.error nonStaticValue (Node.range node) ]
                        in
                        ( errors
                        , { moduleContext | allowedFunctionOrValues = Node.range function :: moduleContext.allowedFunctionOrValues }
                        )

                    else
                        ( [], moduleContext )

                _ ->
                    ( [], moduleContext )

        ( Rule.OnEnter, Expression.FunctionOrValue moduleName functionName ) ->
            if
                isTargetFunction moduleContext moduleName functionName
                    && not (List.member (Node.range node) moduleContext.allowedFunctionOrValues)
            then
                ( [ Rule.error notUsedAsFunction (Node.range node) ]
                , moduleContext
                )

            else
                ( [], moduleContext )

        _ ->
            ( [], moduleContext )


invalidRegex : { message : String, details : List String }
invalidRegex =
    { message = "Helpers.Regex.fromLiteral needs to be called with a valid regex."
    , details =
        [ "This function serves to give you more guarantees about creating regular expressions, but if the argument is dynamic or too complex, I won't be able to tell you."
        ]
    }


nonStaticValue : { message : String, details : List String }
nonStaticValue =
    { message = "Helpers.Regex.fromLiteral needs to be called with a static string literal."
    , details =
        [ "This function serves to give you more guarantees about creating regular expressions, but if the argument is dynamic or too complex, I won't be able to tell you."
        , "Either make the argument static or use Regex.fromString instead."
        ]
    }


notUsedAsFunction : { message : String, details : List String }
notUsedAsFunction =
    { message = "Helpers.Regex.fromLiteral must be called directly."
    , details =
        [ "This function serves to give you more guarantees about creating regular expressions, but I can't determine how it is used if you do something else than calling it directly."
        ]
    }
