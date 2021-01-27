require 'spec_helper'

describe StringScopedOrderable do

  shared_examples_for 'string_scoped_orderable' do

    it 'uses the foreign key of the relationship as scope' do
      orderable1 = StringScopedOrderable.create!(some_scope: 1)
      orderable2 = StringScopedOrderable.create!(some_scope: 1)
      orderable3 = StringScopedOrderable.create!(some_scope: 2)
      expect(orderable1.position).to eq 1
      expect(orderable2.position).to eq 2
      expect(orderable3.position).to eq 1
    end
  end

  context 'with transactions' do
    enable_transactions!

    it_behaves_like 'string_scoped_orderable'
  end

  context 'without transactions' do
    disable_transactions!

    it_behaves_like 'string_scoped_orderable'
  end
end
