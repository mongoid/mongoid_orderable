require 'spec_helper'

describe 'concurrency' do
  enable_transactions!

  describe 'simple create' do

    it 'should correctly insert at the top' do
      20.times.map do
        Thread.new do
          SimpleOrderable.create!(move_to: :top)
        end
      end.each(&:join)

      expect(SimpleOrderable.pluck(:position).sort).to eq((1..20).to_a)
    end

    it 'should correctly insert at the bottom' do
      20.times.map do
        Thread.new do
          SimpleOrderable.create!
        end
      end.each(&:join)

      expect(SimpleOrderable.pluck(:position).sort).to eq((1..20).to_a)
    end

    it 'should correctly insert at a random position' do
      20.times.map do
        Thread.new do
          SimpleOrderable.create!(move_to: (1..10).to_a.sample)
        end
      end.each(&:join)

      expect(SimpleOrderable.pluck(:position).sort).to eq((1..20).to_a)
    end
  end

  describe 'simple update' do
    before :each do
      5.times { SimpleOrderable.create! }
    end

    it 'should correctly move items to top' do
      20.times.map do
        Thread.new do
          record = SimpleOrderable.all.sample
          record.update_attributes move_to: :top
        end
      end.each(&:join)

      expect(SimpleOrderable.pluck(:position).sort).to eq([1, 2, 3, 4, 5])
    end

    it 'should correctly move items to bottom' do
      20.times.map do
        Thread.new do
          record = SimpleOrderable.all.sample
          record.update_attributes move_to: :bottom
        end
      end.each(&:join)

      expect(SimpleOrderable.pluck(:position).sort).to eq([1, 2, 3, 4, 5])
    end

    it 'should correctly move items higher' do
      20.times.map do
        Thread.new do
          record = SimpleOrderable.all.sample
          record.update_attributes move_to: :higher
        end
      end.each(&:join)

      expect(SimpleOrderable.pluck(:position).sort).to eq([1, 2, 3, 4, 5])
    end

    it 'should correctly move items lower' do
      20.times.map do
        Thread.new do
          record = SimpleOrderable.all.sample
          record.update_attributes move_to: :lower
        end
      end.each(&:join)

      expect(SimpleOrderable.pluck(:position).sort).to eq([1, 2, 3, 4, 5])
    end

    it 'should correctly insert at the top' do
      20.times.map do
        Thread.new do
          SimpleOrderable.create!(move_to: :top)
        end
      end.each(&:join)

      expect(SimpleOrderable.pluck(:position).sort).to eq((1..25).to_a)
    end

    it 'should correctly insert at the bottom' do
      20.times.map do
        Thread.new do
          SimpleOrderable.create!
        end
      end.each(&:join)

      expect(SimpleOrderable.pluck(:position).sort).to eq((1..25).to_a)
    end

    it 'should correctly insert at a random position' do
      20.times.map do
        Thread.new do
          SimpleOrderable.create!(move_to: (1..10).to_a.sample)
        end
      end.each(&:join)

      expect(SimpleOrderable.pluck(:position).sort).to eq((1..25).to_a)
    end

    it 'should correctly move items to a random position' do
      20.times.map do
        Thread.new do
          record = SimpleOrderable.all.sample
          record.update_attributes move_to: (1..5).to_a.sample
        end
      end.each(&:join)

      expect(SimpleOrderable.pluck(:position).sort).to eq([1, 2, 3, 4, 5])
    end
  end

  describe 'scoped update' do

    before :each do
      2.times { ScopedOrderable.create! group_id: 1 }
      3.times { ScopedOrderable.create! group_id: 2 }
    end

    it 'should correctly move items to top' do
      20.times.map do
        Thread.new do
          record = ScopedOrderable.all.sample
          record.update_attributes move_to: :top
        end
      end.each(&:join)

      expect(ScopedOrderable.pluck(:position).sort).to eq([1, 1, 2, 2, 3])
    end

    it 'should correctly move items to bottom' do
      20.times.map do
        Thread.new do
          record = ScopedOrderable.all.sample
          record.update_attributes move_to: :bottom
        end
      end.each(&:join)

      expect(ScopedOrderable.pluck(:position).sort).to eq([1, 1, 2, 2, 3])
    end

    it 'should correctly move items higher' do
      20.times.map do
        Thread.new do
          record = ScopedOrderable.all.sample
          record.update_attributes move_to: :higher
        end
      end.each(&:join)

      expect(ScopedOrderable.pluck(:position).sort).to eq([1, 1, 2, 2, 3])
    end

    it 'should correctly move items lower' do
      20.times.map do
        Thread.new do
          record = ScopedOrderable.all.sample
          record.update_attributes move_to: :lower
        end
      end.each(&:join)

      expect(ScopedOrderable.pluck(:position).sort).to eq([1, 1, 2, 2, 3])
    end

    it 'should correctly move items to a random position' do
      20.times.map do
        Thread.new do
          record = ScopedOrderable.all.sample
          record.update_attributes move_to: (1..5).to_a.sample
        end
      end.each(&:join)

      expect(ScopedOrderable.pluck(:position).sort).to eq([1, 1, 2, 2, 3])
    end

    # This spec fails randomly
    it 'should correctly move items to a random scope', retry: 5 do
      20.times.map do
        Thread.new do
          record = ScopedOrderable.all.sample
          group_id = ([1, 2, 3] - [record.group_id]).sample
          record.update_attributes group_id: group_id
        end
      end.each(&:join)

      result = ScopedOrderable.all.to_a.each_with_object({}) do |obj, hash|
        hash[obj.group_id] ||= []
        hash[obj.group_id] << obj.position
      end

      result.values.each do |ary|
        expect(ary.sort).to eq((1..(ary.size)).to_a)
      end
    end

    it 'should correctly move items to a random position and scope' do
      20.times.map do
        Thread.new do
          record = ScopedOrderable.all.sample
          group_id = ([1, 2, 3] - [record.group_id]).sample
          position = (1..5).to_a.sample
          record.update_attributes group_id: group_id, move_to: position
        end
      end.each(&:join)

      result = ScopedOrderable.all.to_a.each_with_object({}) do |obj, hash|
        hash[obj.group_id] ||= []
        hash[obj.group_id] << obj.position
      end

      result.values.each do |ary|
        expect(ary.sort).to eq((1..(ary.size)).to_a)
      end
    end
  end
end
