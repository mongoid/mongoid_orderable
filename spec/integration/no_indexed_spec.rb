require 'spec_helper'

describe NoIndexOrderable do

  shared_examples_for 'no_index_orderable' do

    it 'should not have index on position field' do
      expect(NoIndexOrderable.index_specifications.detect {|spec| spec.key == :position }).to be_nil
    end
  end

  context 'with transactions' do
    enable_transactions!

    it_behaves_like 'no_index_orderable'
  end

  context 'without transactions' do
    disable_transactions!

    it_behaves_like 'no_index_orderable'
  end
end
