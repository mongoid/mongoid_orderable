require 'spec_helper'

describe EmbeddedOrderable do

  shared_examples_for 'embedded_orderable' do

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

    it 'move_to! moves an item returned by a query to position' do
      parent = EmbedsOrderable.first
      child1 = parent.embedded_orderables.where(position: 1).first
      child2 = parent.embedded_orderables.where(position: 2).first
      child1.move_to!(2)
      expect(child1.reload.position).to eq(2)
      expect(child2.reload.position).to eq(1)
    end

    it 'move_to moves an item returned by a query to position when saving the parent' do
      parent = EmbedsOrderable.first
      child1 = parent.embedded_orderables.where(position: 1).first
      child2 = parent.embedded_orderables.where(position: 2).first
      child1.move_to(2)
      parent.save!
      expect(child1.reload.position).to eq(2)
      expect(child2.reload.position).to eq(1)
    end

    it 'move_to= moves an item returned by a query to position when saving the parent' do
      parent = EmbedsOrderable.first
      child1 = parent.embedded_orderables.where(position: 1).first
      child2 = parent.embedded_orderables.where(position: 2).first
      child1.move_to = 2
      parent.save!
      expect(child1.reload.position).to eq(2)
      expect(child2.reload.position).to eq(1)
    end
  end

  context 'with transactions' do
    enable_transactions!

    it_behaves_like 'embedded_orderable'
  end

  context 'without transactions' do
    disable_transactions!

    it_behaves_like 'embedded_orderable'
  end
end
