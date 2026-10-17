# Upgrading

## 6.0.7

### Assigning embedded document positions

Assigning `child.position` and saving the child or its parent now reorders the embedded siblings, rather than writing a literal position that can leave duplicates. The relation must use `cascade_callbacks: true` when saving through the parent.

In the [README's Survey/Question example](README.md#embedded-documents), `survey` owns the embedded `questions` and each question includes `Mongoid::Orderable`:

```ruby
# Starting positions: [1, 2, 3]
question = survey.questions.last
question.position = 1
survey.save!

# Previously: [1, 2, 1]
# Now:        [2, 3, 1]
```

An out-of-range position is clamped to the list bounds; assigning `nil` moves an existing child to the bottom. Existing movement methods remain available. Code that intentionally manages literal positions should use the existing `:if` or `:unless` ordering conditions rather than relying on assignment to bypass ordering.
