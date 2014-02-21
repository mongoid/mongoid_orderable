module Mongoid::Orderable
  extend ActiveSupport::Concern

  module ClassMethods
    def orderable options = {}
      configuration = {
        :column => :position,
        :index => true,
        :scope => nil,
        :base => 1
      }

      configuration.merge! options if options.is_a?(Hash)
      configuration[:scope] = "#{configuration[:scope]}_id".to_sym if configuration[:scope].is_a?(Symbol) && configuration[:scope].to_s !~ /_id$/

      field configuration[:column], orderable_field_opts(configuration)
      if configuration[:index]
        if MongoidOrderable.mongoid2?
          index configuration[:column]
        else
          index(configuration[:column] => 1)
        end
      end

      case configuration[:scope]
      when Symbol then
        scope :orderable_scope, lambda { |document|
          where(configuration[:scope] => document.send(configuration[:scope])) }
      when Proc then
        scope :orderable_scope, configuration[:scope]
      else
        scope :orderable_scope, lambda { |document| where({}) }
      end

      define_method :orderable_column do
        configuration[:column]
      end

      define_method :orderable_base do
        configuration[:base]
      end

      self_class = self
      define_method :orderable_inherited_class do
        self_class if configuration[:inherited]
      end

      before_save :add_to_list
      after_destroy :remove_from_list
    end

    private

    def orderable_field_opts(configuration)
      field_opts = { :type => Integer }
      field_opts.merge!(configuration.slice(:as))
      field_opts
    end
  end

  ##
  # Returns items below the current document.
  # Items with a position greater than this document's position.
  def lower_items
    orderable_scoped.where(orderable_column.gt => self.position)
  end
  
  ##
  # Returns items above the current document.
  # Items with a position lower than this document's position.
  def higher_items
    orderable_scoped.where(orderable_column.lt => self.position)
  end

  # returns the previous item in the list
  def previous_item
    if higher_items.present?
      previous_position = self.position - 1
      begin
        orderable_scoped.find_by(position: previous_position)
      rescue
        orderable_scoped.where(position: previous_position).first
      end
    else
      nil
    end
  end

  # returns the next item in the list
  def next_item
    if lower_items.present?
      next_position = self.position + 1
      begin
        orderable_scoped.find_by(position: next_position)
      rescue
        orderable_scoped.where(position: next_position).first
      end
    else
      nil
    end
  end

  def move_to! target_position
    @move_to = target_position
    save
  end
  alias_method :insert_at!, :move_to!

  def move_to target_position
    @move_to = target_position
  end
  alias_method :insert_at, :move_to

  def move_to= target_position
    @move_to = target_position
  end
  alias_method :insert_at=, :move_to=

  [:top, :bottom].each do |symbol|
    define_method "move_to_#{symbol}" do
      move_to symbol
    end

    define_method "move_to_#{symbol}!" do
      move_to! symbol
    end
  end

  [:higher, :lower].each do |symbol|
    define_method "move_#{symbol}" do
      move_to symbol
    end

    define_method "move_#{symbol}!" do
      move_to! symbol
    end
  end

  def first?
    in_list? && orderable_position == orderable_base
  end

  def last?
    in_list? && orderable_position == bottom_orderable_position
  end

  def in_list?
    !orderable_position.nil?
  end

  def add_to_list
    apply_position @move_to
  end

  def remove_from_list
    MongoidOrderable.inc orderable_scoped.where(orderable_column.gt => orderable_position), orderable_column, -1
  end

private

  def orderable_position
    send orderable_column
  end

  def orderable_position= value
    send "#{orderable_column}=", value
  end

  def orderable_scoped
    if embedded?
      send(metadata.inverse).send(metadata.name).orderable_scope(self)
    else
      (orderable_inherited_class || self.class).orderable_scope(self)
    end
  end

  def orderable_scope_changed?
    if Mongoid.respond_to?(:unit_of_work)
      Mongoid.unit_of_work do
        orderable_scope_changed_query
      end
    else
      orderable_scope_changed_query
    end
  end

  def orderable_scope_changed_query
    !orderable_scoped.where(:_id => _id).exists?
  end

  def apply_position target_position
    if persisted? && !embedded? && orderable_scope_changed?
      self.class.unscoped.find(_id).remove_from_list
      self.orderable_position = nil
    end

    return if !target_position && in_list?

    target_position = target_position_to_position target_position

    unless in_list?
      MongoidOrderable.inc orderable_scoped.where(orderable_column.gte => target_position), orderable_column, 1
    else
      MongoidOrderable.inc(orderable_scoped.where(orderable_column.gte => target_position, orderable_column.lt => orderable_position), orderable_column, 1) if target_position < orderable_position
      MongoidOrderable.inc(orderable_scoped.where(orderable_column.gt => orderable_position, orderable_column.lte => target_position), orderable_column, -1) if target_position > orderable_position
    end

    self.orderable_position = target_position
  end

  def target_position_to_position target_position
    target_position = :bottom unless target_position

    target_position = case target_position.to_sym
      when :top then orderable_base
      when :bottom then bottom_orderable_position
      when :higher then orderable_position.pred
      when :lower then orderable_position.next
    end unless target_position.is_a? Numeric

    target_position = orderable_base if target_position < orderable_base
    target_position = bottom_orderable_position if target_position > bottom_orderable_position
    target_position
  end

  def bottom_orderable_position
    @bottom_orderable_position = begin
      positions_list = orderable_scoped.distinct(orderable_column)
      return orderable_base if positions_list.empty?
      max = positions_list.map(&:to_i).max.to_i
      in_list? ? max : max.next
    end
  end

end
