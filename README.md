# elm-lint-example

This repository is a very contrived package project, aiming to show how [elm-lint](https://package.elm-lang.org/packages/jfmengels/elm-lint/latest/) and the [CLI](https://www.npmjs.com/package/@jfmengels/elm-lint) are used in a project, and showcase the output by actually running them in your terminal.

## Configuration

Configuration lies in the `lint/` folder. There is an `elm.json` containing the linting packages we wish to use. It also contains a `LintConfig.elm` file, in which we explicitly choose the rules we want to enable.

The imported rules come from the [lint-unused](https://package.elm-lang.org/packages/jfmengels/lint-unused/latest/) and [lint-debug](https://package.elm-lang.org/packages/jfmengels/lint-debug/latest/) packages in the Elm package registry.

## Running it

You can run the linting by running `npm run lint`, which will run `elm-lint src/ lint/`. This means it will run `elm-lint` on the `src/` and the `lint/` directories.

You can also run the fix mode by running `npm run lint:fix`, which will run in effect run `elm-lint src/ lint/ --fix`.

## In a CI environment

You can see what `elm-lint` looks like when run in a CI like Travis [here](https://travis-ci.com/jfmengels/elm-lint-example).
