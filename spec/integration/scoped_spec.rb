require 'spec_helper'

describe ScopedOrderable do

  shared_examples_for 'scoped_orderable' do

    def positions
      ScopedOrderable.order_by([:group_id, :asc], [:position, :asc]).map(&:position)
    end

    before :each do
      2.times { ScopedOrderable.create! group_id: 1 }
      3.times { ScopedOrderable.create! group_id: 2 }
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
  end

  context 'with transactions' do
    enable_transactions!

    it_behaves_like 'scoped_orderable'
  end

  context 'without transactions' do
    disable_transactions!

    it_behaves_like 'scoped_orderable'
  end
end
