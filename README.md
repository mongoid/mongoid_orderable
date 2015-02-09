[![Build Status](https://secure.travis-ci.org/pyromaniac/mongoid_orderable.png)](http://travis-ci.org/pyromaniac/mongoid_orderable)

# What?

Mongoid::Orderable is a ordered list implementation for your mongoid models.

# Why?

* It uses native mongo batch increment feature
* It supports mutators api
* It correctly assigns the position while moving document between scopes
* It supports mongoid 2, 3 and 4
* It supports specifying multiple orderable columns

# How?

```ruby
gem 'mongoid_orderable'
```

Gem has the same api as others. Just include Mongoid::Orderable into your model and call `orderable` method.
Embedded objects are automatically scoped by their parent.

```ruby
class Item
  include Mongoid::Document
  include Mongoid::Orderable

  # belongs_to :group
  # belongs_to :drawer, class_name: "Office::Drawer",
  #            foreign_key: "legacy_drawer_key_id"

  # orderable
  # orderable scope: :group, column: :pos
  # orderable scope: :drawer, column: :pos # resolves scope foreign key from relation
  # orderable scope: 'drawer', column: :pos # but if you pass a string - it will use it as is, as the column name for scope
  # orderable scope: lambda { |document| where(group_id: document.group_id) }
  # orderable index: false # this one if you want specify indexes manually
  # orderable base: 0 # count position from zero as the top-most value (1 is the default value)
end
```

# Usage

```ruby
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

item.next_items # return a collection of items higher on the list
item.previous_items # return a collection of items lower on the list

item.next_item # returns the next item in the list
item.previous_item # returns the previous item in the list
```

# Multiple Columns

You can also define multiple orderable columns for any class including the Mongoid::Orderable module.

```ruby
class Book
  include Mongoid::Document
  include Mongoid::Orderable

  orderable base: 0
  orderable column: sno, as: :serial_no
end
```

The above defines two different orderable_columns on Book - *position* and *serial_no*.
The following helpers are generated in this case:

```ruby
item.move_#{column_name}_to 
item.move_#{column_name}_to=
item.move_#{column_name}_to!

item.move_#{column_name}_to_top
item.move_#{column_name}_to_bottom
item.move_#{column_name}_higher
item.move_#{column_name}_lower

item.next_#{column_name}_items
item.previous_#{column_name}_items

item.next_#{column_name}_item
item.previous_#{column_name}_item
```

*where column_name is either **position** or  **serial_no**.*

When a model defines multiple orderable columns, the original helpers are also available and work on the first orderable column.

```ruby
  @book1 = Book.create!
  @book2 = Book.create!
  @book2                 => #<Book _id: 53a16a2ba1bde4f746000001, serial_no: 1, position: 1>
  @book2.move_to! :top   # this will change the :position of the book to 0 (not serial_no)
  @book2                 => #<Book _id: 53a16a2ba1bde4f746000001, serial_no: 1, position: 0>
```

To specify any other orderable column as default pass the **default: true** option with orderable.

```ruby
  orderable column: sno, as: :serial_no, default: true
```

# Embedded documents
```ruby
class Question
  include Mongoid::Document
  include Mongoid::Orderable
  
  embedded_in :survey

  orderable
end
```
If you bulk import embedded documents without specifying their position, no field `position` will be written. 
```ruby
class Survey
  include Mongoid::Document
  
  embeds_many :questions, cascade_callbacks: true
end
```
To ensure the position is written correctly, you will need to provide the cascade callbacks option to the relation. 

# Contributing

Fork && Patch && Spec && Push && Pull request.

# License

Mongoid::Orderable is released under the MIT license.
