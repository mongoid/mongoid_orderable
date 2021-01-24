require 'spec_helper'

describe Mongoid::Orderable do
  Mongoid::Orderable.configure do |c|
    c.use_transactions = true
    c.transaction_max_retries = 40
    c.lock_collection = :foo_bar_locks
  end

  class SimpleOrderable
    include Mongoid::Document
    include Mongoid::Orderable

    orderable
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

    embeds_many :embedded_orderables
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

  class Fruit
    include Mongoid::Document
    include Mongoid::Orderable

    orderable inherited: true
  end

  class Apple < Fruit
  end

  class Orange < Fruit
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

  describe SimpleOrderable do
    before :each do
      5.times { SimpleOrderable.create! }
    end

    def positions
      SimpleOrderable.pluck(:position).sort
    end

    it 'should have proper position field' do
      expect(SimpleOrderable.fields.key?('position')).to be true
      expect(SimpleOrderable.fields['position'].options[:type]).to eq(Integer)
    end

    it 'should have index on position field' do
      expect(SimpleOrderable.index_specifications.detect { |spec| spec.key == { position: 1 } }).not_to be_nil
    end

    it 'should have a orderable base of 1' do
      expect(SimpleOrderable.create!.orderable_top).to eq(1)
    end

    it 'should set proper position while creation' do
      expect(positions).to eq([1, 2, 3, 4, 5])
    end

    describe 'removement' do
      it 'top' do
        SimpleOrderable.where(position: 1).destroy
        expect(positions).to eq([1, 2, 3, 4])
      end

      it 'bottom' do
        SimpleOrderable.where(position: 5).destroy
        expect(positions).to eq([1, 2, 3, 4])
      end

      it 'middle' do
        SimpleOrderable.where(position: 3).destroy
        expect(positions).to eq([1, 2, 3, 4])
      end
    end

    describe 'inserting' do
      it 'top' do
        newbie = SimpleOrderable.create! move_to: :top
        expect(positions).to eq([1, 2, 3, 4, 5, 6])
        expect(newbie.position).to eq(1)
      end

      it 'bottom' do
        newbie = SimpleOrderable.create! move_to: :bottom
        expect(positions).to eq([1, 2, 3, 4, 5, 6])
        expect(newbie.position).to eq(6)
      end

      it 'middle' do
        newbie = SimpleOrderable.create! move_to: 4
        expect(positions).to eq([1, 2, 3, 4, 5, 6])
        expect(newbie.position).to eq(4)
      end

      it 'middle (with a numeric string)' do
        newbie = SimpleOrderable.create! move_to: '4'
        expect(positions).to eq([1, 2, 3, 4, 5, 6])
        expect(newbie.position).to eq(4)
      end

      it 'middle (with a non-numeric string)' do
        expect do
          SimpleOrderable.create! move_to: 'four'
        end.to raise_error Mongoid::Orderable::Errors::InvalidTargetPosition
      end

      it 'simultaneous create and update' do
        newbie = SimpleOrderable.new
        newbie.send(:orderable_update_positions) { }
        expect(newbie.position).to eq(6)
        another = SimpleOrderable.create!
        expect(another.position).to eq(6)
        newbie.save!
        expect(positions).to eq([1, 2, 3, 4, 5, 6, 7])
        expect(newbie.position).to eq(7)
        expect(another.position).to eq(6)
      end

      it 'parallel updates' do
        newbie = SimpleOrderable.new
        newbie.send(:orderable_update_positions) { }
        another = SimpleOrderable.create!
        newbie.save!
        expect(positions).to eq([1, 2, 3, 4, 5, 6, 7])
        expect(newbie.position).to eq(7)
        expect(another.position).to eq(6)
      end
    end

    describe 'movement' do
      it 'higher from top' do
        record = SimpleOrderable.where(position: 1).first
        record.update_attributes move_to: :higher
        expect(positions).to eq([1, 2, 3, 4, 5])
        expect(record.reload.position).to eq(1)
      end

      it 'higher from bottom' do
        record = SimpleOrderable.where(position: 5).first
        record.update_attributes move_to: :higher
        expect(positions).to eq([1, 2, 3, 4, 5])
        expect(record.reload.position).to eq(4)
      end

      it 'higher from middle' do
        record = SimpleOrderable.where(position: 3).first
        record.update_attributes move_to: :higher
        expect(positions).to eq([1, 2, 3, 4, 5])
        expect(record.reload.position).to eq(2)
      end

      it 'lower from top' do
        record = SimpleOrderable.where(position: 1).first
        record.update_attributes move_to: :lower
        expect(positions).to eq([1, 2, 3, 4, 5])
        expect(record.reload.position).to eq(2)
      end

      it 'lower from bottom' do
        record = SimpleOrderable.where(position: 5).first
        record.update_attributes move_to: :lower
        expect(positions).to eq([1, 2, 3, 4, 5])
        expect(record.reload.position).to eq(5)
      end

      it 'lower from middle' do
        record = SimpleOrderable.where(position: 3).first
        record.update_attributes move_to: :lower
        expect(positions).to eq([1, 2, 3, 4, 5])
        expect(record.reload.position).to eq(4)
      end

      it 'does nothing if position not change' do
        record = SimpleOrderable.where(position: 3).first
        record.save
        expect(positions).to eq([1, 2, 3, 4, 5])
        expect(record.reload.position).to eq(3)
      end
    end

    describe 'utility methods' do
      it 'should return a collection of items lower/higher on the list for next_items/previous_items' do
        record1 = SimpleOrderable.where(position: 1).first
        record2 = SimpleOrderable.where(position: 2).first
        record3 = SimpleOrderable.where(position: 3).first
        record4 = SimpleOrderable.where(position: 4).first
        record5 = SimpleOrderable.where(position: 5).first
        expect(record1.next_items.to_a).to eq([record2, record3, record4, record5])
        expect(record5.previous_items.to_a).to eq([record1, record2, record3, record4])
        expect(record3.previous_items.to_a).to eq([record1, record2])
        expect(record3.next_items.to_a).to eq([record4, record5])
        expect(record1.next_item).to eq(record2)
        expect(record2.previous_item).to eq(record1)
        expect(record1.previous_item).to eq(nil)
        expect(record5.next_item).to eq(nil)
      end
    end

    describe 'concurrency' do
      it 'should correctly move items to top' do
        20.times.map do
          Thread.new do
            record = SimpleOrderable.all.sample
            record.update_attributes move_to: :top
          end
        end.each(&:join)

        expect(SimpleOrderable.pluck(:position).sort).to eq([1, 2, 3, 4, 5])
      end

      it 'should correctly move items to bottom' do
        20.times.map do
          Thread.new do
            record = SimpleOrderable.all.sample
            record.update_attributes move_to: :bottom
          end
        end.each(&:join)

        expect(SimpleOrderable.pluck(:position).sort).to eq([1, 2, 3, 4, 5])
      end

      it 'should correctly move items higher' do
        20.times.map do
          Thread.new do
            record = SimpleOrderable.all.sample
            record.update_attributes move_to: :higher
          end
        end.each(&:join)

        expect(SimpleOrderable.pluck(:position).sort).to eq([1, 2, 3, 4, 5])
      end

      it 'should correctly move items lower' do
        20.times.map do
          Thread.new do
            record = SimpleOrderable.all.sample
            record.update_attributes move_to: :lower
          end
        end.each(&:join)

        expect(SimpleOrderable.pluck(:position).sort).to eq([1, 2, 3, 4, 5])
      end

      it 'should correctly insert at the top' do
        20.times.map do
          Thread.new do
            SimpleOrderable.create!(move_to: :top)
          end
        end.each(&:join)

        expect(SimpleOrderable.pluck(:position).sort).to eq((1..25).to_a)
      end

      it 'should correctly insert at the bottom' do
        20.times.map do
          Thread.new do
            SimpleOrderable.create!
          end
        end.each(&:join)

        expect(SimpleOrderable.pluck(:position).sort).to eq((1..25).to_a)
      end

      it 'should correctly insert at a random position' do
        20.times.map do
          Thread.new do
            SimpleOrderable.create!(move_to: (1..10).to_a.sample)
          end
        end.each(&:join)

        expect(SimpleOrderable.pluck(:position).sort).to eq((1..25).to_a)
      end

      it 'should correctly move items to a random position' do
        20.times.map do
          Thread.new do
            record = SimpleOrderable.all.sample
            record.update_attributes move_to: (1..5).to_a.sample
          end
        end.each(&:join)

        expect(SimpleOrderable.pluck(:position).sort).to eq([1, 2, 3, 4, 5])
      end

      context 'empty database' do
        before { SimpleOrderable.delete_all }

        it 'should correctly insert at the top' do
          20.times.map do
            Thread.new do
              SimpleOrderable.create!(move_to: :top)
            end
          end.each(&:join)

          expect(SimpleOrderable.pluck(:position).sort).to eq((1..20).to_a)
        end

        it 'should correctly insert at the bottom' do
          20.times.map do
            Thread.new do
              SimpleOrderable.create!
            end
          end.each(&:join)

          expect(SimpleOrderable.pluck(:position).sort).to eq((1..20).to_a)
        end

        it 'should correctly insert at a random position' do
          20.times.map do
            Thread.new do
              SimpleOrderable.create!(move_to: (1..10).to_a.sample)
            end
          end.each(&:join)

          expect(SimpleOrderable.pluck(:position).sort).to eq((1..20).to_a)
        end
      end
    end
  end

  describe ScopedOrderable do
    before :each do
      2.times { ScopedOrderable.create! group_id: 1 }
      3.times { ScopedOrderable.create! group_id: 2 }
    end

    def positions
      ScopedOrderable.order_by([:group_id, :asc], [:position, :asc]).map(&:position)
    end

    it 'should set proper position while creation' do
      expect(positions).to eq([1, 2, 1, 2, 3])
    end

    describe 'removement' do
      it 'top' do
        ScopedOrderable.where(position: 1, group_id: 1).destroy
        expect(positions).to eq([1, 1, 2, 3])
      end

      it 'bottom' do
        ScopedOrderable.where(position: 3, group_id: 2).destroy
        expect(positions).to eq([1, 2, 1, 2])
      end

      it 'middle' do
        ScopedOrderable.where(position: 2, group_id: 2).destroy
        expect(positions).to eq([1, 2, 1, 2])
      end
    end

    describe 'inserting' do
      it 'top' do
        newbie = ScopedOrderable.create! move_to: :top, group_id: 1
        expect(positions).to eq([1, 2, 3, 1, 2, 3])
        expect(newbie.position).to eq(1)
      end

      it 'bottom' do
        newbie = ScopedOrderable.create! move_to: :bottom, group_id: 2
        expect(positions).to eq([1, 2, 1, 2, 3, 4])
        expect(newbie.position).to eq(4)
      end

      it 'middle' do
        newbie = ScopedOrderable.create! move_to: 2, group_id: 2
        expect(positions).to eq([1, 2, 1, 2, 3, 4])
        expect(newbie.position).to eq(2)
      end

      it 'middle (with a numeric string)' do
        newbie = ScopedOrderable.create! move_to: '2', group_id: 2
        expect(positions).to eq([1, 2, 1, 2, 3, 4])
        expect(newbie.position).to eq(2)
      end

      it 'middle (with a non-numeric string)' do
        expect do
          ScopedOrderable.create! move_to: 'two', group_id: 2
        end.to raise_error Mongoid::Orderable::Errors::InvalidTargetPosition
      end
    end

    describe 'index' do
      it 'is not on position alone' do
        expect(ScopedOrderable.index_specifications.detect { |spec| spec.key == { position: 1 } }).to be_nil
      end

      it 'is on compound fields' do
        expect(ScopedOrderable.index_specifications.detect { |spec| spec.key == { group_id: 1, position: 1 } }).to_not be_nil
      end
    end

    describe 'scope movement' do
      let(:record) { ScopedOrderable.where(group_id: 2, position: 2).first }

      it 'to a new scope group' do
        record.update_attributes group_id: 3
        expect(positions).to eq([1, 2, 1, 2, 1])
        expect(record.position).to eq(1)
      end

      context 'when moving to an existing scope group' do
        it 'without a position' do
          record.update_attributes group_id: 1
          expect(positions).to eq([1, 2, 3, 1, 2])
          expect(record.reload.position).to eq(3)
        end

        it 'with symbol position' do
          record.update_attributes group_id: 1, move_to: :top
          expect(positions).to eq([1, 2, 3, 1, 2])
          expect(record.reload.position).to eq(1)
        end

        it 'with point position' do
          record.update_attributes group_id: 1, move_to: 2
          expect(positions).to eq([1, 2, 3, 1, 2])
          expect(record.reload.position).to eq(2)
        end

        it 'with point position (with a numeric string)' do
          record.update_attributes group_id: 1, move_to: '2'
          expect(positions).to eq([1, 2, 3, 1, 2])
          expect(record.reload.position).to eq(2)
        end

        it 'with point position (with a non-numeric string)' do
          expect do
            record.update_attributes group_id: 1, move_to: 'two'
          end.to raise_error Mongoid::Orderable::Errors::InvalidTargetPosition
        end
      end
    end

    describe 'utility methods' do
      it 'should return a collection of items lower/higher on the list for next_items/previous_items' do
        record1 = ScopedOrderable.where(group_id: 1, position: 1).first
        record2 = ScopedOrderable.where(group_id: 1, position: 2).first
        record3 = ScopedOrderable.where(group_id: 2, position: 1).first
        record4 = ScopedOrderable.where(group_id: 2, position: 2).first
        record5 = ScopedOrderable.where(group_id: 2, position: 3).first
        expect(record1.next_items.to_a).to eq([record2])
        expect(record5.previous_items.to_a).to eq([record3, record4])
        expect(record3.previous_items.to_a).to eq([])
        expect(record3.next_items.to_a).to eq([record4, record5])
        expect(record1.next_item).to eq(record2)
        expect(record2.previous_item).to eq(record1)
        expect(record1.previous_item).to eq(nil)
        expect(record2.next_item).to eq(nil)
      end
    end

    describe 'concurrency' do
      it 'should correctly move items to top' do
        20.times.map do
          Thread.new do
            record = ScopedOrderable.all.sample
            record.update_attributes move_to: :top
          end
        end.each(&:join)

        expect(ScopedOrderable.pluck(:position).sort).to eq([1, 1, 2, 2, 3])
      end

      it 'should correctly move items to bottom' do
        20.times.map do
          Thread.new do
            record = ScopedOrderable.all.sample
            record.update_attributes move_to: :bottom
          end
        end.each(&:join)

        expect(ScopedOrderable.pluck(:position).sort).to eq([1, 1, 2, 2, 3])
      end

      it 'should correctly move items higher' do
        20.times.map do
          Thread.new do
            record = ScopedOrderable.all.sample
            record.update_attributes move_to: :higher
          end
        end.each(&:join)

        expect(ScopedOrderable.pluck(:position).sort).to eq([1, 1, 2, 2, 3])
      end

      it 'should correctly move items lower' do
        20.times.map do
          Thread.new do
            record = ScopedOrderable.all.sample
            record.update_attributes move_to: :lower
          end
        end.each(&:join)

        expect(ScopedOrderable.pluck(:position).sort).to eq([1, 1, 2, 2, 3])
      end

      it 'should correctly move items to a random position' do
        20.times.map do
          Thread.new do
            record = ScopedOrderable.all.sample
            record.update_attributes move_to: (1..5).to_a.sample
          end
        end.each(&:join)

        expect(ScopedOrderable.pluck(:position).sort).to eq([1, 1, 2, 2, 3])
      end

      # This spec fails randomly
      it 'should correctly move items to a random scope', retry: 5 do
        20.times.map do
          Thread.new do
            record = ScopedOrderable.all.sample
            group_id = ([1, 2, 3] - [record.group_id]).sample
            record.update_attributes group_id: group_id
          end
        end.each(&:join)

        result = ScopedOrderable.all.to_a.each_with_object({}) do |obj, hash|
          hash[obj.group_id] ||= []
          hash[obj.group_id] << obj.position
        end

        result.values.each do |ary|
          expect(ary.sort).to eq((1..(ary.size)).to_a)
        end
      end

      it 'should correctly move items to a random position and scope' do
        20.times.map do
          Thread.new do
            record = ScopedOrderable.all.sample
            group_id = ([1, 2, 3] - [record.group_id]).sample
            position = (1..5).to_a.sample
            record.update_attributes group_id: group_id, move_to: position
          end
        end.each(&:join)

        result = ScopedOrderable.all.to_a.each_with_object({}) do |obj, hash|
          hash[obj.group_id] ||= []
          hash[obj.group_id] << obj.position
        end

        result.values.each do |ary|
          expect(ary.sort).to eq((1..(ary.size)).to_a)
        end
      end
    end
  end

  describe StringScopedOrderable do
    it 'uses the foreign key of the relationship as scope' do
      orderable1 = StringScopedOrderable.create!(some_scope: 1)
      orderable2 = StringScopedOrderable.create!(some_scope: 1)
      orderable3 = StringScopedOrderable.create!(some_scope: 2)
      expect(orderable1.position).to eq 1
      expect(orderable2.position).to eq 2
      expect(orderable3.position).to eq 1
    end
  end

  describe EmbeddedOrderable do
    before :each do
      eo = EmbedsOrderable.create!
      2.times { eo.embedded_orderables.create! }
      eo = EmbedsOrderable.create!
      3.times { eo.embedded_orderables.create! }
    end

    def positions
      EmbedsOrderable.order_by(position: 1).all.map { |eo| eo.embedded_orderables.map(&:position).sort }
    end

    it 'sets proper position while creation' do
      expect(positions).to eq([[1, 2], [1, 2, 3]])
    end

    it 'moves an item returned by a query to position' do
      embedded_orderable1 = EmbedsOrderable.first.embedded_orderables.where(position: 1).first
      embedded_orderable2 = EmbedsOrderable.first.embedded_orderables.where(position: 2).first
      embedded_orderable1.move_to! 2
      expect(embedded_orderable2.reload.position).to eq(1)
    end
  end

  describe CustomizedOrderable do
    it 'does not have default position field' do
      expect(CustomizedOrderable.fields).not_to have_key('position')
    end

    it 'should have custom pos field' do
      expect(CustomizedOrderable.fields).to have_key('pos')
    end

    it 'should have an alias my_position which points to pos field on Mongoid 3+' do
      if CustomizedOrderable.respond_to?(:database_field_name)
        expect(CustomizedOrderable.database_field_name('my_position')).to eq('pos')
      end
    end
  end

  describe NoIndexOrderable do
    it 'should not have index on position field' do
      expect(NoIndexOrderable.index_specifications.detect { |spec| spec.key == :position }).to be_nil
    end
  end

  describe ZeroBasedOrderable do
    before :each do
      5.times { ZeroBasedOrderable.create! }
    end

    def positions
      ZeroBasedOrderable.pluck(:position).sort
    end

    it 'should have a orderable base of 0' do
      expect(ZeroBasedOrderable.create!.orderable_top).to eq(0)
    end

    it 'should set proper position while creation' do
      expect(positions).to eq([0, 1, 2, 3, 4])
    end

    describe 'reset position' do
      before { ZeroBasedOrderable.update_all(position: nil) }
      it 'should properly reset position' do
        ZeroBasedOrderable.all.map(&:save)
        expect(positions).to eq([0, 1, 2, 3, 4])
      end
    end

    describe 'removement' do
      it 'top' do
        ZeroBasedOrderable.where(position: 0).destroy
        expect(positions).to eq([0, 1, 2, 3])
      end

      it 'bottom' do
        ZeroBasedOrderable.where(position: 4).destroy
        expect(positions).to eq([0, 1, 2, 3])
      end

      it 'middle' do
        ZeroBasedOrderable.where(position: 2).destroy
        expect(positions).to eq([0, 1, 2, 3])
      end
    end

    describe 'inserting' do
      it 'top' do
        newbie = ZeroBasedOrderable.create! move_to: :top
        expect(positions).to eq([0, 1, 2, 3, 4, 5])
        expect(newbie.position).to eq(0)
      end

      it 'bottom' do
        newbie = ZeroBasedOrderable.create! move_to: :bottom
        expect(positions).to eq([0, 1, 2, 3, 4, 5])
        expect(newbie.position).to eq(5)
      end

      it 'middle' do
        newbie = ZeroBasedOrderable.create! move_to: 3
        expect(positions).to eq([0, 1, 2, 3, 4, 5])
        expect(newbie.position).to eq(3)
      end

      it 'middle (with a numeric string)' do
        newbie = ZeroBasedOrderable.create! move_to: '3'
        expect(positions).to eq([0, 1, 2, 3, 4, 5])
        expect(newbie.position).to eq(3)
      end

      it 'middle (with a non-numeric string)' do
        expect do
          ZeroBasedOrderable.create! move_to: 'three'
        end.to raise_error Mongoid::Orderable::Errors::InvalidTargetPosition
      end
    end

    describe 'movement' do
      it 'higher from top' do
        record = ZeroBasedOrderable.where(position: 0).first
        record.update_attributes move_to: :higher
        expect(positions).to eq([0, 1, 2, 3, 4])
        expect(record.reload.position).to eq(0)
      end

      it 'higher from bottom' do
        record = ZeroBasedOrderable.where(position: 4).first
        record.update_attributes move_to: :higher
        expect(positions).to eq([0, 1, 2, 3, 4])
        expect(record.reload.position).to eq(3)
      end

      it 'higher from middle' do
        record = ZeroBasedOrderable.where(position: 3).first
        record.update_attributes move_to: :higher
        expect(positions).to eq([0, 1, 2, 3, 4])
        expect(record.reload.position).to eq(2)
      end

      it 'lower from top' do
        record = ZeroBasedOrderable.where(position: 0).first
        record.update_attributes move_to: :lower
        expect(positions).to eq([0, 1, 2, 3, 4])
        expect(record.reload.position).to eq(1)
      end

      it 'lower from bottom' do
        record = ZeroBasedOrderable.where(position: 4).first
        record.update_attributes move_to: :lower
        expect(positions).to eq([0, 1, 2, 3, 4])
        expect(record.reload.position).to eq(4)
      end

      it 'lower from middle' do
        record = ZeroBasedOrderable.where(position: 2).first
        record.update_attributes move_to: :lower
        expect(positions).to eq([0, 1, 2, 3, 4])
        expect(record.reload.position).to eq(3)
      end

      it 'does nothing if position not change' do
        record = ZeroBasedOrderable.where(position: 3).first
        record.save
        expect(positions).to eq([0, 1, 2, 3, 4])
        expect(record.reload.position).to eq(3)
      end
    end

    describe 'utility methods' do
      it 'should return a collection of items lower/higher on the list for next_items/previous_items' do
        record1 = ZeroBasedOrderable.where(position: 0).first
        record2 = ZeroBasedOrderable.where(position: 1).first
        record3 = ZeroBasedOrderable.where(position: 2).first
        record4 = ZeroBasedOrderable.where(position: 3).first
        record5 = ZeroBasedOrderable.where(position: 4).first
        expect(record1.next_items.to_a).to eq([record2, record3, record4, record5])
        expect(record5.previous_items.to_a).to eq([record1, record2, record3, record4])
        expect(record3.previous_items.to_a).to eq([record1, record2])
        expect(record3.next_items.to_a).to eq([record4, record5])
        expect(record1.next_item).to eq(record2)
        expect(record2.previous_item).to eq(record1)
        expect(record1.previous_item).to eq(nil)
        expect(record5.next_item).to eq(nil)
      end
    end
  end

  describe Fruit do
    it 'should set proper position' do
      fruit1 = Apple.create
      fruit2 = Orange.create
      expect(fruit1.position).to eq(1)
      expect(fruit2.position).to eq(2)
    end

    describe 'movement' do
      before :each do
        5.times { Apple.create! }
      end

      it 'with symbol position' do
        first_apple = Apple.asc(:_id).first
        top_pos = first_apple.position
        bottom_pos = Apple.asc(:_id).last.position
        expect do
          first_apple.move_to! :bottom
        end.to change(first_apple, :position).from(top_pos).to bottom_pos
      end

      it 'with point position' do
        first_apple = Apple.asc(:_id).first
        top_pos = first_apple.position
        bottom_pos = Apple.asc(:_id).last.position
        expect do
          first_apple.move_to! bottom_pos
        end.to change(first_apple, :position).from(top_pos).to bottom_pos
      end
    end

    describe 'add orderable configs in inherited class' do
      it 'does not affect the orderable configs of parent class and sibling class' do
        class Apple
          orderable field: :serial
        end
        expect(Fruit.orderable_configs).not_to eq Apple.orderable_configs
        expect(Orange.orderable_configs).not_to eq Apple.orderable_configs
        expect(Fruit.orderable_configs).to eq Orange.orderable_configs
      end
    end
  end

  describe ForeignKeyDiffersOrderable do
    it 'uses the foreign key of the relationship as scope' do
      orderable1, orderable2, orderable3 = nil
      parent_scope1 = ForeignKeyDiffersOrderable.create
      parent_scope2 = ForeignKeyDiffersOrderable.create
      expect do
        orderable1 = ForeignKeyDiffersOrderable.create!(different_scope: parent_scope1)
        orderable2 = ForeignKeyDiffersOrderable.create!(different_scope: parent_scope1)
        orderable3 = ForeignKeyDiffersOrderable.create!(different_scope: parent_scope2)
      end.to_not raise_error
      expect(orderable1.position).to eq 1
      expect(orderable2.position).to eq 2
      expect(orderable3.position).to eq 1
    end
  end

  describe MultipleFieldsOrderable do
    before :each do
      5.times { MultipleFieldsOrderable.create! }
    end

    context 'default orderable' do
      let(:serial_nos) { MultipleFieldsOrderable.pluck(:serial_no).sort }

      describe 'inserting' do
        let(:newbie) { MultipleFieldsOrderable.create! }

        before { @position = newbie.position }

        it 'top' do
          newbie.move_to! :top
          expect(serial_nos).to eq([1, 2, 3, 4, 5, 6])
          expect(newbie.serial_no).to eq(1)
          expect(newbie.position).to eq(@position)
        end

        it 'bottom' do
          newbie.move_to! :bottom
          expect(serial_nos).to eq([1, 2, 3, 4, 5, 6])
          expect(newbie.serial_no).to eq(6)
          expect(newbie.position).to eq(@position)
        end

        it 'middle' do
          newbie.move_to! 4
          expect(serial_nos).to eq([1, 2, 3, 4, 5, 6])
          expect(newbie.serial_no).to eq(4)
          expect(newbie.position).to eq(@position)
        end
      end

      describe 'movement' do
        it 'higher from top' do
          record = MultipleFieldsOrderable.where(serial_no: 1).first
          position = record.position
          record.move_higher!
          expect(serial_nos).to eq([1, 2, 3, 4, 5])
          expect(record.serial_no).to eq(1)
          expect(record.position).to eq(position)
        end

        it 'higher from bottom' do
          record = MultipleFieldsOrderable.where(serial_no: 5).first
          position = record.position
          record.move_higher!
          expect(serial_nos).to eq([1, 2, 3, 4, 5])
          expect(record.serial_no).to eq(4)
          expect(record.position).to eq(position)
        end

        it 'higher from middle' do
          record = MultipleFieldsOrderable.where(serial_no: 3).first
          position = record.position
          record.move_higher!
          expect(serial_nos).to eq([1, 2, 3, 4, 5])
          expect(record.serial_no).to eq(2)
          expect(record.position).to eq(position)
        end

        it 'lower from top' do
          record = MultipleFieldsOrderable.where(serial_no: 1).first
          position = record.position
          record.move_lower!
          expect(serial_nos).to eq([1, 2, 3, 4, 5])
          expect(record.serial_no).to eq(2)
          expect(record.position).to eq(position)
        end

        it 'lower from bottom' do
          record = MultipleFieldsOrderable.where(serial_no: 5).first
          position = record.position
          record.move_lower!
          expect(serial_nos).to eq([1, 2, 3, 4, 5])
          expect(record.serial_no).to eq(5)
          expect(record.position).to eq(position)
        end

        it 'lower from middle' do
          record = MultipleFieldsOrderable.where(serial_no: 3).first
          position = record.position
          record.move_lower!
          expect(serial_nos).to eq([1, 2, 3, 4, 5])
          expect(record.serial_no).to eq(4)
          expect(record.position).to eq(position)
        end
      end

      describe 'utility methods' do
        before do
          @record1 = MultipleFieldsOrderable.where(serial_no: 1).first
          @record2 = MultipleFieldsOrderable.where(serial_no: 2).first
          @record3 = MultipleFieldsOrderable.where(serial_no: 3).first
          @record4 = MultipleFieldsOrderable.where(serial_no: 4).first
          @record5 = MultipleFieldsOrderable.where(serial_no: 5).first
        end

        it 'should return the lower/higher item on the list for next_item/previous_item' do
          expect(@record1.next_item).to eq(@record2)
          expect(@record3.next_item).to eq(@record4)
          expect(@record5.next_item).to eq(nil)
          expect(@record1.prev_item).to eq(nil)
          expect(@record3.prev_item).to eq(@record2)
          expect(@record5.prev_item).to eq(@record4)
        end

        it 'should return a collection of items lower/higher on the list for next_items/previous_items' do
          expect(@record1.next_items.to_a).to eq([@record2, @record3, @record4, @record5])
          expect(@record3.next_items.to_a).to eq([@record4, @record5])
          expect(@record5.next_items.to_a).to eq([])
          expect(@record1.previous_items.to_a).to eq([])
          expect(@record3.previous_items.to_a).to eq([@record1, @record2])
          expect(@record5.previous_items.to_a).to eq([@record1, @record2, @record3, @record4])
        end
      end
    end

    context 'serial_no orderable' do
      let(:serial_nos) { MultipleFieldsOrderable.pluck(:serial_no).sort }

      it 'should have proper serial_no field' do
        expect(MultipleFieldsOrderable.fields.key?('serial_no')).to be true
        expect(MultipleFieldsOrderable.fields['serial_no'].options[:type]).to eq(Integer)
      end

      it 'should have index on serial_no field' do
        expect(MultipleFieldsOrderable.index_specifications.detect { |spec| spec.key == { serial_no: 1 } }).not_to be_nil
      end

      it 'should have a orderable base of 1' do
        expect(MultipleFieldsOrderable.first.orderable_top(:serial_no)).to eq(1)
      end

      it 'should set proper position while creation' do
        expect(serial_nos).to eq([1, 2, 3, 4, 5])
      end

      describe 'removement' do
        it 'top' do
          MultipleFieldsOrderable.where(serial_no: 1).destroy
          expect(serial_nos).to eq([1, 2, 3, 4])
        end

        it 'bottom' do
          MultipleFieldsOrderable.where(serial_no: 5).destroy
          expect(serial_nos).to eq([1, 2, 3, 4])
        end

        it 'middle' do
          MultipleFieldsOrderable.where(serial_no: 3).destroy
          expect(serial_nos).to eq([1, 2, 3, 4])
        end
      end

      describe 'inserting' do
        let(:newbie) { MultipleFieldsOrderable.create! }

        before { @position = newbie.position }

        it 'top' do
          newbie.move_serial_no_to! :top
          expect(serial_nos).to eq([1, 2, 3, 4, 5, 6])
          expect(newbie.serial_no).to eq(1)
          expect(newbie.position).to eq(@position)
        end

        it 'bottom' do
          newbie.move_serial_no_to! :bottom
          expect(serial_nos).to eq([1, 2, 3, 4, 5, 6])
          expect(newbie.serial_no).to eq(6)
          expect(newbie.position).to eq(@position)
        end

        it 'middle' do
          newbie.move_serial_no_to! 4
          expect(serial_nos).to eq([1, 2, 3, 4, 5, 6])
          expect(newbie.serial_no).to eq(4)
          expect(newbie.position).to eq(@position)
        end
      end

      describe 'movement' do
        it 'higher from top' do
          record = MultipleFieldsOrderable.where(serial_no: 1).first
          position = record.position
          record.move_serial_no_higher!
          expect(serial_nos).to eq([1, 2, 3, 4, 5])
          expect(record.serial_no).to eq(1)
          expect(record.position).to eq(position)
        end

        it 'higher from bottom' do
          record = MultipleFieldsOrderable.where(serial_no: 5).first
          position = record.position
          record.move_serial_no_higher!
          expect(serial_nos).to eq([1, 2, 3, 4, 5])
          expect(record.serial_no).to eq(4)
          expect(record.position).to eq(position)
        end

        it 'higher from middle' do
          record = MultipleFieldsOrderable.where(serial_no: 3).first
          position = record.position
          record.move_serial_no_higher!
          expect(serial_nos).to eq([1, 2, 3, 4, 5])
          expect(record.serial_no).to eq(2)
          expect(record.position).to eq(position)
        end

        it 'lower from top' do
          record = MultipleFieldsOrderable.where(serial_no: 1).first
          position = record.position
          record.move_serial_no_lower!
          expect(serial_nos).to eq([1, 2, 3, 4, 5])
          expect(record.serial_no).to eq(2)
          expect(record.position).to eq(position)
        end

        it 'lower from bottom' do
          record = MultipleFieldsOrderable.where(serial_no: 5).first
          position = record.position
          record.move_serial_no_lower!
          expect(serial_nos).to eq([1, 2, 3, 4, 5])
          expect(record.serial_no).to eq(5)
          expect(record.position).to eq(position)
        end

        it 'lower from middle' do
          record = MultipleFieldsOrderable.where(serial_no: 3).first
          position = record.position
          record.move_serial_no_lower!
          expect(serial_nos).to eq([1, 2, 3, 4, 5])
          expect(record.serial_no).to eq(4)
          expect(record.position).to eq(position)
        end
      end

      describe 'utility methods' do
        before do
          @record1 = MultipleFieldsOrderable.where(serial_no: 1).first
          @record2 = MultipleFieldsOrderable.where(serial_no: 2).first
          @record3 = MultipleFieldsOrderable.where(serial_no: 3).first
          @record4 = MultipleFieldsOrderable.where(serial_no: 4).first
          @record5 = MultipleFieldsOrderable.where(serial_no: 5).first
        end

        it 'should return the lower/higher item on the list for next_item/previous_item' do
          expect(@record1.next_serial_no_item).to eq(@record2)
          expect(@record3.next_serial_no_item).to eq(@record4)
          expect(@record5.next_serial_no_item).to eq(nil)
          expect(@record1.prev_serial_no_item).to eq(nil)
          expect(@record3.prev_serial_no_item).to eq(@record2)
          expect(@record5.prev_serial_no_item).to eq(@record4)
        end

        it 'should return a collection of items lower/higher on the list for next_items/previous_items' do
          expect(@record1.next_serial_no_items.to_a).to eq([@record2, @record3, @record4, @record5])
          expect(@record3.next_serial_no_items.to_a).to eq([@record4, @record5])
          expect(@record5.next_serial_no_items.to_a).to eq([])
          expect(@record1.previous_serial_no_items.to_a).to eq([])
          expect(@record3.previous_serial_no_items.to_a).to eq([@record1, @record2])
          expect(@record5.previous_serial_no_items.to_a).to eq([@record1, @record2, @record3, @record4])
        end
      end
    end

    context 'position orderable' do
      let(:positions) { MultipleFieldsOrderable.pluck(:position).sort }

      it 'should not have default position field' do
        expect(MultipleFieldsOrderable.fields).not_to have_key('position')
      end

      it 'should have custom pos field' do
        expect(MultipleFieldsOrderable.fields).to have_key('pos')
        expect(MultipleFieldsOrderable.fields['pos'].options[:type]).to eq(Integer)
      end

      it 'should have index on position field' do
        expect(MultipleFieldsOrderable.index_specifications.detect { |spec| spec.key == { position: 1 } }).to be_nil
      end

      it 'should have a orderable base of 0' do
        expect(MultipleFieldsOrderable.first.orderable_top(:position)).to eq(0)
      end

      it 'should set proper position while creation' do
        expect(positions).to eq([0, 1, 2, 3, 4])
      end

      describe 'removement' do
        it 'top' do
          MultipleFieldsOrderable.where(pos: 1).destroy
          expect(positions).to eq([0, 1, 2, 3])
        end

        it 'bottom' do
          MultipleFieldsOrderable.where(pos: 4).destroy
          expect(positions).to eq([0, 1, 2, 3])
        end

        it 'middle' do
          MultipleFieldsOrderable.where(pos: 3).destroy
          expect(positions).to eq([0, 1, 2, 3])
        end
      end

      describe 'inserting' do
        let(:newbie) { MultipleFieldsOrderable.create! }

        before { @serial_no = newbie.serial_no }

        it 'top' do
          newbie.move_position_to! :top
          expect(positions).to eq([0, 1, 2, 3, 4, 5])
          expect(newbie.position).to eq(0)
          expect(newbie.serial_no).to eq(@serial_no)
        end

        it 'bottom' do
          newbie.move_position_to! :bottom
          expect(positions).to eq([0, 1, 2, 3, 4, 5])
          expect(newbie.position).to eq(5)
          expect(newbie.serial_no).to eq(@serial_no)
        end

        it 'middle' do
          newbie.move_position_to! 4
          expect(positions).to eq([0, 1, 2, 3, 4, 5])
          expect(newbie.position).to eq(4)
          expect(newbie.serial_no).to eq(@serial_no)
        end
      end

      describe 'movement' do
        it 'higher from top' do
          record = MultipleFieldsOrderable.where(pos: 0).first
          position = record.serial_no
          record.move_position_higher!
          expect(positions).to eq([0, 1, 2, 3, 4])
          expect(record.position).to eq(0)
          expect(record.serial_no).to eq(position)
        end

        it 'higher from bottom' do
          record = MultipleFieldsOrderable.where(pos: 4).first
          position = record.serial_no
          record.move_position_higher!
          expect(positions).to eq([0, 1, 2, 3, 4])
          expect(record.position).to eq(3)
          expect(record.serial_no).to eq(position)
        end

        it 'higher from middle' do
          record = MultipleFieldsOrderable.where(pos: 3).first
          position = record.serial_no
          record.move_position_higher!
          expect(positions).to eq([0, 1, 2, 3, 4])
          expect(record.position).to eq(2)
          expect(record.serial_no).to eq(position)
        end

        it 'lower from top' do
          record = MultipleFieldsOrderable.where(pos: 0).first
          position = record.serial_no
          record.move_position_lower!
          expect(positions).to eq([0, 1, 2, 3, 4])
          expect(record.position).to eq(1)
          expect(record.serial_no).to eq(position)
        end

        it 'lower from bottom' do
          record = MultipleFieldsOrderable.where(pos: 4).first
          position = record.serial_no
          record.move_position_lower!
          expect(positions).to eq([0, 1, 2, 3, 4])
          expect(record.position).to eq(4)
          expect(record.serial_no).to eq(position)
        end

        it 'lower from middle' do
          record = MultipleFieldsOrderable.where(pos: 3).first
          position = record.serial_no
          record.move_position_lower!
          expect(positions).to eq([0, 1, 2, 3, 4])
          expect(record.position).to eq(4)
          expect(record.serial_no).to eq(position)
        end
      end

      describe 'utility methods' do
        before do
          @record1 = MultipleFieldsOrderable.where(pos: 0).first
          @record2 = MultipleFieldsOrderable.where(pos: 1).first
          @record3 = MultipleFieldsOrderable.where(pos: 2).first
          @record4 = MultipleFieldsOrderable.where(pos: 3).first
          @record5 = MultipleFieldsOrderable.where(pos: 4).first
        end

        it 'should return the lower/higher item on the list for next_item/previous_item' do
          expect(@record1.next_position_item).to eq(@record2)
          expect(@record3.next_position_item).to eq(@record4)
          expect(@record5.next_position_item).to eq(nil)
          expect(@record1.prev_position_item).to eq(nil)
          expect(@record3.prev_position_item).to eq(@record2)
          expect(@record5.prev_position_item).to eq(@record4)
        end

        it 'should return a collection of items lower/higher on the list for next_items/previous_items' do
          expect(@record1.next_position_items.to_a).to eq([@record2, @record3, @record4, @record5])
          expect(@record3.next_position_items.to_a).to eq([@record4, @record5])
          expect(@record5.next_position_items.to_a).to eq([])
          expect(@record1.previous_position_items.to_a).to eq([])
          expect(@record3.previous_position_items.to_a).to eq([@record1, @record2])
          expect(@record5.previous_position_items.to_a).to eq([@record1, @record2, @record3, @record4])
        end
      end
    end

    context 'group_count orderable' do
      before :each do
        MultipleFieldsOrderable.delete_all
        2.times { MultipleFieldsOrderable.create! group_id: 1 }
        3.times { MultipleFieldsOrderable.create! group_id: 2 }
      end

      let(:all_groups) { MultipleFieldsOrderable.order_by([:group_id, :asc], [:groups, :asc]).map(&:groups) }

      it 'should set proper position while creation' do
        expect(all_groups).to eq([1, 2, 1, 2, 3])
      end

      describe 'removement' do
        it 'top' do
          MultipleFieldsOrderable.where(groups: 1, group_id: 1).destroy
          expect(all_groups).to eq([1, 1, 2, 3])
        end

        it 'bottom' do
          MultipleFieldsOrderable.where(groups: 3, group_id: 2).destroy
          expect(all_groups).to eq([1, 2, 1, 2])
        end

        it 'middle' do
          MultipleFieldsOrderable.where(groups: 2, group_id: 2).destroy
          expect(all_groups).to eq([1, 2, 1, 2])
        end
      end

      describe 'inserting' do
        it 'top' do
          newbie = MultipleFieldsOrderable.create! group_id: 1
          newbie.move_groups_to! :top
          expect(all_groups).to eq([1, 2, 3, 1, 2, 3])
          expect(newbie.groups).to eq(1)
        end

        it 'bottom' do
          newbie = MultipleFieldsOrderable.create! group_id: 2
          newbie.move_groups_to! :bottom
          expect(all_groups).to eq([1, 2, 1, 2, 3, 4])
          expect(newbie.groups).to eq(4)
        end

        it 'middle' do
          newbie = MultipleFieldsOrderable.create! group_id: 2
          newbie.move_groups_to! 2
          expect(all_groups).to eq([1, 2, 1, 2, 3, 4])
          expect(newbie.groups).to eq(2)
        end
      end

      describe 'scope movement' do
        let(:record) { MultipleFieldsOrderable.where(group_id: 2, groups: 2).first }

        it 'to a new scope group' do
          record.update_attributes group_id: 3
          expect(all_groups).to eq([1, 2, 1, 2, 1])
          expect(record.groups).to eq(1)
        end

        context 'when moving to an existing scope group' do
          it 'without a position' do
            record.update_attributes group_id: 1
            expect(all_groups).to eq([1, 2, 3, 1, 2])
            expect(record.reload.groups).to eq(3)
          end

          it 'with symbol position' do
            record.update_attributes group_id: 1
            record.move_groups_to! :top
            expect(all_groups).to eq([1, 2, 3, 1, 2])
            expect(record.reload.groups).to eq(1)
          end

          it 'with point position' do
            record.update_attributes group_id: 1
            record.move_groups_to! 2
            expect(all_groups).to eq([1, 2, 3, 1, 2])
            expect(record.reload.groups).to eq(2)
          end
        end
      end

      describe 'utility methods' do
        before do
          @record1 = MultipleFieldsOrderable.where(group_id: 2, groups: 1).first
          @record2 = MultipleFieldsOrderable.where(group_id: 2, groups: 2).first
          @record3 = MultipleFieldsOrderable.where(group_id: 2, groups: 3).first
          @record4 = MultipleFieldsOrderable.where(group_id: 1, groups: 1).first
          @record5 = MultipleFieldsOrderable.where(group_id: 1, groups: 2).first
        end

        it 'should return the lower/higher item on the list for next_item/previous_item' do
          expect(@record1.next_groups_item).to eq(@record2)
          expect(@record4.next_groups_item).to eq(@record5)
          expect(@record3.next_groups_item).to eq(nil)
          expect(@record1.prev_groups_item).to eq(nil)
          expect(@record3.prev_groups_item).to eq(@record2)
          expect(@record5.prev_groups_item).to eq(@record4)
        end

        it 'should return a collection of items lower/higher on the list for next_items/previous_items' do
          expect(@record1.next_groups_items.to_a).to eq([@record2, @record3])
          expect(@record3.next_groups_items.to_a).to eq([])
          expect(@record4.next_groups_items.to_a).to eq([@record5])
          expect(@record1.previous_groups_items.to_a).to eq([])
          expect(@record3.previous_groups_items.to_a).to eq([@record1, @record2])
          expect(@record5.previous_groups_items.to_a).to eq([@record4])
        end
      end
    end
  end

  describe MultipleScopedOrderable do
    before :each do
      3.times do
        Apple.create
        Orange.create
      end
      MultipleScopedOrderable.create! apple_id: 1, orange_id: 1
      MultipleScopedOrderable.create! apple_id: 2, orange_id: 1
      MultipleScopedOrderable.create! apple_id: 2, orange_id: 2
      MultipleScopedOrderable.create! apple_id: 1, orange_id: 3
      MultipleScopedOrderable.create! apple_id: 1, orange_id: 1
      MultipleScopedOrderable.create! apple_id: 3, orange_id: 3
      MultipleScopedOrderable.create! apple_id: 2, orange_id: 3
      MultipleScopedOrderable.create! apple_id: 3, orange_id: 2
      MultipleScopedOrderable.create! apple_id: 1, orange_id: 3
    end

    def apple_positions
      MultipleScopedOrderable.order_by([:apple_id, :asc], [:posa, :asc]).map(&:posa)
    end

    def orange_positions
      MultipleScopedOrderable.order_by([:orange_id, :asc], [:poso, :asc]).map(&:poso)
    end

    describe 'default positions' do
      it { expect(apple_positions).to eq([1, 2, 3, 4, 1, 2, 3, 1, 2]) }
      it { expect(orange_positions).to eq([1, 2, 3, 1, 2, 1, 2, 3, 4]) }
    end

    describe 'change the scope of the apple' do
      let(:record) { MultipleScopedOrderable.first }
      before do
        record.update_attribute(:apple_id, 2)
      end

      it 'should properly set the apple positions' do
        expect(apple_positions).to eq([1, 2, 3, 1, 2, 3, 4, 1, 2])
      end

      it 'should not affect the orange positions' do
        expect(orange_positions).to eq([1, 2, 3, 1, 2, 1, 2, 3, 4])
      end
    end
  end
end
