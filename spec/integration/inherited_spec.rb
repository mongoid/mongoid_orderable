require 'spec_helper'

describe InheritedOrderable do

  shared_examples_for 'inherited_orderable' do

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
        expect { first_apple.move_to!(:bottom) }.to change(first_apple, :position).from(top_pos).to bottom_pos
      end

      it 'with point position' do
        first_apple = Apple.asc(:_id).first
        top_pos = first_apple.position
        bottom_pos = Apple.asc(:_id).last.position
        expect { first_apple.move_to!(bottom_pos) }.to change(first_apple, :position).from(top_pos).to bottom_pos
      end
    end

    describe 'add orderable configs in inherited class' do
      it 'does not affect the orderable configs of parent class and sibling class' do
        expect(InheritedOrderable.orderable_configs).not_to eq Apple.orderable_configs
        expect(Orange.orderable_configs).not_to eq Apple.orderable_configs
        expect(InheritedOrderable.orderable_configs).to eq Orange.orderable_configs
      end
    end
  end

  context 'with transactions' do
    enable_transactions!

    it_behaves_like 'inherited_orderable'
  end

  context 'without transactions' do
    disable_transactions!

    it_behaves_like 'inherited_orderable'
  end
end
