require 'spec_helper'

describe MultipleFieldsOrderable do

  shared_examples_for 'multiple_fields_orderable' do

    before :each do
      5.times { MultipleFieldsOrderable.create! }
    end

    context 'default orderable' do
      let(:serial_nos) { MultipleFieldsOrderable.pluck(:serial_no).sort }

      describe 'inserting' do
        let(:newbie) { MultipleFieldsOrderable.create! }

        before { @position = newbie.position }

        it 'top' do
          newbie.move_to! :top
          expect(serial_nos).to eq([1, 2, 3, 4, 5, 6])
          expect(newbie.serial_no).to eq(1)
          expect(newbie.position).to eq(@position)
        end

        it 'bottom' do
          newbie.move_to! :bottom
          expect(serial_nos).to eq([1, 2, 3, 4, 5, 6])
          expect(newbie.serial_no).to eq(6)
          expect(newbie.position).to eq(@position)
        end

        it 'middle' do
          newbie.move_to! 4
          expect(serial_nos).to eq([1, 2, 3, 4, 5, 6])
          expect(newbie.serial_no).to eq(4)
          expect(newbie.position).to eq(@position)
        end
      end

      describe 'movement' do
        it 'higher from top' do
          record = MultipleFieldsOrderable.where(serial_no: 1).first
          position = record.position
          record.move_higher!
          expect(serial_nos).to eq([1, 2, 3, 4, 5])
          expect(record.serial_no).to eq(1)
          expect(record.position).to eq(position)
        end

        it 'higher from bottom' do
          record = MultipleFieldsOrderable.where(serial_no: 5).first
          position = record.position
          record.move_higher!
          expect(serial_nos).to eq([1, 2, 3, 4, 5])
          expect(record.serial_no).to eq(4)
          expect(record.position).to eq(position)
        end

        it 'higher from middle' do
          record = MultipleFieldsOrderable.where(serial_no: 3).first
          position = record.position
          record.move_higher!
          expect(serial_nos).to eq([1, 2, 3, 4, 5])
          expect(record.serial_no).to eq(2)
          expect(record.position).to eq(position)
        end

        it 'lower from top' do
          record = MultipleFieldsOrderable.where(serial_no: 1).first
          position = record.position
          record.move_lower!
          expect(serial_nos).to eq([1, 2, 3, 4, 5])
          expect(record.serial_no).to eq(2)
          expect(record.position).to eq(position)
        end

        it 'lower from bottom' do
          record = MultipleFieldsOrderable.where(serial_no: 5).first
          position = record.position
          record.move_lower!
          expect(serial_nos).to eq([1, 2, 3, 4, 5])
          expect(record.serial_no).to eq(5)
          expect(record.position).to eq(position)
        end

        it 'lower from middle' do
          record = MultipleFieldsOrderable.where(serial_no: 3).first
          position = record.position
          record.move_lower!
          expect(serial_nos).to eq([1, 2, 3, 4, 5])
          expect(record.serial_no).to eq(4)
          expect(record.position).to eq(position)
        end
      end

      describe 'utility methods' do
        before do
          @record1 = MultipleFieldsOrderable.where(serial_no: 1).first
          @record2 = MultipleFieldsOrderable.where(serial_no: 2).first
          @record3 = MultipleFieldsOrderable.where(serial_no: 3).first
          @record4 = MultipleFieldsOrderable.where(serial_no: 4).first
          @record5 = MultipleFieldsOrderable.where(serial_no: 5).first
        end

        it 'should return the lower/higher item on the list for next_item/previous_item' do
          expect(@record1.next_item).to eq(@record2)
          expect(@record3.next_item).to eq(@record4)
          expect(@record5.next_item).to eq(nil)
          expect(@record1.prev_item).to eq(nil)
          expect(@record3.prev_item).to eq(@record2)
          expect(@record5.prev_item).to eq(@record4)
        end

        it 'should return a collection of items lower/higher on the list for next_items/previous_items' do
          expect(@record1.next_items.to_a).to eq([@record2, @record3, @record4, @record5])
          expect(@record3.next_items.to_a).to eq([@record4, @record5])
          expect(@record5.next_items.to_a).to eq([])
          expect(@record1.previous_items.to_a).to eq([])
          expect(@record3.previous_items.to_a).to eq([@record1, @record2])
          expect(@record5.previous_items.to_a).to eq([@record1, @record2, @record3, @record4])
        end
      end
    end

    context 'serial_no orderable' do
      let(:serial_nos) { MultipleFieldsOrderable.pluck(:serial_no).sort }

      it 'should have proper serial_no field' do
        expect(MultipleFieldsOrderable.fields.key?('serial_no')).to be true
        expect(MultipleFieldsOrderable.fields['serial_no'].options[:type]).to eq(Integer)
      end

      it 'should have index on serial_no field' do
        expect(MultipleFieldsOrderable.index_specifications.detect { |spec| spec.key == { serial_no: 1 } }).not_to be_nil
      end

      it 'should have a orderable base of 1' do
        expect(MultipleFieldsOrderable.first.orderable_top(:serial_no)).to eq(1)
      end

      it 'should set proper position while creation' do
        expect(serial_nos).to eq([1, 2, 3, 4, 5])
      end

      describe 'removement' do
        it 'top' do
          MultipleFieldsOrderable.where(serial_no: 1).destroy
          expect(serial_nos).to eq([1, 2, 3, 4])
        end

        it 'bottom' do
          MultipleFieldsOrderable.where(serial_no: 5).destroy
          expect(serial_nos).to eq([1, 2, 3, 4])
        end

        it 'middle' do
          MultipleFieldsOrderable.where(serial_no: 3).destroy
          expect(serial_nos).to eq([1, 2, 3, 4])
        end
      end

      describe 'inserting' do
        let(:newbie) { MultipleFieldsOrderable.create! }

        before { @position = newbie.position }

        it 'top' do
          newbie.move_serial_no_to! :top
          expect(serial_nos).to eq([1, 2, 3, 4, 5, 6])
          expect(newbie.serial_no).to eq(1)
          expect(newbie.position).to eq(@position)
        end

        it 'bottom' do
          newbie.move_serial_no_to! :bottom
          expect(serial_nos).to eq([1, 2, 3, 4, 5, 6])
          expect(newbie.serial_no).to eq(6)
          expect(newbie.position).to eq(@position)
        end

        it 'middle' do
          newbie.move_serial_no_to! 4
          expect(serial_nos).to eq([1, 2, 3, 4, 5, 6])
          expect(newbie.serial_no).to eq(4)
          expect(newbie.position).to eq(@position)
        end
      end

      describe 'movement' do
        it 'higher from top' do
          record = MultipleFieldsOrderable.where(serial_no: 1).first
          position = record.position
          record.move_serial_no_higher!
          expect(serial_nos).to eq([1, 2, 3, 4, 5])
          expect(record.serial_no).to eq(1)
          expect(record.position).to eq(position)
        end

        it 'higher from bottom' do
          record = MultipleFieldsOrderable.where(serial_no: 5).first
          position = record.position
          record.move_serial_no_higher!
          expect(serial_nos).to eq([1, 2, 3, 4, 5])
          expect(record.serial_no).to eq(4)
          expect(record.position).to eq(position)
        end

        it 'higher from middle' do
          record = MultipleFieldsOrderable.where(serial_no: 3).first
          position = record.position
          record.move_serial_no_higher!
          expect(serial_nos).to eq([1, 2, 3, 4, 5])
          expect(record.serial_no).to eq(2)
          expect(record.position).to eq(position)
        end

        it 'lower from top' do
          record = MultipleFieldsOrderable.where(serial_no: 1).first
          position = record.position
          record.move_serial_no_lower!
          expect(serial_nos).to eq([1, 2, 3, 4, 5])
          expect(record.serial_no).to eq(2)
          expect(record.position).to eq(position)
        end

        it 'lower from bottom' do
          record = MultipleFieldsOrderable.where(serial_no: 5).first
          position = record.position
          record.move_serial_no_lower!
          expect(serial_nos).to eq([1, 2, 3, 4, 5])
          expect(record.serial_no).to eq(5)
          expect(record.position).to eq(position)
        end

        it 'lower from middle' do
          record = MultipleFieldsOrderable.where(serial_no: 3).first
          position = record.position
          record.move_serial_no_lower!
          expect(serial_nos).to eq([1, 2, 3, 4, 5])
          expect(record.serial_no).to eq(4)
          expect(record.position).to eq(position)
        end
      end

      describe 'utility methods' do
        before do
          @record1 = MultipleFieldsOrderable.where(serial_no: 1).first
          @record2 = MultipleFieldsOrderable.where(serial_no: 2).first
          @record3 = MultipleFieldsOrderable.where(serial_no: 3).first
          @record4 = MultipleFieldsOrderable.where(serial_no: 4).first
          @record5 = MultipleFieldsOrderable.where(serial_no: 5).first
        end

        it 'should return the lower/higher item on the list for next_item/previous_item' do
          expect(@record1.next_serial_no_item).to eq(@record2)
          expect(@record3.next_serial_no_item).to eq(@record4)
          expect(@record5.next_serial_no_item).to eq(nil)
          expect(@record1.prev_serial_no_item).to eq(nil)
          expect(@record3.prev_serial_no_item).to eq(@record2)
          expect(@record5.prev_serial_no_item).to eq(@record4)
        end

        it 'should return a collection of items lower/higher on the list for next_items/previous_items' do
          expect(@record1.next_serial_no_items.to_a).to eq([@record2, @record3, @record4, @record5])
          expect(@record3.next_serial_no_items.to_a).to eq([@record4, @record5])
          expect(@record5.next_serial_no_items.to_a).to eq([])
          expect(@record1.previous_serial_no_items.to_a).to eq([])
          expect(@record3.previous_serial_no_items.to_a).to eq([@record1, @record2])
          expect(@record5.previous_serial_no_items.to_a).to eq([@record1, @record2, @record3, @record4])
        end
      end
    end

    context 'position orderable' do
      let(:positions) { MultipleFieldsOrderable.pluck(:position).sort }

      it 'should not have default position field' do
        expect(MultipleFieldsOrderable.fields).not_to have_key('position')
      end

      it 'should have custom pos field' do
        expect(MultipleFieldsOrderable.fields).to have_key('pos')
        expect(MultipleFieldsOrderable.fields['pos'].options[:type]).to eq(Integer)
      end

      it 'should have index on position field' do
        expect(MultipleFieldsOrderable.index_specifications.detect { |spec| spec.key == { position: 1 } }).to be_nil
      end

      it 'should have a orderable base of 0' do
        expect(MultipleFieldsOrderable.first.orderable_top(:position)).to eq(0)
      end

      it 'should set proper position while creation' do
        expect(positions).to eq([0, 1, 2, 3, 4])
      end

      describe 'removement' do
        it 'top' do
          MultipleFieldsOrderable.where(pos: 1).destroy
          expect(positions).to eq([0, 1, 2, 3])
        end

        it 'bottom' do
          MultipleFieldsOrderable.where(pos: 4).destroy
          expect(positions).to eq([0, 1, 2, 3])
        end

        it 'middle' do
          MultipleFieldsOrderable.where(pos: 3).destroy
          expect(positions).to eq([0, 1, 2, 3])
        end
      end

      describe 'inserting' do
        let(:newbie) { MultipleFieldsOrderable.create! }

        before { @serial_no = newbie.serial_no }

        it 'top' do
          newbie.move_position_to! :top
          expect(positions).to eq([0, 1, 2, 3, 4, 5])
          expect(newbie.position).to eq(0)
          expect(newbie.serial_no).to eq(@serial_no)
        end

        it 'bottom' do
          newbie.move_position_to! :bottom
          expect(positions).to eq([0, 1, 2, 3, 4, 5])
          expect(newbie.position).to eq(5)
          expect(newbie.serial_no).to eq(@serial_no)
        end

        it 'middle' do
          newbie.move_position_to! 4
          expect(positions).to eq([0, 1, 2, 3, 4, 5])
          expect(newbie.position).to eq(4)
          expect(newbie.serial_no).to eq(@serial_no)
        end
      end

      describe 'movement' do
        it 'higher from top' do
          record = MultipleFieldsOrderable.where(pos: 0).first
          position = record.serial_no
          record.move_position_higher!
          expect(positions).to eq([0, 1, 2, 3, 4])
          expect(record.position).to eq(0)
          expect(record.serial_no).to eq(position)
        end

        it 'higher from bottom' do
          record = MultipleFieldsOrderable.where(pos: 4).first
          position = record.serial_no
          record.move_position_higher!
          expect(positions).to eq([0, 1, 2, 3, 4])
          expect(record.position).to eq(3)
          expect(record.serial_no).to eq(position)
        end

        it 'higher from middle' do
          record = MultipleFieldsOrderable.where(pos: 3).first
          position = record.serial_no
          record.move_position_higher!
          expect(positions).to eq([0, 1, 2, 3, 4])
          expect(record.position).to eq(2)
          expect(record.serial_no).to eq(position)
        end

        it 'lower from top' do
          record = MultipleFieldsOrderable.where(pos: 0).first
          position = record.serial_no
          record.move_position_lower!
          expect(positions).to eq([0, 1, 2, 3, 4])
          expect(record.position).to eq(1)
          expect(record.serial_no).to eq(position)
        end

        it 'lower from bottom' do
          record = MultipleFieldsOrderable.where(pos: 4).first
          position = record.serial_no
          record.move_position_lower!
          expect(positions).to eq([0, 1, 2, 3, 4])
          expect(record.position).to eq(4)
          expect(record.serial_no).to eq(position)
        end

        it 'lower from middle' do
          record = MultipleFieldsOrderable.where(pos: 3).first
          position = record.serial_no
          record.move_position_lower!
          expect(positions).to eq([0, 1, 2, 3, 4])
          expect(record.position).to eq(4)
          expect(record.serial_no).to eq(position)
        end
      end

      describe 'utility methods' do
        before do
          @record1 = MultipleFieldsOrderable.where(pos: 0).first
          @record2 = MultipleFieldsOrderable.where(pos: 1).first
          @record3 = MultipleFieldsOrderable.where(pos: 2).first
          @record4 = MultipleFieldsOrderable.where(pos: 3).first
          @record5 = MultipleFieldsOrderable.where(pos: 4).first
        end

        it 'should return the lower/higher item on the list for next_item/previous_item' do
          expect(@record1.next_position_item).to eq(@record2)
          expect(@record3.next_position_item).to eq(@record4)
          expect(@record5.next_position_item).to eq(nil)
          expect(@record1.prev_position_item).to eq(nil)
          expect(@record3.prev_position_item).to eq(@record2)
          expect(@record5.prev_position_item).to eq(@record4)
        end

        it 'should return a collection of items lower/higher on the list for next_items/previous_items' do
          expect(@record1.next_position_items.to_a).to eq([@record2, @record3, @record4, @record5])
          expect(@record3.next_position_items.to_a).to eq([@record4, @record5])
          expect(@record5.next_position_items.to_a).to eq([])
          expect(@record1.previous_position_items.to_a).to eq([])
          expect(@record3.previous_position_items.to_a).to eq([@record1, @record2])
          expect(@record5.previous_position_items.to_a).to eq([@record1, @record2, @record3, @record4])
        end
      end
    end

    context 'group_count orderable' do
      before :each do
        MultipleFieldsOrderable.delete_all
        2.times { MultipleFieldsOrderable.create! group_id: 1 }
        3.times { MultipleFieldsOrderable.create! group_id: 2 }
      end

      let(:all_groups) { MultipleFieldsOrderable.order_by([:group_id, :asc], [:groups, :asc]).map(&:groups) }

      it 'should set proper position while creation' do
        expect(all_groups).to eq([1, 2, 1, 2, 3])
      end

      describe 'removement' do
        it 'top' do
          MultipleFieldsOrderable.where(groups: 1, group_id: 1).destroy
          expect(all_groups).to eq([1, 1, 2, 3])
        end

        it 'bottom' do
          MultipleFieldsOrderable.where(groups: 3, group_id: 2).destroy
          expect(all_groups).to eq([1, 2, 1, 2])
        end

        it 'middle' do
          MultipleFieldsOrderable.where(groups: 2, group_id: 2).destroy
          expect(all_groups).to eq([1, 2, 1, 2])
        end
      end

      describe 'inserting' do
        it 'top' do
          newbie = MultipleFieldsOrderable.create! group_id: 1
          newbie.move_groups_to! :top
          expect(all_groups).to eq([1, 2, 3, 1, 2, 3])
          expect(newbie.groups).to eq(1)
        end

        it 'bottom' do
          newbie = MultipleFieldsOrderable.create! group_id: 2
          newbie.move_groups_to! :bottom
          expect(all_groups).to eq([1, 2, 1, 2, 3, 4])
          expect(newbie.groups).to eq(4)
        end

        it 'middle' do
          newbie = MultipleFieldsOrderable.create! group_id: 2
          newbie.move_groups_to! 2
          expect(all_groups).to eq([1, 2, 1, 2, 3, 4])
          expect(newbie.groups).to eq(2)
        end
      end

      describe 'scope movement' do
        let(:record) { MultipleFieldsOrderable.where(group_id: 2, groups: 2).first }

        it 'to a new scope group' do
          record.update_attributes group_id: 3
          expect(all_groups).to eq([1, 2, 1, 2, 1])
          expect(record.groups).to eq(1)
        end

        context 'when moving to an existing scope group' do
          it 'without a position' do
            record.update_attributes group_id: 1
            expect(all_groups).to eq([1, 2, 3, 1, 2])
            expect(record.reload.groups).to eq(3)
          end

          it 'with symbol position' do
            record.update_attributes group_id: 1
            record.move_groups_to! :top
            expect(all_groups).to eq([1, 2, 3, 1, 2])
            expect(record.reload.groups).to eq(1)
          end

          it 'with point position' do
            record.update_attributes group_id: 1
            record.move_groups_to! 2
            expect(all_groups).to eq([1, 2, 3, 1, 2])
            expect(record.reload.groups).to eq(2)
          end
        end
      end

      describe 'utility methods' do
        before do
          @record1 = MultipleFieldsOrderable.where(group_id: 2, groups: 1).first
          @record2 = MultipleFieldsOrderable.where(group_id: 2, groups: 2).first
          @record3 = MultipleFieldsOrderable.where(group_id: 2, groups: 3).first
          @record4 = MultipleFieldsOrderable.where(group_id: 1, groups: 1).first
          @record5 = MultipleFieldsOrderable.where(group_id: 1, groups: 2).first
        end

        it 'should return the lower/higher item on the list for next_item/previous_item' do
          expect(@record1.next_groups_item).to eq(@record2)
          expect(@record4.next_groups_item).to eq(@record5)
          expect(@record3.next_groups_item).to eq(nil)
          expect(@record1.prev_groups_item).to eq(nil)
          expect(@record3.prev_groups_item).to eq(@record2)
          expect(@record5.prev_groups_item).to eq(@record4)
        end

        it 'should return a collection of items lower/higher on the list for next_items/previous_items' do
          expect(@record1.next_groups_items.to_a).to eq([@record2, @record3])
          expect(@record3.next_groups_items.to_a).to eq([])
          expect(@record4.next_groups_items.to_a).to eq([@record5])
          expect(@record1.previous_groups_items.to_a).to eq([])
          expect(@record3.previous_groups_items.to_a).to eq([@record1, @record2])
          expect(@record5.previous_groups_items.to_a).to eq([@record4])
        end
      end
    end
  end

  context 'with transactions' do
    enable_transactions!

    it_behaves_like 'multiple_fields_orderable'
  end

  context 'without transactions' do
    disable_transactions!

    it_behaves_like 'multiple_fields_orderable'
  end
end
