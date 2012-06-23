[![Build Status](https://secure.travis-ci.org/pyromaniac/mongoid_orderable.png)](http://travis-ci.org/pyromaniac/mongoid_orderable)

# What?

Mongoid::Orderable is a ordered list implementation for your mongoid models.

# Why?

* It uses native mongo batch increment feature
* It supports assignable api
* It proper assingns position while moving document between scopes
* It supports both mongoid 2 and 3

# How?

```
gem 'mongoid_orderable'
```

Gem has the same api as others. Just include Mongoid::Orderable into your model and call `orderable` method.

```
class Item
  include Mongoid::Document
  include Mongoid::Orderable

  # belongs_to :group

  # orderable
  # orderable :scope => :group, :column => :pos
  # orderable :scope => lambda { |document| where(:group_id => document.group_id) }
  # orderable :index => false # this one if you want specify indexes manually
end
```

# Usage

```
item.move_to 2 # just change position
item.move_to! 2 # and save
item.move_to = 2 # assignable method

# symbol position
item.move_to :top
item.move_to :bottom
item.move_to :higher
item.move_to :lower

# generated methods
item.move_to_top
item.move_to_bottom
item.move_higher
item.move_lower
```

# Contributing

Fork && Patch && Spec && Push && Pull request.

# License

Mongoid::Orderable is released under the MIT license.