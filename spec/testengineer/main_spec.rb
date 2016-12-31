require 'spec_helper'

describe TestEngineer do
  let(:foreman) { double('Foreman::Engine') }

  describe '#foreman' do
    it 'should return nil when $foreman is nil' do
      expect(described_class.foreman).to be(nil)
    end

    it 'return the value in $foreman' do
      $foreman = foreman
      expect(described_class.foreman).to be($foreman)
    end

    after :each do
      $foreman = nil
    end
  end

  describe '#wait_for_socket' do
  end

  describe '#stop_process' do
    before :each do
      allow(described_class).to receive(:foreman).and_return(foreman)
    end
    context 'no running processes' do
      before :each do
        allow(foreman).to receive(:running_processes).and_return([])
      end

      it 'do nothing and reset Foreman::Engine.terminating' do
        expect(foreman).to receive(:instance_variable_set).with(:@terminating, false)
        described_class.stop_process('foreman')
      end

      it 'should raise an error on a nil name argument' do
        expect {
          described_class.stop_process(nil)
        }.to raise_error(ArgumentError)
      end
    end
    context 'running processes' do
      let(:process) { double('Foreman::Process') }
      before :each do
        allow(process).to receive(:name).and_return('mock.1')
        allow(foreman).to receive(:running_processes).and_return([[1, process]])
      end

      it 'should not stop unmatched names' do
        expect(process).not_to receive(:kill)
        described_class.stop_process('foreman')
      end

      it 'should not stop partially matched names' do
        expect(process).not_to receive(:kill)
        described_class.stop_process('mockery')
      end

      it 'should stop matching named processes' do
        expect(process).to receive(:kill)
        allow(Process).to receive(:waitpid).and_return(true)
        described_class.stop_process('mock')
      end
    end
  end

  describe '#start_stack' do
  end

  describe '#stop_stack' do
    it 'should not do anything if foreman is nil' do
      expect(foreman).not_to receive(:terminate_gracefully)
      allow(described_class).to receive(:foreman).and_return(nil)
      described_class.stop_stack
    end

    context 'with a stubbed foreman' do
      before :each do
        allow(described_class).to receive(:foreman).and_return(foreman)
      end

      it 'should invoke #terminate_gracefully if foreman exists' do
        expect(foreman).to receive(:terminate_gracefully)
        described_class.stop_stack
      end

      it 'should catch and hide ECHILD gracefully' do
        allow(foreman).to receive(:terminate_gracefully).and_raise(Errno::ECHILD)
        described_class.stop_stack
      end
    end

  end
end
