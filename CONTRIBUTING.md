# Contributing

- Contributions will not be accepted without tests.
- Please read and check Github issues and pending pull requests before submitting new code.
- If fixing a bug or adding a feature please post a new issue for discussion first.
- The active development branch is `version_0.6.0`. Please don't PR against `master`.
- Provide as much information and reproducability as possible when submitting an issue or pull request.

## Workflow
- Fork the project.
- `git checkout version_0.6.0`.
- `git checkout -b ` a topic branch for your fix/addition.
- Run `bundle`.
- Run `bundle exec rspec`.
- Test for the changes you intend to make.
- Make your changes.
- Run `bundle exec rspec`.
- Commit.
- Push to your fork and pull request.

You might want to rebase against the latest version of `version_0.6.0` if your changes take a long time to make.

Thanks for taking the time to contribute to Redcrumbs!
