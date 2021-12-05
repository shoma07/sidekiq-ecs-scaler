# frozen_string_literal: true

RSpec.describe SidekiqEcsScaler::Worker do
  subject { described_class.new.perform }

  let(:stub_client) do
    Class.new do
      def update_desired_count
        1
      end
    end.new
  end

  before do
    allow(SidekiqEcsScaler).to receive(:client).and_return(stub_client)
  end

  it { is_expected.to eq 1 }
end
