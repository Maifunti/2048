# frozen_string_literal: true

require 'rspec'

describe Twenty48::Utils::String do
  describe '.wrap' do
    let(:input) do
      <<~EOF
          Hello world
        EOF
    end

    subject { described_class.wrap input, limit }

    context 'width of text less than limit' do
      let(:limit) { 12 }
      it 'does not change text' do
        expect(subject).to eq input
      end
    end

    context 'width of text equal to limit' do
      let(:limit) { 11 }
      it 'does not change text' do
        expect(subject).to eq input
      end
    end

    context 'width of text exceeds limit' do
      let(:limit) { 10 }
      it 'wraps text' do
        expect(subject).to eq <<~EOF
          Hello worl-
          -d
        EOF
      end
    end

    context 'multiline string' do
      let(:input) do
        <<~EOF
          abc
          defg
          hij
        EOF
      end

      context 'width of text less than limit' do
        let(:limit) { 5 }
        it 'does not change text' do
          expect(subject).to eq input
        end
      end

      context 'width of text equal to limit' do
        let(:limit) { 4 }
        it 'does not change text' do
          expect(subject).to eq input
        end
      end

      context 'width of text exceeds limit' do
        let(:limit) { 3 }
        it 'wraps text' do
          expect(subject).to eq <<~EOF
          abc
          def-
          -g
          hij
        EOF
        end
      end
    end
  end
end