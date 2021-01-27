require 'spec_helper'

describe ForeignKeyDiffersOrderable do

  shared_examples_for 'foreign_key_orderable' do

    it 'uses the foreign key of the relationship as scope' do
      orderable1, orderable2, orderable3 = nil
      parent_scope1 = ForeignKeyDiffersOrderable.create
      parent_scope2 = ForeignKeyDiffersOrderable.create
      expect do
        orderable1 = ForeignKeyDiffersOrderable.create!(different_scope: parent_scope1)
        orderable2 = ForeignKeyDiffersOrderable.create!(different_scope: parent_scope1)
        orderable3 = ForeignKeyDiffersOrderable.create!(different_scope: parent_scope2)
      end.to_not raise_error
      expect(orderable1.position).to eq 1
      expect(orderable2.position).to eq 2
      expect(orderable3.position).to eq 1
    end
  end

  context 'with transactions' do
    enable_transactions!

    it_behaves_like 'foreign_key_orderable'
  end

  context 'without transactions' do
    disable_transactions!

    it_behaves_like 'foreign_key_orderable'
  end
end
