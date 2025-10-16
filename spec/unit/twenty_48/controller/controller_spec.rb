# frozen_string_literal: true

require 'twenty_48/controller'

describe Twenty48::Controller do
  let(:disable_cell_generation) { false }
  let(:controller) { Twenty48::Controller.new initial_state: board_state, disable_cell_generation: disable_cell_generation }

  describe 'generating new cell after move' do
    let(:board_state) { Array.new(Twenty48::Controller::TOTAL_CELL_COUNT) }

    before { stub_const 'Twenty48::Controller::GENERATED_VALUES', [2] }

    it 'generates a "2" || "4" after move' do
      expect { controller.process('↑') }.to change { controller.board_state.compact.empty? }.to false
      expect(controller.board_state.compact.first).to eq 2
    end
  end

  describe 'end game detection' do
    #  - - - -
    #  - - - -
    #  - - - -
    #  - - - -
    context 'vacant cell exists' do
      let(:board_state) do
        [
          [nil, nil, nil, nil],
          [nil, nil, nil, nil],
          [nil, nil, nil, nil],
          [nil, nil, nil, nil],
        ].flatten
      end

      it 'does not detect endgame' do
        expect(controller.status).to eq Twenty48::Controller::PLAYING
      end
    end

    #  2 2 2 2
    #  2 - 2 2
    #  2 2 2 2
    #  2 2 2 2
    context 'vacant cell exists' do
      let(:board_state) do
        [
          [2, 2, 2, 2],
          [2, nil, 2, 2],
          [2, 2, 2, 2],
          [2, 2, 2, 2],
        ].flatten
      end

      it 'does not detect endgame' do
        expect(controller.status).to eq Twenty48::Controller::PLAYING
      end
    end

    #  2 4 2 2 <-
    #  4 2 4 8
    #  2 4 2 4
    #  4 2 4 2
    context 'all cells filled but horizontal merge candidates exist' do
      let(:board_state) do
        [
          [2, 4, 2, 2],
          [4, 2, 4, 2],
          [2, 4, 2, 4],
          [4, 2, 4, 2],
        ].flatten
      end

      it 'does not detect endgame' do
        expect(controller.status).to eq Twenty48::Controller::PLAYING
      end
    end

    #  2 4 8 2 <-
    #  4 2 4 2
    #  2 4 2 4
    #  4 2 4 2
    context 'all cells filled but vertical merge candidates exist' do
      let(:board_state) do
        [
          [2, 4, 2, 2],
          [4, 2, 4, 2],
          [2, 4, 2, 4],
          [4, 2, 4, 2],
        ].flatten
      end

      it 'does not detect endgame' do
        expect(controller.status).to eq Twenty48::Controller::PLAYING
      end
    end

    #  2 4 2 4
    #  4 2 4 2
    #  2 4 2 4
    #  4 2 4 2
    context 'all cells filled with no merge candidates exist' do
      let(:board_state) do
        [
          [2, 4, 2, 4],
          [4, 2, 4, 2],
          [2, 4, 2, 4],
          [4, 2, 4, 2],
        ].flatten
      end

      it 'detects defeat' do
        expect(controller.status).to eq Twenty48::Controller::DEFEAT
      end
    end

    #  2 4 2 4
    #  4 2 4 2
    #  2 4 2 4
    #  4 2 4 2048
    context 'value >= 2048 exists on board' do
      let(:board_state) do
        [
          [2, 4, 2, 4],
          [4, 2, 4, 2],
          [2, 4, 2, 4],
          [4, 2, 4, 2048],
        ].flatten
      end

      it 'detects win' do
        expect(controller.status).to eq Twenty48::Controller::VICTORY
      end
    end
  end

  describe 'merge left' do
    let(:disable_cell_generation) { true }

    subject(:merge_left) { controller.process('←') }

    # requirements example
    #  - 8 2 2
    #  4 2 - 2
    #  - - - -
    #  - - - 2
    context 'requirements example' do
      let(:board_state) do
        [
          [nil, 8, 2, 2],
          [4, 2, nil, 2],
          [nil, nil, nil, nil],
          [nil, nil, nil, 2],
        ].flatten
      end

      it 'merges successfully' do
        expect { merge_left }.to change { controller.board_state }.to(
          [
            [8, 4, nil, nil],
            [4, 4, nil, nil],
            [nil, nil, nil, nil],
            [2, nil, nil, nil],
          ].flatten
        )
      end
    end

    #  - - - -
    #  2 2 2 2
    #  - - - -
    #  - - - -
    context 'row is full' do
      let(:board_state) do
        [
          [nil, nil, nil, nil],
          [2, 2, 2, 2],
          [nil, nil, nil, nil],
          [nil, nil, nil, nil],
        ].flatten
      end

      it 'merges successfully' do
        expect { merge_left }.to change { controller.board_state }.to(
          [
            [nil, nil, nil, nil],
            [4, 4, nil, nil],
            [nil, nil, nil, nil],
            [nil, nil, nil, nil],
          ].flatten
        )
      end
    end

    #  - - - -
    #  2 - - -
    #  - - - -
    #  - - - -
    context 'value in leftmost cell' do
      let(:board_state) do
        [
          [nil, nil, nil, nil],
          [2, nil, nil, nil],
          [nil, nil, nil, nil],
          [nil, nil, nil, nil],
        ].flatten
      end

      it 'does nothing' do
        expect { merge_left }.to_not change { controller.board_state }
      end
    end

    #  - - - -
    #  - - - 2
    #  - - - -
    #  - - - -
    context 'value in rightmost cell' do
      let(:board_state) do
        [
          [nil, nil, nil, nil],
          [nil, nil, nil, 2],
          [nil, nil, nil, nil],
          [nil, nil, nil, nil],
        ].flatten
      end

      it 'moves value to left' do
        expect { merge_left }.to change { controller.board_state }.to(
          [
            [nil, nil, nil, nil],
            [2, nil, nil, nil],
            [nil, nil, nil, nil],
            [nil, nil, nil, nil],
          ].flatten
        )
      end
    end

    #  - - - -
    #  2 4 8 16
    #  - - - -
    #  - - - -
    context 'unmerge-able row is full' do
      let(:board_state) do
        [
          [nil, nil, nil, nil],
          [2, 4, 6, 8],
          [nil, nil, nil, nil],
          [nil, nil, nil, nil],
        ].flatten
      end

      it 'does nothing' do
        expect { merge_left }.to_not change { controller.board_state }
      end
    end

    #  - - - -
    #  8 - 8 -
    #  - - - -
    #  - - - -
    context 'merge candidates' do
      let(:board_state) do
        [
          [nil, nil, nil, nil],
          [8, nil, 8, nil],
          [nil, nil, nil, nil],
          [nil, nil, nil, nil],
        ].flatten
      end

      it 'merges successfully' do
        expect { merge_left }.to change { controller.board_state }.to(
          [
            [nil, nil, nil, nil],
            [16, nil, nil, nil],
            [nil, nil, nil, nil],
            [nil, nil, nil, nil],
          ].flatten
        )
      end
    end

    #  - - - -
    #  - 2 - 2
    #  - - - -
    #  - - - -
    context 'merge candidates' do
      let(:board_state) do
        [
          [nil, nil, nil, nil],
          [nil, 2, nil, 2],
          [nil, nil, nil, nil],
          [nil, nil, nil, nil],
        ].flatten
      end

      it 'merges successfully' do
        expect { merge_left }.to change { controller.board_state }.to(
          [
            [nil, nil, nil, nil],
            [4, nil, nil, nil],
            [nil, nil, nil, nil],
            [nil, nil, nil, nil],
          ].flatten
        )
      end
    end

    #  - - 2 - -
    #  2 - 2 - -
    #  - - 2 - -
    #  - - 2 - -
    context 'merge candidates' do
      let(:board_state) do
        [
          [nil, nil, 2, nil],
          [2,   nil, 2, nil],
          [nil, nil, 2, nil],
          [nil, nil, 2, nil],
        ].flatten
      end

      it 'merges successfully' do
        expect { merge_left }.to change { controller.board_state }.to(
          [
            [2, nil, nil, nil],
            [4, nil, nil, nil],
            [2, nil, nil, nil],
            [2, nil, nil, nil],
          ].flatten
        )
      end
    end

    #  - - - - -
    #  2 8 2 - -
    #  - - - - -
    #  - - - - -
    context 'merge candidates' do
      let(:board_state) do
        [
          [nil, nil, nil, nil],
          [2,   8,   2, nil],
          [nil, nil, nil, nil],
          [nil, nil, nil, nil],
        ].flatten
      end

      it 'does nothing' do
        expect { merge_left }.to_not change { controller.board_state }
      end
    end
  end

  describe 'merge right' do
    let(:disable_cell_generation) { true }

    subject(:merge_right) { controller.process('→') }


    # requirements example
    #  - 8 2 2
    #  4 2 - 2
    #  - - - -
    #  - - - 2
    context 'requirements example' do
      let(:board_state) do
        [
          [nil, 8, 2, 2],
          [4, 2, nil, 2],
          [nil, nil, nil, nil],
          [nil, nil, nil, 2],
        ].flatten
      end

      it 'merges successfully' do
        expect { merge_right }.to change { controller.board_state }.to(
          [
            [nil, nil, 8, 4],
            [nil, nil, 4, 4],
            [nil, nil, nil, nil],
            [nil, nil, nil, 2],
          ].flatten
        )
      end
    end

    #  - - - -
    #  2 2 2 2
    #  - - - -
    #  - - - -
    context 'row is full' do
      let(:board_state) do
        [
          [nil, nil, nil, nil],
          [2, 2, 2, 2],
          [nil, nil, nil, nil],
          [nil, nil, nil, nil],
        ].flatten
      end

      it 'merges successfully' do
        expect { merge_right }.to change { controller.board_state }.to(
          [
            [nil, nil, nil, nil],
            [nil, nil, 4, 4],
            [nil, nil, nil, nil],
            [nil, nil, nil, nil],
          ].flatten
        )
      end
    end

    #  - - - -
    #  2 - - -
    #  - - - -
    #  - - - -
    context 'value in rightmost cell' do
      let(:board_state) do
        [
          [nil, nil, nil, nil],
          [nil, nil, nil, 2],
          [nil, nil, nil, nil],
          [nil, nil, nil, nil],
        ].flatten
      end

      it 'does nothing' do
        expect { merge_right }.to_not change { controller.board_state }
      end
    end

    #  - - - -
    #  - - - 2
    #  - - - -
    #  - - - -
    context 'value in leftmost cell' do
      let(:board_state) do
        [
          [nil, nil, nil, nil],
          [2, nil, nil, nil],
          [nil, nil, nil, nil],
          [nil, nil, nil, nil],
        ].flatten
      end

      it 'moves value to right' do
        expect { merge_right }.to change { controller.board_state }.to(
          [
            [nil, nil, nil, nil],
            [nil, nil, nil, 2],
            [nil, nil, nil, nil],
            [nil, nil, nil, nil],
          ].flatten
        )
      end
    end

    #  - - - -
    #  2 4 8 16
    #  - - - -
    #  - - - -
    context 'unmerge-able row is full' do
      let(:board_state) do
        [
          [nil, nil, nil, nil],
          [2, 4, 6, 8],
          [nil, nil, nil, nil],
          [nil, nil, nil, nil],
        ].flatten
      end

      it 'does nothing' do
        expect { merge_right }.to_not change { controller.board_state }
      end
    end

    #  - - - -
    #  8 - 8 -
    #  - - - -
    #  - - - -
    context 'merge candidates' do
      let(:board_state) do
        [
          [nil, nil, nil, nil],
          [8, nil, 8, nil],
          [nil, nil, nil, nil],
          [nil, nil, nil, nil],
        ].flatten
      end

      it 'merges successfully' do
        expect { merge_right }.to change { controller.board_state }.to(
          [
            [nil, nil, nil, nil],
            [nil, nil, nil, 16],
            [nil, nil, nil, nil],
            [nil, nil, nil, nil],
          ].flatten
        )
      end
    end

    #  - - - -
    #  - 8 - 8
    #  - - - -
    #  - - - -
    context 'merge candidates' do
      let(:board_state) do
        [
          [nil, nil, nil, nil],
          [nil, 8, nil, 8],
          [nil, nil, nil, nil],
          [nil, nil, nil, nil],
        ].flatten
      end

      it 'merges successfully' do
        expect { merge_right }.to change { controller.board_state }.to(
          [
            [nil, nil, nil, nil],
            [nil, nil, nil, 16],
            [nil, nil, nil, nil],
            [nil, nil, nil, nil],
          ].flatten
        )
      end
    end

    #  - 2 - -
    #  - 2 - 2
    #  - 2 - -
    #  - 2 - -
    context 'merge candidates' do
      let(:board_state) do
        [
          [nil, 2, nil, nil],
          [nil, 2, nil, 2],
          [nil, 2, nil, nil],
          [nil, 2, nil, nil],
        ].flatten
      end

      it 'merges successfully' do
        expect { merge_right }.to change { controller.board_state }.to(
          [
            [nil, nil, nil, 2],
            [nil, nil, nil, 4],
            [nil, nil, nil, 2],
            [nil, nil, nil, 2],
          ].flatten
        )
      end
    end

    #  - - - - -
    #  2 8 2 - -
    #  - - - - -
    #  - - - - -
    context 'merge candidates' do
      let(:board_state) do
        [
          [nil, nil, nil, nil],
          [nil, 2,   8,   2],
          [nil, nil, nil, nil],
          [nil, nil, nil, nil],
        ].flatten
      end

      it 'does nothing' do
        expect { merge_right }.to_not change { controller.board_state }
      end
    end
  end

  describe 'merge up' do
    let(:disable_cell_generation) { true }

    subject(:merge_up) { controller.process('↑') }


    # requirements example
    #  - 8 2 2
    #  4 2 - 2
    #  - - - -
    #  - - - 2
    context 'requirements example' do
      let(:board_state) do
        [
          [nil, 8, 2, 2],
          [4, 2, nil, 2],
          [nil, nil, nil, nil],
          [nil, nil, nil, 2],
        ].flatten
      end

      it 'merges successfully' do
        expect { merge_up }.to change { controller.board_state }.to(
          [
            [4, 8, 2, 4],
            [nil, 2, nil, 2],
            [nil, nil, nil, nil],
            [nil, nil, nil, nil],
          ].flatten
        )
      end
    end

    #  - 2 - -
    #  - 2 - -
    #  - 2 - -
    #  - 2 - -
    context 'column is full' do
      let(:board_state) do
        [
          [nil, 2, nil, nil],
          [nil, 2, nil, nil],
          [nil, 2, nil, nil],
          [nil, 2, nil, nil],
        ].flatten
      end

      it 'merges successfully' do
        expect { merge_up }.to change { controller.board_state }.to(
          [
            [nil, 4, nil, nil],
            [nil, 4, nil, nil],
            [nil, nil, nil, nil],
            [nil, nil, nil, nil],
          ].flatten
        )
      end
    end

    #  - - 2 -
    #  - - - -
    #  - - - -
    #  - - - -
    context 'value in upmost cell' do
      let(:board_state) do
        [
          [nil, nil, 2, nil],
          [nil, nil, nil, nil],
          [nil, nil, nil, nil],
          [nil, nil, nil, nil],
        ].flatten
      end

      it 'does nothing' do
        expect { merge_up }.to_not change { controller.board_state }
      end
    end

    #  - - - -
    #  - - - -
    #  - - - -
    #  - - 2 -
    context 'value in bottomost cell' do
      let(:board_state) do
        [
          [nil, nil, nil, nil],
          [nil, nil, nil, nil],
          [nil, nil, nil, nil],
          [nil, nil, 2, nil],
        ].flatten
      end

      it 'moves value to top' do
        expect { merge_up }.to change { controller.board_state }.to(
          [
            [nil, nil, 2, nil],
            [nil, nil, nil, nil],
            [nil, nil, nil, nil],
            [nil, nil, nil, nil],
          ].flatten
        )
      end
    end

    #  - 2 - -
    #  - 4 - -
    #  - 8 - -
    #  - 16 - -
    context 'unmerge-able column is full' do
      let(:board_state) do
        [
          [nil, 2, nil, nil],
          [nil, 4, nil, nil],
          [nil, 8, nil, nil],
          [nil, 16, nil, nil],
        ].flatten
      end

      it 'does nothing' do
        expect { merge_up }.to_not change { controller.board_state }
      end
    end

    #  - 8 - -
    #  - - - -
    #  - 8 - -
    #  - - - -
    context 'merge candidates' do
      let(:board_state) do
        [
          [nil, 8, nil, nil],
          [nil, nil, nil, nil],
          [nil, 8, nil, nil],
          [nil, nil, nil, nil],
        ].flatten
      end

      it 'merges successfully' do
        expect { merge_up }.to change { controller.board_state }.to(
          [
            [nil, 16, nil, nil],
            [nil, nil, nil, nil],
            [nil, nil, nil, nil],
            [nil, nil, nil, nil],
          ].flatten
        )
      end
    end

    #  - - - -
    #  - 2 - -
    #  - - - -
    #  - 2 - -
    context 'merge candidates' do
      let(:board_state) do
        [
          [nil, nil, nil, nil],
          [nil, 2, nil, nil],
          [nil, nil, nil, nil],
          [nil, 2, nil, nil],
        ].flatten
      end

      it 'merges successfully' do
        expect { merge_up }.to change { controller.board_state }.to(
          [
            [nil, 4, nil, nil],
            [nil, nil, nil, nil],
            [nil, nil, nil, nil],
            [nil, nil, nil, nil],
          ].flatten
        )
      end
    end

    #  - 2 - -
    #  2 2 2 2
    #  - 2 - -
    #  - 2 - -
    context 'merge candidates' do
      let(:board_state) do
        [
          [nil, 2, nil, nil],
          [2,   2, 2,   2],
          [nil, 2, nil, nil],
          [nil, 2, nil, nil],
        ].flatten
      end

      it 'merges successfully' do
        expect { merge_up }.to change { controller.board_state }.to(
          [
            [2,   4,   2,   2],
            [nil, 4,   nil, nil],
            [nil, nil, nil, nil],
            [nil, nil, nil, nil],
          ].flatten
        )
      end
    end

    #  - 2 - - -
    #  - 8 - - -
    #  - 2 - - -
    #  - - - - -
    context 'merge candidates' do
      let(:board_state) do
        [
          [nil, 2,   nil, nil],
          [nil, 8,   nil, nil],
          [nil, 2,   nil, nil],
          [nil, nil, nil, nil],
        ].flatten
      end

      it 'does nothing' do
        expect { merge_up }.to_not change { controller.board_state }
      end
    end
  end

  describe 'merge down' do
    let(:disable_cell_generation) { true }

    subject(:merge_down) { controller.process('↓') }


    # requirements example
    #  - 8 2 2
    #  4 2 - 2
    #  - - - -
    #  - - - 2
    context 'requirements example' do
      let(:board_state) do
        [
          [nil, 8,   2,   2],
          [4,   2,   nil, 2],
          [nil, nil, nil, nil],
          [nil, nil, nil, 2],
        ].flatten
      end

      it 'merges successfully' do
        expect { merge_down }.to change { controller.board_state }.to(
          [
            [nil, nil, nil, nil],
            [nil, nil, nil, nil],
            [nil, 8,   nil, 2],
            [4,   2,   2,   4],
          ].flatten
        )
      end
    end

    #  - 2 - -
    #  - 2 - -
    #  - 2 - -
    #  - 2 - -
    context 'column is full' do
      let(:board_state) do
        [
          [nil, 2, nil, nil],
          [nil, 2, nil, nil],
          [nil, 2, nil, nil],
          [nil, 2, nil, nil],
        ].flatten
      end

      it 'merges successfully' do
        expect { merge_down }.to change { controller.board_state }.to(
          [
            [nil, nil, nil, nil],
            [nil, nil, nil, nil],
            [nil, 4, nil, nil],
            [nil, 4, nil, nil],
          ].flatten
        )
      end
    end

    #  - - 2 -
    #  - - - -
    #  - - - -
    #  - - - -
    context 'value in upmost cell' do
      let(:board_state) do
        [
          [nil, nil, nil, nil],
          [nil, nil, nil, nil],
          [nil, nil, nil, nil],
          [nil, nil, 2, nil],
        ].flatten
      end

      it 'does nothing' do
        expect { merge_down }.to_not change { controller.board_state }
      end
    end

    #  - - 2 -
    #  - - - -
    #  - - - -
    #  - - - -
    context 'value in topmost cell' do
      let(:board_state) do
        [
          [nil, nil, 2, nil],
          [nil, nil, nil, nil],
          [nil, nil, nil, nil],
          [nil, nil, nil, nil],
        ].flatten
      end

      it 'moves value to bottom' do
        expect { merge_down }.to change { controller.board_state }.to(
          [
            [nil, nil, nil, nil],
            [nil, nil, nil, nil],
            [nil, nil, nil, nil],
            [nil, nil, 2, nil],
          ].flatten
        )
      end
    end

    #  - 2 - -
    #  - 4 - -
    #  - 8 - -
    #  - 16 - -
    context 'unmerge-able column is full' do
      let(:board_state) do
        [
          [nil, 2, nil, nil],
          [nil, 4, nil, nil],
          [nil, 8, nil, nil],
          [nil, 16, nil, nil],
        ].flatten
      end

      it 'does nothing' do
        expect { merge_down }.to_not change { controller.board_state }
      end
    end

    #  - 8 - -
    #  - - - -
    #  - 8 - -
    #  - - - -
    context 'merge candidates' do
      let(:board_state) do
        [
          [nil, 8, nil, nil],
          [nil, nil, nil, nil],
          [nil, 8, nil, nil],
          [nil, nil, nil, nil],
        ].flatten
      end

      it 'merges successfully' do
        expect { merge_down }.to change { controller.board_state }.to(
          [
            [nil, nil, nil, nil],
            [nil, nil, nil, nil],
            [nil, nil, nil, nil],
            [nil, 16, nil, nil],
          ].flatten
        )
      end
    end

    #  - - - -
    #  - 2 - -
    #  - - - -
    #  - 2 - -
    context 'merge candidates' do
      let(:board_state) do
        [
          [nil, nil, nil, nil],
          [nil, 2, nil, nil],
          [nil, nil, nil, nil],
          [nil, 2, nil, nil],
        ].flatten
      end

      it 'merges successfully' do
        expect { merge_down }.to change { controller.board_state }.to(
          [
            [nil, nil, nil, nil],
            [nil, nil, nil, nil],
            [nil, nil, nil, nil],
            [nil, 4, nil, nil],
          ].flatten
        )
      end
    end

    #  - 2 - -
    #  2 2 2 2
    #  - 2 - -
    #  - 2 - -
    context 'merge candidates' do
      let(:board_state) do
        [
          [nil, 2, nil, nil],
          [2,   2, 2,   2],
          [nil, 2, nil, nil],
          [nil, 2, nil, nil],
        ].flatten
      end

      it 'merges successfully' do
        expect { merge_down }.to change { controller.board_state }.to(
          [
            [nil, nil, nil, nil],
            [nil, nil, nil, nil],
            [nil, 4,   nil, nil],
            [2,   4,   2,   2],
          ].flatten
        )
      end
    end

    #  - - - - -
    #  - 2 - - -
    #  - 8 - - -
    #  - 2 - - -
    context 'merge candidates' do
      let(:board_state) do
        [
          [nil, nil, nil, nil],
          [nil, 2,   nil, nil],
          [nil, 8, nil, nil],
          [nil, 2, nil, nil],
        ].flatten
      end

      it 'does nothing' do
        expect { merge_down }.to_not change { controller.board_state }
      end
    end
  end
end
