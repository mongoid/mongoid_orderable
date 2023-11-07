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
      EmbedsOrderable.order_by(position: 1).all.map { |eo| eo.embedded_orderables.map(&:position) }
    end

    it 'sets proper position while creation' do
      expect(positions).to eq([[1, 2], [1, 2, 3]])
    end

    context '#move_to!' do
      it 'moves an embedded item to top position' do
        parent = EmbedsOrderable.first
        child1 = parent.embedded_orderables.where(position: 1).first
        child2 = parent.embedded_orderables.where(position: 2).first
        child2.move_to!(1)

        # before reload
        expect(parent.embedded_orderables.map(&:position)).to eq([2, 1])
        expect(child1.position).to eq(2)
        expect(child2.position).to eq(1)

        # after reload
        [child1, child2, parent].each(&:reload)
        expect(parent.embedded_orderables.map(&:position)).to eq([2, 1])
        expect(child1.position).to eq(2)
        expect(child2.position).to eq(1)
      end

      it 'moves an embedded item to top position by symbol' do
        parent = EmbedsOrderable.first
        child1 = parent.embedded_orderables.where(position: 1).first
        child2 = parent.embedded_orderables.where(position: 2).first
        child2.move_to!(:top)

        # before reload
        expect(parent.embedded_orderables.map(&:position)).to eq([2, 1])
        expect(child1.position).to eq(2)
        expect(child2.position).to eq(1)

        # after reload
        [child1, child2, parent].each(&:reload)
        expect(parent.embedded_orderables.map(&:position)).to eq([2, 1])
        expect(child1.position).to eq(2)
        expect(child2.position).to eq(1)
      end

      it 'moves an embedded item above top position' do
        parent = EmbedsOrderable.first
        child1 = parent.embedded_orderables.where(position: 1).first
        child2 = parent.embedded_orderables.where(position: 2).first
        child2.move_to!(0)

        # before reload
        expect(parent.embedded_orderables.map(&:position)).to eq([2, 1])
        expect(child1.position).to eq(2)
        expect(child2.position).to eq(1)

        # after reload
        [child1, child2, parent].each(&:reload)
        expect(parent.embedded_orderables.map(&:position)).to eq([2, 1])
        expect(child1.position).to eq(2)
        expect(child2.position).to eq(1)
      end

      it 'moves an embedded item to middle position' do
        parent = EmbedsOrderable.last
        child1 = parent.embedded_orderables.where(position: 1).first
        child2 = parent.embedded_orderables.where(position: 2).first
        child3 = parent.embedded_orderables.where(position: 3).first
        child3.move_to!(2)

        # before reload
        expect(parent.embedded_orderables.map(&:position)).to eq([1, 3, 2])
        expect(child1.position).to eq(1)
        expect(child2.position).to eq(3)
        expect(child3.position).to eq(2)

        # after reload
        [child1, child2, child3, parent].each(&:reload)
        expect(parent.embedded_orderables.map(&:position)).to eq([1, 3, 2])
        expect(child1.position).to eq(1)
        expect(child2.position).to eq(3)
        expect(child3.position).to eq(2)
      end

      it 'moves an embedded item to bottom position' do
        parent = EmbedsOrderable.first
        child1 = parent.embedded_orderables.where(position: 1).first
        child2 = parent.embedded_orderables.where(position: 2).first
        child1.move_to!(2)

        # before reload
        expect(parent.embedded_orderables.map(&:position)).to eq([2, 1])
        expect(child1.position).to eq(2)
        expect(child2.position).to eq(1)

        # after reload
        [child1, child2, parent].each(&:reload)
        expect(parent.embedded_orderables.map(&:position)).to eq([2, 1])
        expect(child1.position).to eq(2)
        expect(child2.position).to eq(1)
      end

      it 'moves an embedded item to bottom position by symbol' do
        parent = EmbedsOrderable.first
        child1 = parent.embedded_orderables.where(position: 1).first
        child2 = parent.embedded_orderables.where(position: 2).first
        child1.move_to!(:bottom)

        # before reload
        expect(parent.embedded_orderables.map(&:position)).to eq([2, 1])
        expect(child1.position).to eq(2)
        expect(child2.position).to eq(1)

        # after reload
        [child1, child2, parent].each(&:reload)
        expect(parent.embedded_orderables.map(&:position)).to eq([2, 1])
        expect(child1.position).to eq(2)
        expect(child2.position).to eq(1)
      end

      it 'moves an embedded item below bottom position' do
        parent = EmbedsOrderable.first
        child1 = parent.embedded_orderables.where(position: 1).first
        child2 = parent.embedded_orderables.where(position: 2).first
        child1.move_to!(3)

        # before reload
        expect(parent.embedded_orderables.map(&:position)).to eq([2, 1])
        expect(child1.position).to eq(2)
        expect(child2.position).to eq(1)

        # after reload
        [child1, child2, parent].each(&:reload)
        expect(parent.embedded_orderables.map(&:position)).to eq([2, 1])
        expect(child1.position).to eq(2)
        expect(child2.position).to eq(1)
      end
    end

    context '#move_to' do
      it 'move_to moves an item returned by a query to position when saving the parent' do
        parent = EmbedsOrderable.first
        child1 = parent.embedded_orderables.where(position: 1).first
        child2 = parent.embedded_orderables.where(position: 2).first
        child1.move_to(2)

        # does not move position before saving
        expect(child1.position).to eq(1)
        expect(child2.position).to eq(2)

        parent.save!
        expect(child1.position).to eq(2)
        expect(child2.position).to eq(1)
        expect(child1.reload.position).to eq(2)
        expect(child2.reload.position).to eq(1)
      end
    end

    context '#move_to=' do
      it 'move_to= moves an item returned by a query to position when saving the parent' do
        parent = EmbedsOrderable.first
        child1 = parent.embedded_orderables.where(position: 1).first
        child2 = parent.embedded_orderables.where(position: 2).first
        child1.move_to = 2

        # does not move position before saving
        expect(child1.position).to eq(1)
        expect(child2.position).to eq(2)

        parent.save!
        expect(child1.position).to eq(2)
        expect(child2.position).to eq(1)
        expect(child1.reload.position).to eq(2)
        expect(child2.reload.position).to eq(1)
      end
    end

    context '#save! on parent' do
      let!(:parent) { EmbedsOrderable.last }
      let!(:child1) { parent.embedded_orderables.first }
      let!(:child2) { parent.embedded_orderables.second }
      let!(:child3) { parent.embedded_orderables.third }

      it 'sets existing item to top' do
        child3.position = 1
        parent.save!
        # expect(parent.embedded_orderables.map(&:position)).to eq [1, 2, 1]
        expect(parent.reload.embedded_orderables.map(&:position)).to eq [2, 3, 1]
      end

      it 'sets existing item above top' do
        child3.position = 0
        parent.save!
        # expect(parent.embedded_orderables.map(&:position)).to eq [1, 2, 0]
        expect(parent.reload.embedded_orderables.map(&:position)).to eq [2, 3, 1]
      end

      it 'sets existing item to middle' do
        child3.position = 2
        parent.save!
        # expect(parent.embedded_orderables.map(&:position)).to eq [1, 2, 2]
        expect(parent.reload.embedded_orderables.map(&:position)).to eq [1, 3, 2]
      end

      it 'sets existing item to bottom' do
        child1.position = 3
        parent.save!
        # expect(parent.embedded_orderables.map(&:position)).to eq [3, 2, 3]
        expect(parent.reload.embedded_orderables.map(&:position)).to eq [3, 1, 2]
      end

      it 'sets existing item below bottom' do
        child1.position = 4
        parent.save!
        # expect(parent.embedded_orderables.map(&:position)).to eq [4, 2, 3]
        expect(parent.reload.embedded_orderables.map(&:position)).to eq [3, 1, 2]
      end

      it 'sets existing item with nil position' do
        child2.position = nil
        parent.save!
        # expect(parent.embedded_orderables.map(&:position)).to eq [1, 4, 3]
        expect(parent.reload.embedded_orderables.map(&:position)).to eq [1, 3, 2]
      end

      it 'saves new item with position set to top' do
        child4 = parent.embedded_orderables.build
        child4.position = 1
        parent.save!
        # expect(parent.embedded_orderables.map(&:position)).to eq [2, 3, 4, 1]
        expect(parent.reload.embedded_orderables.map(&:position)).to eq [2, 3, 4, 1]
      end

      it 'saves new item with position set above top' do
        child4 = parent.embedded_orderables.build
        child4.position = 0
        parent.save!
        # expect(parent.embedded_orderables.map(&:position)).to eq [2, 3, 4, 1]
        expect(parent.reload.embedded_orderables.map(&:position)).to eq [2, 3, 4, 1]
      end

      it 'saves new item with position set to middle' do
        child4 = parent.embedded_orderables.build
        child4.position = 2
        parent.save!
        # expect(parent.embedded_orderables.map(&:position)).to eq [1, 3, 4, 2]
        expect(parent.reload.embedded_orderables.map(&:position)).to eq [1, 3, 4, 2]
      end

      it 'saves new item with position set to bottom' do
        child4 = parent.embedded_orderables.build
        child4.position = 4
        parent.save!
        # expect(parent.embedded_orderables.map(&:position)).to eq [1, 2, 3, 5]
        expect(parent.reload.embedded_orderables.map(&:position)).to eq [1, 2, 3, 4]
      end

      it 'saves new item with position set below bottom' do
        child4 = parent.embedded_orderables.build
        child4.position = 5
        parent.save!
        # expect(parent.embedded_orderables.map(&:position)).to eq [1, 2, 3, 4]
        expect(parent.reload.embedded_orderables.map(&:position)).to eq [1, 2, 3, 4]
      end

      it 'saves new item with nil position' do
        parent.embedded_orderables.build
        parent.save!
        expect(parent.reload.embedded_orderables.map(&:position)).to eq [1, 2, 3, 4]
      end
    end

    context '#save! on child' do
      let!(:parent) { EmbedsOrderable.last }
      let!(:child1) { parent.embedded_orderables.first }
      let!(:child2) { parent.embedded_orderables.second }
      let!(:child3) { parent.embedded_orderables.third }

      it 'sets existing item to top' do
        child3.position = 1
        child3.save!
        # expect(parent.embedded_orderables.map(&:position)).to eq [1, 2, 1]
        expect(parent.reload.embedded_orderables.map(&:position)).to eq [2, 3, 1]
      end

      it 'sets existing item above top' do
        child3.position = 0
        child3.save!
        # expect(parent.embedded_orderables.map(&:position)).to eq [1, 2, 0]
        expect(parent.reload.embedded_orderables.map(&:position)).to eq [2, 3, 1]
      end

      it 'sets existing item to middle' do
        child3.position = 2
        child3.save!
        # expect(parent.embedded_orderables.map(&:position)).to eq [1, 2, 2]
        expect(parent.reload.embedded_orderables.map(&:position)).to eq [1, 3, 2]
      end

      it 'sets existing item to bottom' do
        child1.position = 3
        child1.save!
        # expect(parent.embedded_orderables.map(&:position)).to eq [3, 2, 3]
        expect(parent.reload.embedded_orderables.map(&:position)).to eq [3, 1, 2]
      end

      it 'sets existing item below bottom' do
        child1.position = 4
        child1.save!
        # expect(parent.embedded_orderables.map(&:position)).to eq [4, 2, 3]
        expect(parent.reload.embedded_orderables.map(&:position)).to eq [3, 1, 2]
      end

      it 'sets existing item with nil position' do
        child2.position = nil
        child2.save!
        # expect(parent.embedded_orderables.map(&:position)).to eq [1, 4, 3]
        expect(parent.reload.embedded_orderables.map(&:position)).to eq [1, 3, 2]
      end

      it 'saves new item with position set to top' do
        child4 = parent.embedded_orderables.build
        child4.position = 1
        child4.save!
        # expect(parent.embedded_orderables.map(&:position)).to eq [2, 3, 4, 1]
        expect(parent.reload.embedded_orderables.map(&:position)).to eq [2, 3, 4, 1]
      end

      it 'saves new item with position set above top' do
        child4 = parent.embedded_orderables.build
        child4.position = 0
        child4.save!
        # expect(parent.embedded_orderables.map(&:position)).to eq [2, 3, 4, 1]
        expect(parent.reload.embedded_orderables.map(&:position)).to eq [2, 3, 4, 1]
      end

      it 'saves new item with position set to middle' do
        child4 = parent.embedded_orderables.build
        child4.position = 2
        child4.save!
        # expect(parent.embedded_orderables.map(&:position)).to eq [1, 3, 4, 2]
        expect(parent.reload.embedded_orderables.map(&:position)).to eq [1, 3, 4, 2]
      end

      it 'saves new item with position set to bottom' do
        child4 = parent.embedded_orderables.build
        child4.position = 4
        child4.save!
        # expect(parent.embedded_orderables.map(&:position)).to eq [1, 2, 3, 5]
        expect(parent.reload.embedded_orderables.map(&:position)).to eq [1, 2, 3, 4]
      end

      it 'saves new item with position set below bottom' do
        child4 = parent.embedded_orderables.build
        child4.position = 5
        child4.save!
        # expect(parent.embedded_orderables.map(&:position)).to eq [1, 2, 3, 4]
        expect(parent.reload.embedded_orderables.map(&:position)).to eq [1, 2, 3, 4]
      end

      it 'saves new item with nil position' do
        child4 = parent.embedded_orderables.build
        child4.save!
        expect(parent.reload.embedded_orderables.map(&:position)).to eq [1, 2, 3, 4]
      end
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
