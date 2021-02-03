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
if [ "$INPUT_DIRECTORY" == "." ]; then
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

# This part of the script, which publishes the scribble docs to Github pages,
# is adapted from Alexis King’s original scripts for Travis CI. Unfortunately,
# we cannot infer very much from the package structure so we rely on the
# the user to set the paths.
if [ -n "$INPUT_DOC_DIRECTORY" ] && [ -n "$INPUT_SCRIBBLE_FILE" ] \
       && [ -n "$INPUT_MAIN_REF" ] && [ -n "$INPUT_GITHUB_TOKEN" ]; then
    if [[ -z "$GITHUB_BASE_REF" ]] && [ "$INPUT_MAIN_REF" == "$GITHUB_REF" ]; then
        echo "Uploading documentation under ${INPUT_DOC_DIRECTORY}..."
	ls -alt
	raco scribble +m --htmls \
	     --redirect-main http://pkg-build.racket-lang.org/doc/ \
	     --dest ./docs \
	     "${INPUT_DOC_DIRECTORY}/scribblings/${INPUT_SCRIBBLE_FILE}.scribl"
	# Here we create a /new/ repository with no history where the scribble docs are generated.
	cd docs || exit 1
	# Sometimes the scribble command will create a subfolder, but Github doesn't like it.
	# This is a noop in the case that there isn't one.
	cd $(find . -maxdepth 1 -type d | tail -n1) || exit 1
        git config --global user.email $(git show -s --format=format:%ae) 
        git config --global user.name $(git show -s --format=formmat:%an)
	git init
	git add .
	git commit -m 'Deploy to Github Pages'
	# Rarely do we want to actually save the history of the Github Pages — force pushing wipes the history.
	git push --force  \
	    "https://${GITHUB_ACTOR}:${INPUT_GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git" \
	    master:gh-pages
    fi
fi
