require 'spec_helper'

describe MultipleScopedOrderable do

  shared_examples_for 'multiple_scoped_orderable' do

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

  context 'with transactions' do
    enable_transactions!

    it_behaves_like 'multiple_scoped_orderable'
  end

  context 'without transactions' do
    disable_transactions!

    it_behaves_like 'multiple_scoped_orderable'
  end
end
