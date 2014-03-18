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
      SimpleOrderable.fields.key?('position').should be_true
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
end
