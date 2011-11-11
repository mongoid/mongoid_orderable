# What?

Mongoid::Orderable is a ordered list implementation for your mongoid models.

# Why?

* It uses native mongo batch increment feature
* It supports assignable api
* It proper assingns position while moving document between scopes

# How?

```
gem 'mongoid_orderable'
```

Gem has the same api as others. Just include Mongoid::Orderable into your model.
Also you can initialize orderable manually and specify `:scope` or `:column` options:

```
class Item
  include Mongoid::Document
  include Mongoid::Orderable

  # belongs_to :group

  # orderable :scope => :group, :column => :pos
  # orderable :scope => lambda { |document| where(:group_id => document.group_id) }
end
```

# Contributing

Fork && Patch && Spec && Push && Pull request.

# License

Mongoid::Orderable is released under the MIT license.