require 'spec_helper'

describe CustomizedOrderable do

  shared_examples_for 'customized_orderable' do

    it 'does not have default position field' do
      expect(CustomizedOrderable.fields).not_to have_key('position')
    end

    it 'should have custom pos field' do
      expect(CustomizedOrderable.fields).to have_key('pos')
    end

    it 'should have an alias my_position which points to pos field on Mongoid 3+' do
      expect(CustomizedOrderable.database_field_name('my_position')).to eq('pos')
    end
  end

  context 'with transactions' do
    enable_transactions!

    it_behaves_like 'customized_orderable'
  end

  context 'without transactions' do
    disable_transactions!

    it_behaves_like 'customized_orderable'
  end
end
