# elm-lint-example

This repository is a very contrived package project, aiming to show how [elm-lint](https://package.elm-lang.org/packages/jfmengels/elm-lint/latest/) and the [CLI](https://www.npmjs.com/package/@jfmengels/elm-lint) are used in a project, and showcase the output by actually running them in your terminal.

## Configuration

Configuration lies in the `lint/` directory. There is an `elm.json` containing the linting packages we wish to use. It also contains a `LintConfig.elm` file, in which we explicitly choose the rules we want to enable.

The imported rules come from the [lint-unused](https://package.elm-lang.org/packages/jfmengels/lint-unused/latest/) and [lint-debug](https://package.elm-lang.org/packages/jfmengels/lint-debug/latest/) packages in the Elm package registry.

## Custom rules

There are two custom rules in this project:
- [`NoDefiningColorsOutsideOfUiColor`](https://github.com/jfmengels/elm-lint-example/blob/master/lint/NoDefiningColorsOutsideOfUiColor.elm): This rule prevents defining colors (using `Css.hex`) outside of the `Ui.Color` module, which is the central location where we define colors in the application.
- [`NoUsingHtmlButton`](https://github.com/jfmengels/elm-lint-example/blob/master/lint/NoUsingHtmlButton.elm): This rule prevents users from using `Html.button` and `Html.Styled.button`, because we already have a great module to create buttons with the `Ui.Button`.

Both rules are found in the `lint/` directory. You can find their corresponding tests in `lint/tests/`.

## Running it

You can run the linting by running `npm run lint`, which will run `elm-lint src/ lint/`. This means it will run `elm-lint` on the `src/` and the `lint/` directories.

You can also run the fix mode by running `npm run lint:fix`, which will run in effect run `elm-lint src/ lint/ --fix`.

## In a CI environment

You can see what `elm-lint` looks like when run in a CI like Travis [here](https://travis-ci.com/jfmengels/elm-lint-example).
