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
      EmbedsOrderable.order_by(position: 1).all.map { |eo| eo.embedded_orderables.map(&:position).sort }
    end

    it 'sets proper position while creation' do
      expect(positions).to eq([[1, 2], [1, 2, 3]])
    end

    context '#move_to' do

      it 'moves an embedded item to top position' do
        parent = EmbedsOrderable.first
        emb1 = parent.embedded_orderables.where(position: 1).first
        emb2 = parent.embedded_orderables.where(position: 2).first
        emb2.move_to!(1)

        [emb1, emb2, parent].each(&:reload)
        # TODO: needs to sort order
        # expect(parent.embedded_orderables).to eq([emb2, emb1])
        expect(parent.embedded_orderables.map(&:position).sort).to eq([1, 2])
        expect(emb1.position).to eq(2)
        expect(emb2.position).to eq(1)
      end

      it 'moves an embedded item to top position by symbol' do
        parent = EmbedsOrderable.first
        emb1 = parent.embedded_orderables.where(position: 1).first
        emb2 = parent.embedded_orderables.where(position: 2).first
        emb2.move_to!(:top)

        [emb1, emb2, parent].each(&:reload)
        # TODO: needs to sort order
        # expect(parent.embedded_orderables).to eq([emb2, emb1])
        expect(parent.embedded_orderables.map(&:position).sort).to eq([1, 2])
        expect(emb1.position).to eq(2)
        expect(emb2.position).to eq(1)
      end

      it 'moves an embedded item above top position' do
        parent = EmbedsOrderable.first
        emb1 = parent.embedded_orderables.where(position: 1).first
        emb2 = parent.embedded_orderables.where(position: 2).first
        emb2.move_to!(0)

        [emb1, emb2, parent].each(&:reload)
        # TODO: needs to sort order; remove sort from position
        # expect(parent.embedded_orderables).to eq([emb2, emb1])
        expect(parent.embedded_orderables.map(&:position).sort).to eq([1, 2])
        expect(emb1.position).to eq(2)
        expect(emb2.position).to eq(1)
      end

      it 'moves an embedded item to middle position' do
        parent = EmbedsOrderable.last
        emb1 = parent.embedded_orderables.where(position: 1).first
        emb2 = parent.embedded_orderables.where(position: 2).first
        emb3 = parent.embedded_orderables.where(position: 3).first
        emb3.move_to!(2)

        [emb1, emb2, emb3, parent].each(&:reload)
        # TODO: needs to sort order
        # expect(parent.embedded_orderables).to eq([emb1, emb3, emb2])
        expect(parent.embedded_orderables.map(&:position).sort).to eq([1, 2, 3])
        expect(emb1.position).to eq(1)
        expect(emb2.position).to eq(3)
        expect(emb3.position).to eq(2)
      end

      it 'moves an embedded item to bottom position' do
        parent = EmbedsOrderable.first
        emb1 = parent.embedded_orderables.where(position: 1).first
        emb2 = parent.embedded_orderables.where(position: 2).first
        emb1.move_to!(2)

        [emb1, emb2, parent].each(&:reload)
        # TODO: needs to sort order
        # expect(parent.embedded_orderables).to eq([emb2, emb1])
        expect(parent.embedded_orderables.map(&:position).sort).to eq([1, 2])
        expect(emb1.position).to eq(2)
        expect(emb2.position).to eq(1)
      end

      it 'moves an embedded item to bottom position by symbol' do
        parent = EmbedsOrderable.first
        emb1 = parent.embedded_orderables.where(position: 1).first
        emb2 = parent.embedded_orderables.where(position: 2).first
        emb1.move_to!(:bottom)

        [emb1, emb2, parent].each(&:reload)
        # TODO: needs to sort order
        # expect(parent.embedded_orderables).to eq([emb2, emb1])
        expect(parent.embedded_orderables.map(&:position).sort).to eq([1, 2])
        expect(emb1.position).to eq(2)
        expect(emb2.position).to eq(1)
      end

      it 'moves an embedded item below bottom position' do
        parent = EmbedsOrderable.first
        emb1 = parent.embedded_orderables.where(position: 1).first
        emb2 = parent.embedded_orderables.where(position: 2).first
        emb1.move_to!(3)

        [emb1, emb2, parent].each(&:reload)
        # TODO: needs to sort order; remove sort from position
        # expect(parent.embedded_orderables).to eq([emb2, emb1])
        expect(parent.embedded_orderables.map(&:position).sort).to eq([1, 2])
        expect(emb1.position).to eq(2)
        expect(emb2.position).to eq(1)
      end
    end

    context '#save! on parent' do
      let!(:parent) { EmbedsOrderable.first }
      let!(:emb1) { parent.embedded_orderables.where(position: 1).first }
      let!(:emb2) { parent.embedded_orderables.where(position: 2).first }

      it 'saves new item with position set to top' do
        emb3 = parent.embedded_orderables.build
        emb3.position = 1
        parent.save!
        # expect(parent.embedded_orderables).to eq([emb3, emb1, emb2])
        expect(parent.reload.embedded_orderables.map(&:position)).to eq [1, 2, 3]
      end

      it 'saves new item with position set above top' do
        emb3 = parent.embedded_orderables.build
        emb3.position = 2
        parent.save!
        # expect(parent.embedded_orderables).to eq([emb3, emb1, emb2])
        expect(parent.reload.embedded_orderables.map(&:position)).to eq [1, 2, 3]
      end

      it 'saves new item with position set to middle' do
        emb3 = parent.embedded_orderables.build
        emb3.position = 2
        parent.save!
        # expect(parent.embedded_orderables).to eq([emb1, emb3, emb2])
        expect(parent.reload.embedded_orderables.map(&:position)).to eq [1, 2, 3]
      end

      it 'saves new item with position set to bottom' do
        emb3 = parent.embedded_orderables.build
        emb3.position = 3
        parent.save!
        # expect(parent.embedded_orderables).to eq([emb1, emb2, emb3])
        expect(parent.reload.embedded_orderables.map(&:position)).to eq [1, 2, 3]
      end

      it 'saves new item with position set below bottom' do
        emb3 = parent.embedded_orderables.build
        emb3.position = 4
        parent.save!
        # expect(parent.embedded_orderables).to eq([emb1, emb2, emb3])
        expect(parent.reload.embedded_orderables.map(&:position)).to eq [1, 2, 3]
      end

      it 'saves new item with nil position' do
        parent.embedded_orderables.build
        parent.save!
        # expect(parent.embedded_orderables).to eq([emb1, emb2, emb3])
        expect(parent.reload.embedded_orderables.map(&:position)).to eq [1, 2, 3]
      end
    end

    context '#save! on child' do
      let!(:parent) { EmbedsOrderable.first }
      let!(:emb1) { parent.embedded_orderables.where(position: 1).first }
      let!(:emb2) { parent.embedded_orderables.where(position: 2).first }

      it 'saves new item with position set to top' do
        emb3 = parent.embedded_orderables.build
        emb3.position = 1
        emb3.save!
        # expect(parent.embedded_orderables).to eq([emb3, emb1, emb2])
        expect(parent.reload.embedded_orderables.map(&:position)).to eq [1, 2, 3]
      end

      it 'saves new item with position set above top' do
        emb3 = parent.embedded_orderables.build
        emb3.position = 2
        emb3.save!
        # expect(parent.embedded_orderables).to eq([emb3, emb1, emb2])
        expect(parent.reload.embedded_orderables.map(&:position)).to eq [1, 2, 3]
      end

      it 'saves new item with position set to middle' do
        emb3 = parent.embedded_orderables.build
        emb3.position = 2
        emb3.save!
        # expect(parent.embedded_orderables).to eq([emb1, emb3, emb2])
        expect(parent.reload.embedded_orderables.map(&:position)).to eq [1, 2, 3]
      end

      it 'saves new item with position set to bottom' do
        emb3 = parent.embedded_orderables.build
        emb3.position = 3
        emb3.save!
        # expect(parent.embedded_orderables).to eq([emb1, emb2, emb3])
        expect(parent.reload.embedded_orderables.map(&:position)).to eq [1, 2, 3]
      end

      it 'saves new item with position set below bottom' do
        emb3 = parent.embedded_orderables.build
        emb3.position = 4
        emb3.save!
        # expect(parent.embedded_orderables).to eq([emb1, emb2, emb3])
        expect(parent.reload.embedded_orderables.map(&:position)).to eq [1, 2, 3]
      end

      it 'saves new item with nil position' do
        emb3 = parent.embedded_orderables.build
        emb3.save!
        # expect(parent.embedded_orderables).to eq([emb1, emb2, emb3])
        expect(parent.reload.embedded_orderables.map(&:position)).to eq [1, 2, 3]
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
