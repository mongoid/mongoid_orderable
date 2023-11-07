

Mongoid::Orderable.configure do |c|
  c.use_transactions = true
  c.transaction_max_retries = 100
  c.lock_collection = :foo_bar_locks
end

class SimpleOrderable
  include Mongoid::Document
  include Mongoid::Orderable

  orderable
end

class ConditionalOrderable
  include Mongoid::Document
  include Mongoid::Orderable

  field :cond_a, type: Boolean
  field :cond_b, type: Integer

  orderable field: :pos_a, if: :cond_a, unless: ->(obj) { obj.cond_b&.<(2) }
  orderable field: :pos_b, if: -> { cond_b&.<=(4) }
  orderable field: :pos_c, unless: false
end

class ScopedGroup
  include Mongoid::Document

  has_many :scoped_orderables
  has_many :multiple_fields_orderables
end

class ScopedOrderable
  include Mongoid::Document
  include Mongoid::Orderable

  belongs_to :group, class_name: 'ScopedGroup', optional: true

  orderable scope: :group
end

class StringScopedOrderable
  include Mongoid::Document
  include Mongoid::Orderable

  field :some_scope, type: Integer

  orderable scope: 'some_scope'
end

class EmbedsOrderable
  include Mongoid::Document

  embeds_many :embedded_orderables, cascade_callbacks: true
end

class EmbeddedOrderable
  include Mongoid::Document
  include Mongoid::Orderable

  embedded_in :embeds_orderable

  orderable
end

class CustomizedOrderable
  include Mongoid::Document
  include Mongoid::Orderable

  orderable field: :pos, as: :my_position
end

class NoIndexOrderable
  include Mongoid::Document
  include Mongoid::Orderable

  orderable index: false
end

class ZeroBasedOrderable
  include Mongoid::Document
  include Mongoid::Orderable

  orderable base: 0
end

class InheritedOrderable
  include Mongoid::Document
  include Mongoid::Orderable

  orderable inherited: true
end

class Apple < InheritedOrderable
  orderable field: :serial
end

class Orange < InheritedOrderable
end

class ForeignKeyDiffersOrderable
  include Mongoid::Document
  include Mongoid::Orderable

  belongs_to :different_scope, class_name: 'ForeignKeyDiffersOrderable',
             foreign_key: 'different_orderable_id',
             optional: true

  orderable scope: :different_scope
end

class MultipleFieldsOrderable
  include Mongoid::Document
  include Mongoid::Orderable

  belongs_to :group, class_name: 'ScopedGroup', optional: true

  orderable field: :pos, base: 0, index: false, as: :position
  orderable field: :serial_no, default: true
  orderable field: :groups, scope: :group
end

class MultipleScopedOrderable
  include Mongoid::Document
  include Mongoid::Orderable

  belongs_to :apple, optional: true
  belongs_to :orange, optional: true

  orderable field: :posa, scope: :apple_id
  orderable field: :poso, scope: :orange_id
end
