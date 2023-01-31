require 'spec_helper'

describe Mongoid::Orderable::Mixins::Cascadeable do

  it do
    eo = EmbedsOrderable.create!
    orderable = eo.embedded_orderables.create!
    expect(orderable.in_callback_state?(:update)).to eq false
    orderable.move_to = 2
    expect(orderable.in_callback_state?(:update)).to eq true
  end
end
