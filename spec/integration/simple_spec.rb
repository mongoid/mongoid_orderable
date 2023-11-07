require 'spec_helper'

describe SimpleOrderable do

  shared_examples_for 'simple_orderable' do

    def positions
      SimpleOrderable.pluck(:position).sort
    end

    before :each do
      5.times { SimpleOrderable.create! }
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
        newbie.send(:orderable_before_update) { }
        expect(newbie.position).to eq(6)
        another = SimpleOrderable.create!
        expect(another.position).to eq(6)
        newbie.save!
        expect(positions).to eq([1, 2, 3, 4, 5, 6, 7])
        expect(newbie.position).to eq(6)
        expect(newbie.reload.position).to eq(6)
        expect(another.position).to eq(6)
        expect(another.reload.position).to eq(7)
      end

      it 'parallel updates' do
        newbie = SimpleOrderable.new
        newbie.send(:orderable_before_update) { }
        another = SimpleOrderable.create!
        newbie.save!
        expect(positions).to eq([1, 2, 3, 4, 5, 6, 7])
        expect(newbie.position).to eq(6)
        expect(newbie.reload.position).to eq(6)
        expect(another.position).to eq(6)
        expect(another.reload.position).to eq(7)
      end

      it 'with correct specific position as a number' do
        record = SimpleOrderable.create!(position: 3)
        expect(record.position).to eq(3)
        expect(record.reload.position).to eq(3)
      end

      it 'with incorrect specific position as a number' do
        record = SimpleOrderable.create!(position: -4)
        expect(record.position).to eq(1)
        expect(record.reload.position).to eq(1)
      end

      it 'with correct specific position as a string' do
        record = SimpleOrderable.create!(position: '4')
        expect(record.position).to eq(4)
        expect(record.reload.position).to eq(4)
      end

      it 'with incorrect specific position as a string' do
        record = SimpleOrderable.create!(position: '-4')
        expect(record.position).to eq(1)
        expect(record.reload.position).to eq(1)
      end

      it 'should offset the positions of all the next elements' do
        records = SimpleOrderable.all
        expect(records.pluck(:position)).to eq([1, 2, 3, 4, 5])
        SimpleOrderable.create!(position: 3)
        expect(records.pluck(:position)).to eq([1, 2, 4, 5, 6, 3])
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
  end

  context 'with transactions' do
    enable_transactions!

    it_behaves_like 'simple_orderable'
  end

  context 'without transactions' do
    disable_transactions!

    it_behaves_like 'simple_orderable'
  end
end
