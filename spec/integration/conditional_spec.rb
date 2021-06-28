require_relative '../spec_helper'

describe ConditionalOrderable do

  shared_examples_for 'conditional_orderable' do

    before :each do
      ConditionalOrderable.create!(cond_a: false, cond_b: nil)
      ConditionalOrderable.create!(cond_a: false, cond_b: 1)
      ConditionalOrderable.create!(cond_a: true, cond_b: 2)
      ConditionalOrderable.create!(cond_a: false, cond_b: 3)
      ConditionalOrderable.create!(cond_a: true, cond_b: 4)
      ConditionalOrderable.create!(cond_a: true, cond_b: 5)
    end

    it 'should have proper position field' do
      orderables = ConditionalOrderable.all.sort_by {|x| x.cond_b || 0 }

      expect(orderables.map(&:pos_a)).to eq [nil, nil, 1, nil, 2, 3]
      expect(orderables.map(&:pos_b)).to eq [nil, 1, 2, 3, 4, nil]
      expect(orderables.map(&:pos_c)).to eq [1, 2, 3, 4, 5, 6]
    end
  end

  context 'with transactions' do
    enable_transactions!

    it_behaves_like 'conditional_orderable'
  end

  context 'without transactions' do
    disable_transactions!

    it_behaves_like 'conditional_orderable'
  end
end
