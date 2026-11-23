# Contributing to Mongoid Orderable

Fork the project on GitHub, create a topic branch, make your change with passing specs, add a line to [CHANGELOG.md](CHANGELOG.md), and open a pull request against `master`.

```sh
bundle install
bundle exec rake
```

The specs need a local MongoDB. `bundle exec rake` runs lint and specs on MRI Ruby 3.3 or newer and only specs on older Ruby versions. Run `bundle exec rake lint` to check Ruby, Markdown, YAML, and spelling, and add reviewed project vocabulary to `.spellcheck.txt`.

The Ruby 4.0 CI job measures all library files with SimpleCov and submits `coverage/.resultset.json` through the official Coveralls action using GitHub's automatic token. Other matrix jobs do not upload duplicate reports. Run `COVERAGE=true bundle install` and `COVERAGE=true bundle exec rake spec` to measure coverage locally. An accepted upstream default-branch build is required for the badge; this workflow alone does not activate the external service.
