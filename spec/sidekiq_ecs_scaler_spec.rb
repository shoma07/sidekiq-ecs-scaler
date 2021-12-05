# frozen_string_literal: true

RSpec.describe SidekiqEcsScaler do
  describe "VERSION" do
    it "has a version number" do
      expect(SidekiqEcsScaler::VERSION).not_to be nil
    end
  end

  describe "self.config" do
    subject { described_class.config }

    it { is_expected.to be_instance_of(SidekiqEcsScaler::Configuration) }
  end

  describe "self.configure" do
    let(:stub_config) { SidekiqEcsScaler::Configuration.new }

    before do
      allow(described_class).to receive(:config).and_return(stub_config)
    end

    context "when block given" do
      subject(:configure) do
        described_class.configure do |config|
          config.min_count = 1
          config.max_count = 2
        end
      end

      it do
        expect { configure }.to change(stub_config, :max_count).to(2)
      end
    end

    context "when block not given" do
      subject(:configure) do
        described_class.configure
      end

      it do
        expect { configure }.to raise_error(SidekiqEcsScaler::Error)
      end
    end
  end

  describe "self.client" do
    subject { described_class.client }

    it { is_expected.to be_instance_of(SidekiqEcsScaler::Client) }
  end
end
