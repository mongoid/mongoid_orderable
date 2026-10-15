# Releasing

Release from a clean local checkout of the upstream repository, not a fork. You need repository push access, RubyGems ownership with MFA, and an authenticated GitHub CLI.

## Prepare

1. Run `git switch master` and `git pull --ff-only`. Confirm that `origin` points to `mongoid/mongoid_orderable`.
2. Choose the next semantic version and update `lib/mongoid/orderable/version.rb`. Date the corresponding changelog section and remove its contribution placeholder.
3. Run `bundle install`, then `bundle exec rake` against a MongoDB replica set so transaction examples run correctly. Set `MONGODB_HOST` if the replica set is not on `localhost:27017`; use `MONGOID_VERSION` to select a supported Mongoid version.
4. Commit the preparation, push `master`, and wait for the complete GitHub Actions test matrix and RuboCop workflow to pass for that commit.

## Publish

Run `bundle exec rake release`. This builds the package under `pkg/`, creates and pushes the version tag, and publishes to RubyGems. Enter a fresh RubyGems MFA code when prompted.

If RubyGems rejects the push for missing MFA after the tag was pushed, do not rerun the entire release task. Check the tag and RubyGems first, then publish the built package with `gem push pkg/mongoid_orderable-VERSION.gem --otp CODE`. Never move a published tag or republish an existing version.

Create a GitHub release from the same tag, using the matching changelog section as its release notes:

```sh
version=6.0.6 # Replace with the version being released.
gh release create "v$version" --repo mongoid/mongoid_orderable \
  --verify-tag --title "$version" --notes-file /path/to/release-notes.md --latest
```

Verify the exact version at `https://rubygems.org/gems/mongoid_orderable/versions/VERSION` and inspect `gh release view "v$version" --repo mongoid/mongoid_orderable` to confirm a published, non-draft release. If interrupted, resume only the missing publication step.

## Next development version

Increment the patch version in `lib/mongoid/orderable/version.rb`, add a new dated-as-`Next` changelog section with a contribution placeholder, and commit and push the changes to `master`.
