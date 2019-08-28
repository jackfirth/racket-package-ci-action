#!/usr/bin/env bash

set -euo pipefail

cd "$GITHUB_WORKSPACE"

# We install using --link to ensure that compiled bytecode and rendered docs are
# placed inside $GITHUB_WORKSPACE, and therefore persisted to other steps in a
# GitHub Actions workflow. Note however that all compilation artifacts for
# dependencies live inside the docker container's racket installation's
# directory, not $GITHUB_WORKSPACE, so those will be lost. It's unclear whether
# that's a problem or not. This persistence behavior is the main reason there is
# a single action that installs, builds, and tests a package, instead of
# separate actions for each of those steps.
if [ "$INPUT_DIRECTORY" -eq "." ]
then
  # As of August 2019, installing a linked package with source directory "."
  # raises an error for some bizarre reason, even when the package's name is
  # specified explicitly with --name. This is especially strange because source
  # directories like "./foo" work just fine.
  raco pkg install --name "$INPUT_NAME" --batch --auto --link
else
  raco pkg install --name "$INPUT_NAME" --batch --auto --link "$INPUT_DIRECTORY"
fi

# We use --drdr to get the same defaults as racket's other standard CI systems,
# including DrDr and the official package catalog build service. Beware that
# this causes stderr output to fail a test, which is not the default behavior of
# `raco test -p mypackage`. So you may see tests pass locally but fail in CI
# because they're printing to stderr and you're not counting that as a failure
# locally. In those cases, prefer counting the stderr output as a legitimate
# failure and switch to using `raco test --drdr` locally.
raco test --package --drdr "$INPUT_NAME"
