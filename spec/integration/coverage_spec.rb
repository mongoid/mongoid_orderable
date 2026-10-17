require 'spec_helper'

describe 'Orderable helper contracts' do
  disable_transactions!

  it 'recognizes list membership and both endpoints' do
    first = SimpleOrderable.create!
    last = SimpleOrderable.create!

    expect(SimpleOrderable.new.in_list?).to eq(false)
    expect(first.in_list?).to eq(true)
    expect(first.first?).to eq(true)
    expect(first.last?).to eq(false)
    expect(last.first?).to eq(false)
    expect(last.last?).to eq(true)
  end

  it 'moves through the generated positional methods and setters' do
    first, middle, last = 3.times.map { SimpleOrderable.create! }
    first.move_position_to(3)
    first.save!
    expect(SimpleOrderable.asc(:position).to_a).to eq([middle, last, first])

    first.move_position_to = 1
    first.save!
    expect(SimpleOrderable.asc(:position).to_a).to eq([first, middle, last])
  end

  it 'moves through generated top, bottom, higher and lower helpers' do
    first, middle, last = 3.times.map { SimpleOrderable.create! }
    last.move_position_to_top
    last.save!
    expect(last.reload.position).to eq(1)

    last.move_position_to_bottom!
    expect(last.reload.position).to eq(3)
    last.move_position_higher
    last.save!
    expect(last.reload.position).to eq(2)

    last.move_position_lower!
    expect(last.reload.position).to eq(3)
    expect(SimpleOrderable.asc(:position).to_a).to eq([first, middle, last])
  end

  it 'compacts embedded siblings when a child is destroyed and handles root destruction' do
    parent = EmbedsOrderable.create!
    first, middle, last = 3.times.map { parent.embedded_orderables.create! }
    middle.destroy!
    expect(parent.reload.embedded_orderables.map(&:id)).to eq([first.id, last.id])
    expect(parent.embedded_orderables.map(&:position)).to eq([1, 2])

    parent.destroy!
    expect(parent).to be_destroyed
  end
end

describe Mongoid::Orderable::Handlers::Transaction do
  it 'reuses the outer transaction for nested operations' do
    handler = described_class.new(SimpleOrderable.new)
    expect(handler).to receive(:do_transaction).once.and_call_original
    calls = 0

    handler.with_transaction { handler.with_transaction { calls += 1 } }
    expect(calls).to eq(1)
    expect(Thread.current[described_class::THREAD_KEY]).to be_nil
  end

  it 'wraps exhausted server retries and clears thread-local transaction state' do
    handler = described_class.new(SimpleOrderable.new)
    error = Mongo::Error::OperationFailure.new('simulated write conflict')
    allow(handler).to receive(:transaction_max_retries).and_return(1)
    expect(handler).to receive(:do_transaction).twice.and_raise(error)

    expect { handler.with_transaction { raise 'unreachable' } }
      .to raise_error(Mongoid::Orderable::Errors::TransactionFailed, /simulated write conflict/)
    expect(Thread.current[described_class::THREAD_KEY]).to be_nil
  end
end

describe Mongoid::Orderable do
  it 'rejects non-field entries in a scope array' do
    expect { Mongoid::Orderable::Configs::FieldConfig.new(SimpleOrderable, scope: [:position, 42]) }
      .to raise_error(ArgumentError, /Orderable :scope invalid/)
  end

  it 'loads its standalone version entry point' do
    stub_const('Mongoid::Orderable', Module.new)
    load File.expand_path('../../lib/mongoid/orderable/version.rb', __dir__)
    expect(Mongoid::Orderable::VERSION).to match(/\A\d+\.\d+\.\d+\z/)
  end
end
