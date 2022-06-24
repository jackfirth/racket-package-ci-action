# racket-package-ci-action

A [GitHub Action][github-action] for building and testing [Racket][racket]
packages.

Consider using the [Bogdanp/setup-racket](https://github.com/Bogdanp/setup-racket)
action instead. It's far more flexible and essentially obsoletes this action.

## Action inputs

Only one input is required: `name`, for the name of the package. This is used
as the `--name` argument to `raco pkg install`. An optional input, `directory`,
can be used to specify where to look in your repository for the package's code.
It should be a relative path to a directory containing the `info.rkt` file for
the package. By default it is `.`, which is suitable for repositories that
contain only a single package with an `info.rkt` file at the root of the
repository.

## Build and test environment

Building and testing occurs in a Docker image with Minimal Racket installed.
Currently, packages are always built and tested using the latest released
version of Racket as determined by the [`racket/racket:latest`][racket-image]
Docker Hub image. If you need support for more versions of Racket or non-minimal
Racket, please reach out to me by opening an [issue][repo-issues] and telling me
more about your use case.

[github-action]: https://github.com/features/actions
[racket]: https://racket-lang.org/
[racket-image]: https://hub.docker.com/r/racket/racket
[repo-issues]: https://github.com/jackfirth/racket-package-ci-action/issues
