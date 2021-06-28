[![Gem Version](https://badge.fury.io/rb/mongoid_orderable.svg)](https://badge.fury.io/rb/mongoid_orderable)
[![Build Status](https://travis-ci.org/mongoid/mongoid_orderable.svg?branch=master)](https://travis-ci.org/mongoid/mongoid_orderable)

# Mongoid Orderable

Mongoid::Orderable is a ordered list implementation for your Mongoid 7+ projects.

### Core Features

* Sets a position index field on your documents which allows you to sort them in order.
* Uses MongoDB's `$inc` operator to batch-update position.
* Supports scope for position index, including changing scopes.
* Supports multiple position indexes on the same document.
* (Optional) Uses [MongoDB transactions](https://docs.mongodb.com/manual/core/transactions/) to ensure order integrity during concurrent updates.

### Version Support

As of version 6.0.0, Mongoid::Orderable supports the following dependency versions:

* Ruby 2.6+
* Mongoid 7.0+
* Rails 5.2+

For older versions, please use Mongoid::Orderable 5.x and earlier.

Transaction support requires MongoDB 4.2+ (4.4+ recommended.)

## Usage

### Getting Started

```ruby
gem 'mongoid_orderable'
```

Include `Mongoid::Orderable` into your model and call `orderable` method.
Embedded objects are automatically scoped to their parent.

```ruby
class MyModel
  include Mongoid::Document
  include Mongoid::Orderable

  belongs_to :group
  belongs_to :drawer, class_name: "Office::Drawer",
             foreign_key: "legacy_drawer_key_id"

  orderable

  # if you set :scope as a symbol, it will resolve the foreign key from relation
  orderable scope: :drawer, field: :pos

  # if you set :scope as a string, it will use it as the field name for scope
  orderable scope: 'drawer', field: :pos

  # scope can also be a proc
  orderable scope: ->(doc) { where(group_id: doc.group_id) }

  # this one if you want specify indexes manually
  orderable index: false 

  # count position from zero as the top-most value (1 is the default value)
  orderable base: 0
end
```

You can also set default config values in an initializer, which will be
applied when calling the `orderable` macro in a model.

```ruby
# configs/initializers/mongoid_orderable.rb
Mongoid::Orderable.configure do |config|
  config.field = :pos
  config.base = 0
  config.index = false
end
```

### Moving Position

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

### Multiple Fields

You can also define multiple orderable fields for any class including the Mongoid::Orderable module.

```ruby
class Book
  include Mongoid::Document
  include Mongoid::Orderable

  orderable base: 0
  orderable field: sno, as: :serial_no
end
```

The above defines two different orderable_fields on Book - *position* and *serial_no*.
The following helpers are generated in this case:

```ruby
book.move_#{field}_to
book.move_#{field}_to=
book.move_#{field}_to!

book.move_#{field}_to_top
book.move_#{field}_to_bottom
book.move_#{field}_higher
book.move_#{field}_lower

book.next_#{field}_items
book.previous_#{field}_items

book.next_#{field}_item
book.previous_#{field}_item
```

where `#{field}` is either `position` or `serial_no`.

When a model defines multiple orderable fields, the original helpers are also available and work
on the first orderable field.

```ruby
  @book1 = Book.create!
  @book2 = Book.create!
  @book2                 # => <Book _id: 53a16a2ba1bde4f746000001, serial_no: 1, position: 1>
  @book2.move_to! :top   # this will change the :position of the book to 0 (not serial_no)
  @book2                 # => <Book _id: 53a16a2ba1bde4f746000001, serial_no: 1, position: 0>
```

To specify any other orderable field as default pass the **default: true** option with orderable.

```ruby
  orderable field: sno, as: :serial_no, default: true
```

### Embedded Documents

```ruby
class Question
  include Mongoid::Document
  include Mongoid::Orderable

  embedded_in :survey

  orderable
end
```

If you bulk import embedded documents without specifying their position,
no field `position` will be written.

```ruby
class Survey
  include Mongoid::Document

  embeds_many :questions, cascade_callbacks: true
end
```

To ensure the position is written correctly, you will need to set
`cascade_callbacks: true` on the relation.

### Disable Ordering

You can disable position tracking for specific documents using the `:if` and `:unless` options.
This is in advanced scenarios where you want to control position manually for certain documents.
In general, the disable condition should match a specific scope.
**Warning:** If used improperly, this will cause your documents to become out-of-order.

```ruby
class Book
  include Mongoid::Document
  include Mongoid::Orderable

  field :track_position, type: Boolean
  
  orderable if: :track_position, unless: -> { created_at < Date.parse('2020-01-01') }
end
```

## Transaction Support

By default, Mongoid Orderable does not guarantee ordering consistency
when doing multiple concurrent updates on documents. This means that
instead of having positions `1, 2, 3, 4, 5`, after running your system
in production at scale your position data will become corrupted, e.g.
`1, 1, 4, 4, 6`. To remedy this, this Mongoid Orderable can use
[MongoDB transactions](https://docs.mongodb.com/manual/core/transactions/)

### Prerequisites

* MongoDB version 4.2+ (4.4+ recommended.)
* Requires [MongoDB Replica Set](https://docs.mongodb.com/manual/tutorial/deploy-replica-set/) topology

### Configuration

You may enable transactions on both the global and model configs:

```ruby
Mongoid::Orderable.configure do |config|
  config.use_transactions = true       # default: false
  config.transaction_max_retries = 10  # default: 10
end

class MyModel
  orderable :position, use_transactions: false
end
```

When two transactions are attempted at the same time, database-level
`WriteConflict` failures may result and retries will be attempted.
After `transaction_max_retries` has been exceeded, a
`Mongoid::Orderable::Errors::TransactionFailed` error will be raised.

### Locks

When using transactions, Mongoid Orderable creates a collection
`mongoid_orderable_locks` which is used to store temporary lock objects.
Lock collections use a TTL index which auto-deletes objects older than 1 day.

You can change the lock collection name globally or per model:

```ruby
Mongoid::Orderable.configure do |config|
  config.lock_collection = "my_locks"  # default: "mongoid_orderable_locks"
end

class MyModel
  orderable :position, lock_collection: "my_model_locks"
end
```

### MongoDB 4.2 Support

In MongoDB 4.2, collections cannot be created within transactions.
Therefore, you will need to manually run the following command once
to initialize the lock collection:

```ruby
Mongoid::Orderable::Models::Lock.create!
```

This step is not necessary when using MongoDB 4.4+.

### Contributing

Please fork the project on Github and raise a pull request including passing specs.

### Copyright & License

Copyright (c) 2011 Arkadiy Zabazhanov, Johnny Shields, and contributors.

MIT license, see [LICENSE](LICENSE.txt) for details.
