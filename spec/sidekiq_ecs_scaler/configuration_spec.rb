# frozen_string_literal: true

RSpec.describe SidekiqEcsScaler::Configuration do
  let(:configuration) { described_class.new }

  describe "#enabled" do
    subject { configuration.enabled }

    context "when default" do
      it { is_expected.to eq true }
    end
  end

  describe "#enabled=" do
    subject(:write) { configuration.enabled = enabled }

    context "when enabled is true" do
      let(:enabled) { true }

      it do
        expect { write }.not_to change(configuration, :enabled).from(true)
      end
    end

    context "when enabled is false" do
      let(:enabled) { false }

      it do
        expect { write }.to change(configuration, :enabled).to(false)
      end
    end

    context "when enabled is invalid" do
      let(:enabled) { "true" }

      it do
        expect { write }.to raise_error(ArgumentError)
      end
    end
  end

  describe "#logger" do
    subject { configuration.logger }

    context "when default" do
      it { is_expected.to eq Sidekiq.logger }
    end
  end

  describe "#logger=" do
    subject(:write) { configuration.logger = logger }

    context "when logger is valid" do
      let(:logger) { Logger.new(StringIO.new) }

      it do
        expect { write }.to change(configuration, :logger).to(logger)
      end
    end

    context "when logger is invalid" do
      let(:logger) { StringIO.new }

      it do
        expect { write }.to raise_error(ArgumentError)
      end
    end
  end

  describe "#queue_name" do
    subject { configuration.queue_name }

    context "when default" do
      it { is_expected.to eq "default" }
    end
  end

  describe "#queue_name=" do
    subject(:write) { configuration.queue_name = queue_name }

    context "when argument is valid" do
      let(:queue_name) { "highest" }

      it do
        expect { write }.to change(configuration, :queue_name).to("highest")
      end
    end

    context "when argument is invalid" do
      let(:queue_name) { nil }

      it do
        expect { write }.to raise_error(ArgumentError)
      end
    end
  end

  describe "#min_count" do
    subject { configuration.min_count }

    context "when default" do
      it { is_expected.to eq 1 }
    end
  end

  describe "#min_count=" do
    subject(:write) { configuration.min_count = min_count }

    context "when argument is valid and less than max_count" do
      let(:min_count) { 2 }

      before do
        configuration.max_count = 3
      end

      it do
        expect { write }.to change(configuration, :min_count).to(2)
      end

      it do
        expect { write }.not_to change(configuration, :max_count)
      end
    end

    context "when argument is valid and grater than max_count" do
      let(:min_count) { 2 }

      before do
        configuration.max_count = 1
      end

      it do
        expect { write }.to change(configuration, :min_count).to(2)
      end

      it do
        expect { write }.to change(configuration, :max_count).to(2)
      end
    end

    context "when argument is invalid" do
      let(:min_count) { 0 }

      it do
        expect { write }.to raise_error(ArgumentError)
      end
    end
  end

  describe "#max_count" do
    subject { configuration.max_count }

    context "when default" do
      it { is_expected.to eq 1 }
    end
  end

  describe "#max_count=" do
    subject(:write) { configuration.max_count = max_count }

    context "when argument is valid and grater than min_count" do
      let(:max_count) { 2 }

      before do
        configuration.min_count = 1
      end

      it do
        expect { write }.to change(configuration, :max_count).to(2)
      end

      it do
        expect { write }.not_to change(configuration, :min_count)
      end
    end

    context "when argument is valid and less than min_count" do
      let(:max_count) { 2 }

      before do
        configuration.min_count = 3
      end

      it do
        expect { write }.to change(configuration, :max_count).to(2)
      end

      it do
        expect { write }.to change(configuration, :min_count).to(2)
      end
    end

    context "when argument is invalid" do
      let(:max_count) { 0 }

      it do
        expect { write }.to raise_error(ArgumentError)
      end
    end
  end

  describe "#step_count" do
    subject { configuration.step_count }

    context "when default" do
      it { is_expected.to eq 1 }
    end
  end

  describe "#step_count=" do
    subject(:write) { configuration.step_count = step_count }

    context "when argument is valid" do
      let(:step_count) { 2 }

      it do
        expect { write }.to change(configuration, :step_count).to(2)
      end
    end

    context "when argument is invalid" do
      let(:step_count) { 0 }

      it do
        expect { write }.to raise_error(ArgumentError)
      end
    end
  end

  describe "#max_latency" do
    subject { configuration.max_latency }

    context "when default" do
      it { is_expected.to eq 3600 }
    end
  end

  describe "#max_latency=" do
    subject(:write) { configuration.max_latency = max_latency }

    context "when argument is valid" do
      let(:max_latency) { 7200 }

      it do
        expect { write }.to change(configuration, :max_latency).to(7200)
      end
    end

    context "when argument is less than max count" do
      let(:max_latency) { 10 }

      before do
        configuration.max_count = 20
      end

      it do
        expect { write }.to raise_error(ArgumentError)
      end
    end
  end

  describe "#ecs_client" do
    subject { configuration.ecs_client }

    context "when default" do
      it { is_expected.to be_instance_of(::Aws::ECS::Client) }
    end
  end

  describe "#ecs_client=" do
    subject(:write) { configuration.ecs_client = ecs_client }

    context "when argument is kind of Aws::ECS::Client" do
      let(:ecs_client) do
        Class.new(::Aws::ECS::Client) do
          def initialize
            super(stub_responses: true)
          end
        end.new
      end

      it do
        write
        expect(configuration.ecs_client).to be_kind_of(::Aws::ECS::Client)
      end
    end

    context "when argument is not kind of Aws::ECS::Client" do
      let(:ecs_client) do
        Class.new.new
      end

      it do
        expect { write }.to raise_error(ArgumentError)
      end
    end
  end

  describe "#latency_per_step_count" do
    subject { configuration.latency_per_step_count }

    context "when step_count is 1" do
      before do
        configuration.min_count = 2
        configuration.max_count = 20
        configuration.max_latency = 3600
      end

      it { is_expected.to eq 189 }
    end

    context "when step_count is 2" do
      before do
        configuration.min_count = 2
        configuration.max_count = 20
        configuration.step_count = 2
        configuration.max_latency = 3600
      end

      it { is_expected.to eq 360 }
    end
  end

  describe "#task_meta!" do
    subject(:call) { configuration.task_meta! }

    context "when task_meta is present" do
      before do
        allow(configuration).to receive(:task_meta).and_return(
          SidekiqEcsScaler::TaskMetaV4.new({ "Cluster" => "local", "TaskARN" => "ARN" })
        )
      end

      it { is_expected.to have_attributes(cluster: "local", task_arn: "ARN") }
    end

    context "when task_meta is null" do
      it do
        expect { call }.to raise_error(SidekiqEcsScaler::Error)
      end
    end
  end

  describe "#sidekiq_options" do
    subject { configuration.sidekiq_options }

    context "when default" do
      it { is_expected.to eq({ "retry" => true, "queue" => "default" }) }
    end
  end

  describe "#sidekiq_options=" do
    subject(:write) { configuration.sidekiq_options = sidekiq_options }

    context "when argument is invalid" do
      let(:sidekiq_options) { nil }

      it do
        expect { write }.to raise_error(ArgumentError)
      end
    end

    context "when argument is valid" do
      let(:sidekiq_options) { { "queue" => "scheduler" } }

      around do |example|
        original_options = SidekiqEcsScaler::Worker.sidekiq_options

        example.run

        SidekiqEcsScaler::Worker.sidekiq_options(original_options)
      end

      it do
        expect { write }.to(
          change(SidekiqEcsScaler::Worker, :sidekiq_options).to({ "retry" => true, "queue" => "scheduler" })
        )
      end
    end
  end
end
