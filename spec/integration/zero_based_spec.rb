require 'spec_helper'

describe ZeroBasedOrderable do

  shared_examples_for 'zero_based_orderable' do

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

  context 'with transactions' do
    enable_transactions!

    it_behaves_like 'zero_based_orderable'
  end

  context 'without transactions' do
    disable_transactions!

    it_behaves_like 'zero_based_orderable'
  end
end
