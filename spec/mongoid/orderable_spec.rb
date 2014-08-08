require 'spec_helper'

describe Mongoid::Orderable do

  class SimpleOrderable
    include Mongoid::Document
    include Mongoid::Orderable

    orderable
  end

  class ScopedGroup
    include Mongoid::Document

    has_many :scoped_orderables
    has_many :multiple_columns_orderables
  end

  class ScopedOrderable
    include Mongoid::Document
    include Mongoid::Orderable

    field :group_id
    belongs_to :scoped_group

    orderable :scope => :group
  end

  class StringScopedOrderable
    include Mongoid::Document
    include Mongoid::Orderable

    field :some_scope, :type => Integer

    orderable :scope => 'some_scope'
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

    orderable :column => :pos, :as => :my_position
  end

  class NoIndexOrderable
    include Mongoid::Document
    include Mongoid::Orderable

    orderable :index => false
  end

  class ZeroBasedOrderable
    include Mongoid::Document
    include Mongoid::Orderable

    orderable :base => 0
  end

  class Fruit
    include Mongoid::Document
    include Mongoid::Orderable

    orderable :inherited => true
  end

  class Apple < Fruit
  end

  class Orange < Fruit
  end

  class ForeignKeyDiffersOrderable
    include Mongoid::Document
    include Mongoid::Orderable

    belongs_to  :different_scope, :class_name => "ForeignKeyDiffersOrderable",
                :foreign_key => "different_orderable_id"

    orderable :scope => :different_scope
  end

  class MultipleColumnsOrderable
    include Mongoid::Document
    include Mongoid::Orderable

    field :group_id

    belongs_to :scoped_group

    orderable :column => :pos, :base => 0, :index => false, :as => :position
    orderable :column => :serial_no, :default => true
    orderable :column => :groups, :scope => :group
  end

  describe SimpleOrderable do

    before :each do
      SimpleOrderable.delete_all
      5.times do
        SimpleOrderable.create!
      end
    end

    def positions
      SimpleOrderable.all.map(&:position).sort
    end

    it 'should have proper position column' do
      SimpleOrderable.fields.key?('position').should be true
      SimpleOrderable.fields['position'].options[:type].should == Integer
    end

    it 'should have index on position column' do
      if MongoidOrderable.mongoid2?
        SimpleOrderable.index_options[:position].should_not be_nil
      elsif MongoidOrderable.mongoid3?
        SimpleOrderable.index_options[{:position => 1}].should_not be_nil
      else
        SimpleOrderable.index_specifications.detect { |spec| spec.key == {:position => 1} }.should_not be_nil
      end
    end

    it 'should have a orderable base of 1' do
      SimpleOrderable.create!.orderable_base.should == 1
    end

    it 'should set proper position while creation' do
      positions.should == [1, 2, 3, 4, 5]
    end

    describe 'removement' do

      it 'top' do
        SimpleOrderable.where(:position => 1).destroy
        positions.should == [1, 2, 3, 4]
      end

      it 'bottom' do
        SimpleOrderable.where(:position => 5).destroy
        positions.should == [1, 2, 3, 4]
      end

      it 'middle' do
        SimpleOrderable.where(:position => 3).destroy
        positions.should == [1, 2, 3, 4]
      end
    end

    describe 'inserting' do

      it 'top' do
        newbie = SimpleOrderable.create! :move_to => :top
        positions.should == [1, 2, 3, 4, 5, 6]
        newbie.position.should == 1
      end

      it 'bottom' do
        newbie = SimpleOrderable.create! :move_to => :bottom
        positions.should == [1, 2, 3, 4, 5, 6]
        newbie.position.should == 6
      end

      it 'middle' do
        newbie = SimpleOrderable.create! :move_to => 4
        positions.should == [1, 2, 3, 4, 5, 6]
        newbie.position.should == 4
      end

      it 'middle (with a numeric string)' do
        newbie = SimpleOrderable.create! :move_to => '4'
        positions.should == [1, 2, 3, 4, 5, 6]
        newbie.position.should == 4
      end

      it 'middle (with a non-numeric string)' do
        expect do
          SimpleOrderable.create! :move_to => 'four'
        end.to raise_error Mongoid::Orderable::Errors::InvalidTargetPosition
      end
    end

    describe 'movement' do

      it 'higher from top' do
        record = SimpleOrderable.where(:position => 1).first
        record.update_attributes :move_to => :higher
        positions.should == [1, 2, 3, 4, 5]
        record.reload.position.should == 1
      end

      it 'higher from bottom' do
        record = SimpleOrderable.where(:position => 5).first
        record.update_attributes :move_to => :higher
        positions.should == [1, 2, 3, 4, 5]
        record.reload.position.should == 4
      end

      it 'higher from middle' do
        record = SimpleOrderable.where(:position => 3).first
        record.update_attributes :move_to => :higher
        positions.should == [1, 2, 3, 4, 5]
        record.reload.position.should == 2
      end

      it 'lower from top' do
        record = SimpleOrderable.where(:position => 1).first
        record.update_attributes :move_to => :lower
        positions.should == [1, 2, 3, 4, 5]
        record.reload.position.should == 2
      end

      it 'lower from bottom' do
        record = SimpleOrderable.where(:position => 5).first
        record.update_attributes :move_to => :lower
        positions.should == [1, 2, 3, 4, 5]
        record.reload.position.should == 5
      end

      it 'lower from middle' do
        record = SimpleOrderable.where(:position => 3).first
        record.update_attributes :move_to => :lower
        positions.should == [1, 2, 3, 4, 5]
        record.reload.position.should == 4
      end

      it 'does nothing if position not change' do
        record = SimpleOrderable.where(:position => 3).first
        record.save
        positions.should == [1, 2, 3, 4, 5]
        record.reload.position.should == 3
      end
    end

    describe 'utiity methods' do

      it "should return a collection of items lower/higher on the list for next_items/previous_items" do
        record_1 = SimpleOrderable.where(:position => 1).first
        record_2 = SimpleOrderable.where(:position => 2).first
        record_3 = SimpleOrderable.where(:position => 3).first
        record_4 = SimpleOrderable.where(:position => 4).first
        record_5 = SimpleOrderable.where(:position => 5).first
        expect(record_1.next_items.to_a).to eq([record_2, record_3, record_4, record_5])
        expect(record_5.previous_items.to_a).to eq([record_1, record_2, record_3, record_4])
        expect(record_3.previous_items.to_a).to eq([record_1, record_2])
        expect(record_3.next_items.to_a).to eq([record_4, record_5])
      end
    end
  end

  describe ScopedOrderable do

    before :each do
      ScopedOrderable.delete_all
      2.times do
        ScopedOrderable.create! :group_id => 1
      end
      3.times do
        ScopedOrderable.create! :group_id => 2
      end
    end

    def positions
      ScopedOrderable.order_by([:group_id, :asc], [:position, :asc]).map(&:position)
    end

    it 'should set proper position while creation' do
      positions.should == [1, 2, 1, 2, 3]
    end

    describe 'removement' do

      it 'top' do
        ScopedOrderable.where(:position => 1, :group_id => 1).destroy
        positions.should == [1, 1, 2, 3]
      end

      it 'bottom' do
        ScopedOrderable.where(:position => 3, :group_id => 2).destroy
        positions.should == [1, 2, 1, 2]
      end

      it 'middle' do
        ScopedOrderable.where(:position => 2, :group_id => 2).destroy
        positions.should == [1, 2, 1, 2]
      end
    end

    describe 'inserting' do

      it 'top' do
        newbie = ScopedOrderable.create! :move_to => :top, :group_id => 1
        positions.should == [1, 2, 3, 1, 2, 3]
        newbie.position.should == 1
      end

      it 'bottom' do
        newbie = ScopedOrderable.create! :move_to => :bottom, :group_id => 2
        positions.should == [1, 2, 1, 2, 3, 4]
        newbie.position.should == 4
      end

      it 'middle' do
        newbie = ScopedOrderable.create! :move_to => 2, :group_id => 2
        positions.should == [1, 2, 1, 2, 3, 4]
        newbie.position.should == 2
      end

      it 'middle (with a numeric string)' do
        newbie = ScopedOrderable.create! :move_to => '2', :group_id => 2
        positions.should == [1, 2, 1, 2, 3, 4]
        newbie.position.should == 2
      end

      it 'middle (with a non-numeric string)' do
        expect do
          ScopedOrderable.create! :move_to => 'two', :group_id => 2
        end.to raise_error Mongoid::Orderable::Errors::InvalidTargetPosition
      end
    end

    describe 'scope movement' do

      let(:record){ ScopedOrderable.where(:group_id => 2, :position => 2).first }

      it 'to a new scope group' do
        record.update_attributes :group_id => 3
        positions.should == [1, 2, 1, 2, 1]
        record.position.should == 1
      end

      context 'when moving to an existing scope group' do

        it 'without a position' do
          record.update_attributes :group_id => 1
          positions.should == [1, 2, 3, 1, 2]
          record.reload.position.should == 3
        end

        it 'with symbol position' do
          record.update_attributes :group_id => 1, :move_to => :top
          positions.should == [1, 2, 3, 1, 2]
          record.reload.position.should == 1
        end

        it 'with point position' do
          record.update_attributes :group_id => 1, :move_to => 2
          positions.should == [1, 2, 3, 1, 2]
          record.reload.position.should == 2
        end

        it 'with point position (with a numeric string)' do
          record.update_attributes :group_id => 1, :move_to => '2'
          positions.should == [1, 2, 3, 1, 2]
          record.reload.position.should == 2
        end

        it 'with point position (with a non-numeric string)' do
          expect do
            record.update_attributes :group_id => 1, :move_to => 'two'
          end.to raise_error Mongoid::Orderable::Errors::InvalidTargetPosition
        end
      end
    end

    if defined?(Mongoid::IdentityMap)

      context 'when identity map is enabled' do

        let(:record){ ScopedOrderable.where(:group_id => 2, :position => 2).first }

        before do
          Mongoid.identity_map_enabled = true
          Mongoid::IdentityMap[ScopedOrderable.collection_name] = { record.id => record }
        end

        after do
          Mongoid.identity_map_enabled = false
        end

        it 'to a new scope group' do
          record.update_attributes :group_id => 3
          positions.should == [1, 2, 1, 2, 1]
          record.position.should == 1
        end

        it 'to an existing scope group' do
          record.update_attributes :group_id => 1, :move_to => 2
          positions.should == [1, 2, 3, 1, 2]
          record.reload.position.should == 2
        end

        it 'to an existing scope group (with a numeric string)' do
          record.update_attributes :group_id => 1, :move_to => '2'
          positions.should == [1, 2, 3, 1, 2]
          record.reload.position.should == 2
        end

        it 'to an existing scope group (with a non-numeric string)' do
          expect do
            record.update_attributes :group_id => 1, :move_to => 'two'
          end.to raise_error Mongoid::Orderable::Errors::InvalidTargetPosition
        end
      end
    end

    describe 'utiity methods' do

      it "should return a collection of items lower/higher on the list for next_items/previous_items" do
        record_1 = SimpleOrderable.where(:position => 1).first
        record_2 = SimpleOrderable.where(:position => 2).first
        record_3 = SimpleOrderable.where(:position => 3).first
        record_4 = SimpleOrderable.where(:position => 4).first
        record_5 = SimpleOrderable.where(:position => 5).first
        expect(record_1.next_items.to_a).to eq([record_2, record_3, record_4, record_5])
        expect(record_5.previous_items.to_a).to eq([record_1, record_2, record_3, record_4])
        expect(record_3.previous_items.to_a).to eq([record_1, record_2])
        expect(record_3.next_items.to_a).to eq([record_4, record_5])
        # next_item & previous_item testing
        expect(record_1.next_item).to eq(record_2)
        expect(record_2.previous_item).to eq(record_1)
        expect(record_1.previous_item).to eq(nil)
        expect(record_5.next_item).to eq(nil)
      end
    end
  end

  describe StringScopedOrderable do

    it 'uses the foreign key of the relationship as scope' do
      orderable1 = StringScopedOrderable.create(:some_scope => 1)
      orderable2 = StringScopedOrderable.create(:some_scope => 1)
      orderable3 = StringScopedOrderable.create(:some_scope => 2)
      expect(orderable1.position).to eq 1
      expect(orderable2.position).to eq 2
      expect(orderable3.position).to eq 1
    end
  end

  describe EmbeddedOrderable do

    before :each do
      EmbedsOrderable.delete_all
      eo = EmbedsOrderable.create!
      2.times do
        eo.embedded_orderables.create!
      end
      eo = EmbedsOrderable.create!
      3.times do
        eo.embedded_orderables.create!
      end
    end

    def positions
      EmbedsOrderable.order_by(:position => 1).all.map { |eo| eo.embedded_orderables.map(&:position).sort }
    end

    it 'sets proper position while creation' do
      positions.should == [[1, 2], [1, 2, 3]]
    end

    it 'moves an item returned by a query to position' do
      embedded_orderable_1 = EmbedsOrderable.first.embedded_orderables.where(:position => 1).first
      embedded_orderable_2 = EmbedsOrderable.first.embedded_orderables.where(:position => 2).first
      embedded_orderable_1.move_to! 2
      embedded_orderable_2.reload.position.should == 1
    end
  end

  describe CustomizedOrderable do

    it 'does not have default position field' do
      CustomizedOrderable.fields.should_not have_key('position')
    end

    it 'should have custom pos field' do
      CustomizedOrderable.fields.should have_key('pos')
    end

    it 'should have an alias my_position which points to pos field on Mongoid 3+' do
      if CustomizedOrderable.respond_to?(:database_field_name)
        CustomizedOrderable.database_field_name('my_position').should eq('pos')
      end
    end
  end

  describe NoIndexOrderable do

    it 'should not have index on position column' do
      if MongoidOrderable.mongoid2? || MongoidOrderable.mongoid3?
        NoIndexOrderable.index_options[:position].should be_nil
      else
        NoIndexOrderable.index_specifications.detect { |spec| spec.key == :position }.should be_nil
      end
    end
  end

  describe ZeroBasedOrderable do

    before :each do
      ZeroBasedOrderable.delete_all
      5.times do
        ZeroBasedOrderable.create!
      end
    end

    def positions
      ZeroBasedOrderable.all.map(&:position).sort
    end

    it 'should have a orderable base of 0' do
      ZeroBasedOrderable.create!.orderable_base.should == 0
    end

    it 'should set proper position while creation' do
      positions.should == [0, 1, 2, 3, 4]
    end

    describe 'reset position' do
      before{ ZeroBasedOrderable.update_all({:position => nil}) }
      it 'should properly reset position' do
        ZeroBasedOrderable.all.map(&:save)
        positions.should == [0, 1, 2, 3, 4]
      end
    end

    describe 'removement' do

      it 'top' do
        ZeroBasedOrderable.where(:position => 0).destroy
        positions.should == [0, 1, 2, 3]
      end

      it 'bottom' do
        ZeroBasedOrderable.where(:position => 4).destroy
        positions.should == [0, 1, 2, 3]
      end

      it 'middle' do
        ZeroBasedOrderable.where(:position => 2).destroy
        positions.should == [0, 1, 2, 3]
      end
    end

    describe 'inserting' do

      it 'top' do
        newbie = ZeroBasedOrderable.create! :move_to => :top
        positions.should == [0, 1, 2, 3, 4, 5]
        newbie.position.should == 0
      end

      it 'bottom' do
        newbie = ZeroBasedOrderable.create! :move_to => :bottom
        positions.should == [0, 1, 2, 3, 4, 5]
        newbie.position.should == 5
      end

      it 'middle' do
        newbie = ZeroBasedOrderable.create! :move_to => 3
        positions.should == [0, 1, 2, 3, 4, 5]
        newbie.position.should == 3
      end

      it 'middle (with a numeric string)' do
        newbie = ZeroBasedOrderable.create! :move_to => '3'
        positions.should == [0, 1, 2, 3, 4, 5]
        newbie.position.should == 3
      end

      it 'middle (with a non-numeric string)' do
        expect do
          ZeroBasedOrderable.create! :move_to => 'three'
        end.to raise_error Mongoid::Orderable::Errors::InvalidTargetPosition
      end
    end

    describe 'movement' do

      it 'higher from top' do
        record = ZeroBasedOrderable.where(:position => 0).first
        record.update_attributes :move_to => :higher
        positions.should == [0, 1, 2, 3, 4]
        record.reload.position.should == 0
      end

      it 'higher from bottom' do
        record = ZeroBasedOrderable.where(:position => 4).first
        record.update_attributes :move_to => :higher
        positions.should == [0, 1, 2, 3, 4]
        record.reload.position.should == 3
      end

      it 'higher from middle' do
        record = ZeroBasedOrderable.where(:position => 3).first
        record.update_attributes :move_to => :higher
        positions.should == [0, 1, 2, 3, 4]
        record.reload.position.should == 2
      end

      it 'lower from top' do
        record = ZeroBasedOrderable.where(:position => 0).first
        record.update_attributes :move_to => :lower
        positions.should == [0, 1, 2, 3, 4]
        record.reload.position.should == 1
      end

      it 'lower from bottom' do
        record = ZeroBasedOrderable.where(:position => 4).first
        record.update_attributes :move_to => :lower
        positions.should == [0, 1, 2, 3, 4]
        record.reload.position.should == 4
      end

      it 'lower from middle' do
        record = ZeroBasedOrderable.where(:position => 2).first
        record.update_attributes :move_to => :lower
        positions.should == [0, 1, 2, 3, 4]
        record.reload.position.should == 3
      end

      it 'does nothing if position not change' do
        record = ZeroBasedOrderable.where(:position => 3).first
        record.save
        positions.should == [0, 1, 2, 3, 4]
        record.reload.position.should == 3
      end
    end

    describe 'utiity methods' do

      it "should return a collection of items lower/higher on the list for next_items/previous_items" do
        record_1 = SimpleOrderable.where(:position => 1).first
        record_2 = SimpleOrderable.where(:position => 2).first
        record_3 = SimpleOrderable.where(:position => 3).first
        record_4 = SimpleOrderable.where(:position => 4).first
        record_5 = SimpleOrderable.where(:position => 5).first
        expect(record_1.next_items.to_a).to eq([record_2, record_3, record_4, record_5])
        expect(record_5.previous_items.to_a).to eq([record_1, record_2, record_3, record_4])
        expect(record_3.previous_items.to_a).to eq([record_1, record_2])
        expect(record_3.next_items.to_a).to eq([record_4, record_5])
        # next_item & previous_item testing
        expect(record_1.next_item).to eq(record_2)
        expect(record_2.previous_item).to eq(record_1)
        expect(record_1.previous_item).to eq(nil)
        expect(record_5.next_item).to eq(nil)
      end
    end
  end

  describe Fruit do

    it 'should set proper position' do
      fruit1 = Apple.create
      fruit2 = Orange.create
      fruit1.position.should == 1
      fruit2.position.should == 2
    end

    describe 'movement' do
      before :each do
        Fruit.delete_all
        5.times do
          Apple.create!
        end
      end

      it 'with symbol position' do
        first_apple = Apple.first
        top_pos = first_apple.position
        bottom_pos = Apple.last.position
        expect do
          first_apple.move_to! :bottom
        end.to change(first_apple, :position).from(top_pos).to bottom_pos
      end

      it 'with point position' do
        first_apple = Apple.first
        top_pos = first_apple.position
        bottom_pos = Apple.last.position
        expect do
          first_apple.move_to! bottom_pos
        end.to change(first_apple, :position).from(top_pos).to bottom_pos
      end
    end

    describe 'add orderable configurations in inherited class' do
      it 'does not affect the orderable configurations of parent class and sibling class' do
        class Apple
          orderable :column => :serial
        end
        expect(Fruit.orderable_configurations).not_to eq Apple.orderable_configurations
        expect(Orange.orderable_configurations).not_to eq Apple.orderable_configurations
        expect(Fruit.orderable_configurations).to eq Orange.orderable_configurations
      end
    end
  end

  describe ForeignKeyDiffersOrderable do

    it 'uses the foreign key of the relationship as scope' do
      orderable1, orderable2, orderable3 = nil
      parent_scope1 = ForeignKeyDiffersOrderable.create
      parent_scope2 = ForeignKeyDiffersOrderable.create
      expect do
        orderable1 = ForeignKeyDiffersOrderable.create(:different_scope => parent_scope1)
        orderable2 = ForeignKeyDiffersOrderable.create(:different_scope => parent_scope1)
        orderable3 = ForeignKeyDiffersOrderable.create(:different_scope => parent_scope2)
      end.to_not raise_error
      expect(orderable1.position).to eq 1
      expect(orderable2.position).to eq 2
      expect(orderable3.position).to eq 1
    end
  end

  describe MultipleColumnsOrderable do

    before :each do
      MultipleColumnsOrderable.delete_all
      5.times do
        MultipleColumnsOrderable.create!
      end
    end

    context 'default orderable' do
      let(:serial_nos){ MultipleColumnsOrderable.all.map(&:serial_no).sort }

      describe 'inserting' do
        let(:newbie){ MultipleColumnsOrderable.create! }

        before { @position = newbie.position }

        it 'top' do
          newbie.move_to! :top
          serial_nos.should == [1, 2, 3, 4, 5, 6]
          newbie.serial_no.should == 1
          newbie.position.should == @position
        end

        it 'bottom' do
          newbie.move_to! :bottom
          serial_nos.should == [1, 2, 3, 4, 5, 6]
          newbie.serial_no.should == 6
          newbie.position.should == @position
        end

        it 'middle' do
          newbie.move_to! 4
          serial_nos.should == [1, 2, 3, 4, 5, 6]
          newbie.serial_no.should == 4
          newbie.position.should == @position
        end
      end

      describe 'movement' do
        it 'higher from top' do
          record = MultipleColumnsOrderable.where(:serial_no => 1).first
          position = record.position
          record.move_higher!
          serial_nos.should == [1, 2, 3, 4, 5]
          record.serial_no.should == 1
          record.position.should == position
        end

        it 'higher from bottom' do
          record = MultipleColumnsOrderable.where(:serial_no => 5).first
          position = record.position
          record.move_higher!
          serial_nos.should == [1, 2, 3, 4, 5]
          record.serial_no.should == 4
          record.position.should == position
        end
        
        it 'higher from middle' do
          record = MultipleColumnsOrderable.where(:serial_no => 3).first
          position = record.position
          record.move_higher!
          serial_nos.should == [1, 2, 3, 4, 5]
          record.serial_no.should == 2
          record.position.should == position
        end
        
        it 'lower from top' do
          record = MultipleColumnsOrderable.where(:serial_no => 1).first
          position = record.position
          record.move_lower!
          serial_nos.should == [1, 2, 3, 4, 5]
          record.serial_no.should == 2
          record.position.should == position
        end
        
        it 'lower from bottom' do
          record = MultipleColumnsOrderable.where(:serial_no => 5).first
          position = record.position
          record.move_lower!
          serial_nos.should == [1, 2, 3, 4, 5]
          record.serial_no.should == 5
          record.position.should == position
        end
        
        it 'lower from middle' do
          record = MultipleColumnsOrderable.where(:serial_no => 3).first
          position = record.position
          record.move_lower!
          serial_nos.should == [1, 2, 3, 4, 5]
          record.serial_no.should == 4
          record.position.should == position
        end
      end

      describe 'utility methods' do

        before do
          @record_1 = MultipleColumnsOrderable.where(:serial_no => 1).first
          @record_2 = MultipleColumnsOrderable.where(:serial_no => 2).first
          @record_3 = MultipleColumnsOrderable.where(:serial_no => 3).first
          @record_4 = MultipleColumnsOrderable.where(:serial_no => 4).first
          @record_5 = MultipleColumnsOrderable.where(:serial_no => 5).first
        end

        it "should return the lower/higher item on the list for next_item/previous_item" do
          expect(@record_1.next_item).to eq(@record_2)
          expect(@record_3.next_item).to eq(@record_4)
          expect(@record_5.next_item).to eq(nil)
          expect(@record_1.prev_item).to eq(nil)
          expect(@record_3.prev_item).to eq(@record_2)
          expect(@record_5.prev_item).to eq(@record_4)
        end

        it "should return a collection of items lower/higher on the list for next_items/previous_items" do
          expect(@record_1.next_items.to_a).to eq([@record_2, @record_3, @record_4, @record_5])
          expect(@record_3.next_items.to_a).to eq([@record_4, @record_5])
          expect(@record_5.next_items.to_a).to eq([])
          expect(@record_1.previous_items.to_a).to eq([])
          expect(@record_3.previous_items.to_a).to eq([@record_1, @record_2])
          expect(@record_5.previous_items.to_a).to eq([@record_1, @record_2, @record_3, @record_4])
        end
      end
    end

    context 'serial_no orderable' do

      let(:serial_nos){ MultipleColumnsOrderable.all.map(&:serial_no).sort }

      it 'should have proper serial_no column' do
        MultipleColumnsOrderable.fields.key?('serial_no').should be true
        MultipleColumnsOrderable.fields['serial_no'].options[:type].should == Integer
      end

      it 'should have index on serial_no column' do
        if MongoidOrderable.mongoid2?
          MultipleColumnsOrderable.index_options[:serial_no].should_not be_nil
        elsif MongoidOrderable.mongoid3?
          MultipleColumnsOrderable.index_options[{:serial_no => 1}].should_not be_nil
        else
          MultipleColumnsOrderable.index_specifications.detect { |spec| spec.key == {:serial_no => 1} }.should_not be_nil
        end
      end

      it 'should have a orderable base of 1' do
        MultipleColumnsOrderable.first.orderable_base(:serial_no).should == 1
      end

      it 'should set proper position while creation' do
        serial_nos.should == [1, 2, 3, 4, 5]
      end

      describe 'removement' do

        it 'top' do
          MultipleColumnsOrderable.where(:serial_no => 1).destroy
          serial_nos.should == [1, 2, 3, 4]
        end

        it 'bottom' do
          MultipleColumnsOrderable.where(:serial_no => 5).destroy
          serial_nos.should == [1, 2, 3, 4]
        end

        it 'middle' do
          MultipleColumnsOrderable.where(:serial_no => 3).destroy
          serial_nos.should == [1, 2, 3, 4]
        end
      end

      describe 'inserting' do
        let(:newbie){ MultipleColumnsOrderable.create! }

        before { @position = newbie.position }

        it 'top' do
          newbie.move_serial_no_to! :top
          serial_nos.should == [1, 2, 3, 4, 5, 6]
          newbie.serial_no.should == 1
          newbie.position.should == @position
        end

        it 'bottom' do
          newbie.move_serial_no_to! :bottom
          serial_nos.should == [1, 2, 3, 4, 5, 6]
          newbie.serial_no.should == 6
          newbie.position.should == @position
        end

        it 'middle' do
          newbie.move_serial_no_to! 4
          serial_nos.should == [1, 2, 3, 4, 5, 6]
          newbie.serial_no.should == 4
          newbie.position.should == @position
        end
      end

      describe 'movement' do
        it 'higher from top' do
          record = MultipleColumnsOrderable.where(:serial_no => 1).first
          position = record.position
          record.move_serial_no_higher!
          serial_nos.should == [1, 2, 3, 4, 5]
          record.serial_no.should == 1
          record.position.should == position
        end

        it 'higher from bottom' do
          record = MultipleColumnsOrderable.where(:serial_no => 5).first
          position = record.position
          record.move_serial_no_higher!
          serial_nos.should == [1, 2, 3, 4, 5]
          record.serial_no.should == 4
          record.position.should == position
        end
        
        it 'higher from middle' do
          record = MultipleColumnsOrderable.where(:serial_no => 3).first
          position = record.position
          record.move_serial_no_higher!
          serial_nos.should == [1, 2, 3, 4, 5]
          record.serial_no.should == 2
          record.position.should == position
        end
        
        it 'lower from top' do
          record = MultipleColumnsOrderable.where(:serial_no => 1).first
          position = record.position
          record.move_serial_no_lower!
          serial_nos.should == [1, 2, 3, 4, 5]
          record.serial_no.should == 2
          record.position.should == position
        end
        
        it 'lower from bottom' do
          record = MultipleColumnsOrderable.where(:serial_no => 5).first
          position = record.position
          record.move_serial_no_lower!
          serial_nos.should == [1, 2, 3, 4, 5]
          record.serial_no.should == 5
          record.position.should == position
        end
        
        it 'lower from middle' do
          record = MultipleColumnsOrderable.where(:serial_no => 3).first
          position = record.position
          record.move_serial_no_lower!
          serial_nos.should == [1, 2, 3, 4, 5]
          record.serial_no.should == 4
          record.position.should == position
        end
      end

      describe 'utility methods' do

        before do
          @record_1 = MultipleColumnsOrderable.where(:serial_no => 1).first
          @record_2 = MultipleColumnsOrderable.where(:serial_no => 2).first
          @record_3 = MultipleColumnsOrderable.where(:serial_no => 3).first
          @record_4 = MultipleColumnsOrderable.where(:serial_no => 4).first
          @record_5 = MultipleColumnsOrderable.where(:serial_no => 5).first
        end

        it "should return the lower/higher item on the list for next_item/previous_item" do
          expect(@record_1.next_serial_no_item).to eq(@record_2)
          expect(@record_3.next_serial_no_item).to eq(@record_4)
          expect(@record_5.next_serial_no_item).to eq(nil)
          expect(@record_1.prev_serial_no_item).to eq(nil)
          expect(@record_3.prev_serial_no_item).to eq(@record_2)
          expect(@record_5.prev_serial_no_item).to eq(@record_4)
        end

        it "should return a collection of items lower/higher on the list for next_items/previous_items" do
          expect(@record_1.next_serial_no_items.to_a).to eq([@record_2, @record_3, @record_4, @record_5])
          expect(@record_3.next_serial_no_items.to_a).to eq([@record_4, @record_5])
          expect(@record_5.next_serial_no_items.to_a).to eq([])
          expect(@record_1.previous_serial_no_items.to_a).to eq([])
          expect(@record_3.previous_serial_no_items.to_a).to eq([@record_1, @record_2])
          expect(@record_5.previous_serial_no_items.to_a).to eq([@record_1, @record_2, @record_3, @record_4])
        end
      end

    end

    context 'position orderable' do

      let(:positions){ MultipleColumnsOrderable.all.map(&:position).sort }

      it 'should not have default position field' do
        MultipleColumnsOrderable.fields.should_not have_key('position')
      end

      it 'should have custom pos field' do
        MultipleColumnsOrderable.fields.should have_key('pos')
        MultipleColumnsOrderable.fields['pos'].options[:type].should == Integer
      end

      it 'should have index on position column' do
        if MongoidOrderable.mongoid2?
          MultipleColumnsOrderable.index_options[:position].should be_nil
        elsif MongoidOrderable.mongoid3?
          MultipleColumnsOrderable.index_options[{:position => 1}].should be_nil
        else
          MultipleColumnsOrderable.index_specifications.detect { |spec| spec.key == {:position => 1} }.should be_nil
        end
      end

      it 'should have a orderable base of 0' do
        MultipleColumnsOrderable.first.orderable_base(:position).should == 0
      end

      it 'should set proper position while creation' do
        positions.should == [0, 1, 2, 3, 4]
      end

      describe 'removement' do

        it 'top' do
          MultipleColumnsOrderable.where(:pos => 1).destroy
          positions.should == [0, 1, 2, 3]
        end

        it 'bottom' do
          MultipleColumnsOrderable.where(:pos => 4).destroy
          positions.should == [0, 1, 2, 3]
        end

        it 'middle' do
          MultipleColumnsOrderable.where(:pos => 3).destroy
          positions.should == [0, 1, 2, 3]
        end
      end

      describe 'inserting' do
        let(:newbie){ MultipleColumnsOrderable.create! }

        before { @serial_no = newbie.serial_no }

        it 'top' do
          newbie.move_position_to! :top
          positions.should == [0, 1, 2, 3, 4, 5]
          newbie.position.should == 0
          newbie.serial_no.should == @serial_no
        end

        it 'bottom' do
          newbie.move_position_to! :bottom
          positions.should == [0, 1, 2, 3, 4, 5]
          newbie.position.should == 5
          newbie.serial_no.should == @serial_no
        end

        it 'middle' do
          newbie.move_position_to! 4
          positions.should == [0, 1, 2, 3, 4, 5]
          newbie.position.should == 4
          newbie.serial_no.should == @serial_no
        end
      end

      describe 'movement' do
        it 'higher from top' do
          record = MultipleColumnsOrderable.where(:pos => 0).first
          position = record.serial_no
          record.move_position_higher!
          positions.should == [0, 1, 2, 3, 4]
          record.position.should == 0
          record.serial_no.should == position
        end

        it 'higher from bottom' do
          record = MultipleColumnsOrderable.where(:pos => 4).first
          position = record.serial_no
          record.move_position_higher!
          positions.should == [0, 1, 2, 3, 4]
          record.position.should == 3
          record.serial_no.should == position
        end
        
        it 'higher from middle' do
          record = MultipleColumnsOrderable.where(:pos => 3).first
          position = record.serial_no
          record.move_position_higher!
          positions.should == [0, 1, 2, 3, 4]
          record.position.should == 2
          record.serial_no.should == position
        end
        
        it 'lower from top' do
          record = MultipleColumnsOrderable.where(:pos => 0).first
          position = record.serial_no
          record.move_position_lower!
          positions.should == [0, 1, 2, 3, 4]
          record.position.should == 1
          record.serial_no.should == position
        end
        
        it 'lower from bottom' do
          record = MultipleColumnsOrderable.where(:pos => 4).first
          position = record.serial_no
          record.move_position_lower!
          positions.should == [0, 1, 2, 3, 4]
          record.position.should == 4
          record.serial_no.should == position
        end
        
        it 'lower from middle' do
          record = MultipleColumnsOrderable.where(:pos => 3).first
          position = record.serial_no
          record.move_position_lower!
          positions.should == [0, 1, 2, 3, 4]
          record.position.should == 4
          record.serial_no.should == position
        end
      end

      describe 'utility methods' do

        before do
          @record_1 = MultipleColumnsOrderable.where(:pos => 0).first
          @record_2 = MultipleColumnsOrderable.where(:pos => 1).first
          @record_3 = MultipleColumnsOrderable.where(:pos => 2).first
          @record_4 = MultipleColumnsOrderable.where(:pos => 3).first
          @record_5 = MultipleColumnsOrderable.where(:pos => 4).first
        end

        it "should return the lower/higher item on the list for next_item/previous_item" do
          expect(@record_1.next_position_item).to eq(@record_2)
          expect(@record_3.next_position_item).to eq(@record_4)
          expect(@record_5.next_position_item).to eq(nil)
          expect(@record_1.prev_position_item).to eq(nil)
          expect(@record_3.prev_position_item).to eq(@record_2)
          expect(@record_5.prev_position_item).to eq(@record_4)
        end

        it "should return a collection of items lower/higher on the list for next_items/previous_items" do
          expect(@record_1.next_position_items.to_a).to eq([@record_2, @record_3, @record_4, @record_5])
          expect(@record_3.next_position_items.to_a).to eq([@record_4, @record_5])
          expect(@record_5.next_position_items.to_a).to eq([])
          expect(@record_1.previous_position_items.to_a).to eq([])
          expect(@record_3.previous_position_items.to_a).to eq([@record_1, @record_2])
          expect(@record_5.previous_position_items.to_a).to eq([@record_1, @record_2, @record_3, @record_4])
        end
      end

    end

    context 'group_count orderable' do
      before :each do
        MultipleColumnsOrderable.delete_all
        2.times { MultipleColumnsOrderable.create! :group_id => 1 }
        3.times { MultipleColumnsOrderable.create! :group_id => 2 }
      end

      let(:all_groups){ MultipleColumnsOrderable.order_by([:group_id, :asc], [:groups, :asc]).map(&:groups) }

      it 'should set proper position while creation' do
        all_groups.should == [1, 2, 1, 2, 3]
      end

      describe 'removement' do

        it 'top' do
          MultipleColumnsOrderable.where(:groups => 1, :group_id => 1).destroy
          all_groups.should == [1, 1, 2, 3]
        end

        it 'bottom' do
          MultipleColumnsOrderable.where(:groups => 3, :group_id => 2).destroy
          all_groups.should == [1, 2, 1, 2]
        end

        it 'middle' do
          MultipleColumnsOrderable.where(:groups => 2, :group_id => 2).destroy
          all_groups.should == [1, 2, 1, 2]
        end
      end

      describe 'inserting' do

        it 'top' do
          newbie = MultipleColumnsOrderable.create! :group_id => 1
          newbie.move_groups_to! :top
          all_groups.should == [1, 2, 3, 1, 2, 3]
          newbie.groups.should == 1
        end

        it 'bottom' do
          newbie = MultipleColumnsOrderable.create! :group_id => 2
          newbie.move_groups_to! :bottom
          all_groups.should == [1, 2, 1, 2, 3, 4]
          newbie.groups.should == 4
        end

        it 'middle' do
          newbie = MultipleColumnsOrderable.create! :group_id => 2
          newbie.move_groups_to! 2
          all_groups.should == [1, 2, 1, 2, 3, 4]
          newbie.groups.should == 2
        end
      end

      describe 'scope movement' do
      
        let(:record){ MultipleColumnsOrderable.where(:group_id => 2, :groups => 2).first }
      
        it 'to a new scope group' do
          record.update_attributes :group_id => 3
          all_groups.should == [1, 2, 1, 2, 1]
          record.groups.should == 1
        end
      
        context 'when moving to an existing scope group' do
      
          it 'without a position' do
            record.update_attributes :group_id => 1
            all_groups.should == [1, 2, 3, 1, 2]
            record.reload.groups.should == 3
          end
      
          it 'with symbol position' do
            record.update_attributes :group_id => 1
            record.move_groups_to! :top
            all_groups.should == [1, 2, 3, 1, 2]
            record.reload.groups.should == 1
          end
      
          it 'with point position' do
            record.update_attributes :group_id => 1
            record.move_groups_to! 2
            all_groups.should == [1, 2, 3, 1, 2]
            record.reload.groups.should == 2
          end
        end
      end

      if defined?(Mongoid::IdentityMap)

        context 'when identity map is enabled' do

          let(:record){ MultipleColumnsOrderable.where(:group_id => 2, :groups => 2).first }

          before do
            Mongoid.identity_map_enabled = true
            Mongoid::IdentityMap[MultipleColumnsOrderable.collection_name] = { record.id => record }
          end

          after { Mongoid.identity_map_enabled = false }

          it 'to a new scope group' do
            record.update_attributes :group_id => 3
            all_groups.should == [1, 2, 1, 2, 1]
            record.groups.should == 1
          end

          it 'to an existing scope group' do
            record.update_attributes :group_id => 1
            record.move_groups_to! 2
            all_groups.should == [1, 2, 3, 1, 2]
            record.groups.should == 2
          end
        end
      end

      describe 'utility methods' do

        before do
          @record_1 = MultipleColumnsOrderable.where(:group_id => 2, :groups => 1).first
          @record_2 = MultipleColumnsOrderable.where(:group_id => 2, :groups => 2).first
          @record_3 = MultipleColumnsOrderable.where(:group_id => 2, :groups => 3).first
          @record_4 = MultipleColumnsOrderable.where(:group_id => 1, :groups => 1).first
          @record_5 = MultipleColumnsOrderable.where(:group_id => 1, :groups => 2).first
        end

        it "should return the lower/higher item on the list for next_item/previous_item" do
          expect(@record_1.next_groups_item).to eq(@record_2)
          expect(@record_4.next_groups_item).to eq(@record_5)
          expect(@record_3.next_groups_item).to eq(nil)
          expect(@record_1.prev_groups_item).to eq(nil)
          expect(@record_3.prev_groups_item).to eq(@record_2)
          expect(@record_5.prev_groups_item).to eq(@record_4)
        end

        it "should return a collection of items lower/higher on the list for next_items/previous_items" do
          expect(@record_1.next_groups_items.to_a).to eq([@record_2, @record_3])
          expect(@record_3.next_groups_items.to_a).to eq([])
          expect(@record_4.next_groups_items.to_a).to eq([@record_5])
          expect(@record_1.previous_groups_items.to_a).to eq([])
          expect(@record_3.previous_groups_items.to_a).to eq([@record_1, @record_2])
          expect(@record_5.previous_groups_items.to_a).to eq([@record_4])
        end
      end
    end
  end

end
