require 'spec_helper'

describe Mongoid::Orderable::Mixins::Changeable do

  it do
    orderable = SimpleOrderable.create!
    expect(orderable.changed?).to eq false
    orderable.move_to = 2
    expect(orderable.changed?).to eq true
  end
end
