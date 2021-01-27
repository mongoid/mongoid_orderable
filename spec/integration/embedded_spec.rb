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

    it 'moves an item returned by a query to position' do
      embedded_orderable1 = EmbedsOrderable.first.embedded_orderables.where(position: 1).first
      embedded_orderable2 = EmbedsOrderable.first.embedded_orderables.where(position: 2).first
      embedded_orderable1.move_to! 2
      expect(embedded_orderable2.reload.position).to eq(1)
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
