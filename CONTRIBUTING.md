# Contributing

## Bikeshed 

The Open Screen Protocol spec is maintained with
[Bikeshed](https://tabatkins.github.io/bikeshed/), which has instructions for
installing the necessary tools on common platforms, and the document syntax
based on Markdown.

Things you can do:

* `make lint` checks the input document for errors.
* `make watch` runs in the background and regenerates `index.html` immediately
   after you modify `index.bs`.

## Using GitHub

Direct contributions to the spec should be made using the [Fork &
Pull](https://help.github.com/articles/using-pull-requests/#fork--pull)
model. The `openscreenprotocol` directory contains the spec source `index.bs`
and a `Makefile` to generate the spec.

1. Before doing any local changes, it is a good idea to ensure your fork is up-to-date with the upstream repository:
```bash
git fetch upstream
git merge upstream/gh-pages
```
1. In the `openscreenprotocol` directory, update the spec source `index.bs` with your changes.
1. Review your changes and commit them locally:
```bash
git diff
git add index.bs
git commit -m "Your commit message"
```
[Do **not** add `index.html`]
[How to write a Git commit message](http://chris.beams.io/posts/git-commit/)
1. Push your changes up to your GitHub fork, assuming `YOUR_FORK_NAME` is the name of your remote, and you are working off of the default `gh-pages` branch:
```bash
git push YOUR_FORK_NAME gh-pages
```
(Note: use the default `gh-pages` branch for minor changes only. For more significant changes, please create a new branch instead.)
1. On GitHub, navigate to your fork `https://github.com/YOUR_GITHUB_USERNAME/openscreenprotocol` and create a pull request with your changes.
1. Assuming there are no concerns from the group in a reasonable time, the editor will merge the changes to the upstream `webscreens/openscreenprotocol` repository, and the Editor's Draft hosted at https://webscreens.github.io/openscreenprotocol/ is automatically updated.
1. Pull requests sometimes contain work-in-progress commits such as "fix typos" or
"oops" commits, that do not need to be included in the Git history of the main
branch. By default, the editor will merge such pull requests with the Squash and
merge option provided by GitHub to create only one commit in the Git history.


