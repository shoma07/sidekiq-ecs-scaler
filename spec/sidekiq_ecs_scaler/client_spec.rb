# frozen_string_literal: true

RSpec.describe SidekiqEcsScaler::Client do
  let(:client) { described_class.new(config) }

  let(:config) do
    SidekiqEcsScaler::Configuration.new.tap do |c|
      c.queue_name = "highest"
      c.logger = Logger.new(io).tap { |logger| logger.formatter = Sidekiq::Logger::Formatters::JSON.new }
      c.min_count = 1
      c.max_count = 10
      c.max_latency = 3600
      c.ecs_client = ecs_client
      c.enabled = enabled
    end
  end

  let(:enabled) { true }

  let(:io) { StringIO.new }

  let(:ecs_client) { Aws::ECS::Client.new(stub_responses: true) }

  let(:stub_task_meta) do
    SidekiqEcsScaler::TaskMetaV4.new({ "Cluster" => "local", "TaskARN" => "ARN" })
  end

  let(:queue) do
    Class.new do
      def latency
        1800
      end
    end.new
  end

  let(:stub_tasks) { [{ group: "service:local" }] }

  let(:stub_services) { [{ cluster_arn: "cluster", service_name: "service", desired_count: 1 }] }

  before do
    allow(config).to receive(:task_meta).and_return(stub_task_meta)
    allow(Sidekiq::Queue).to receive(:new).with("highest").and_return(queue)
    ecs_client.stub_responses(:describe_tasks, tasks: stub_tasks)
    ecs_client.stub_responses(:describe_services, services: stub_services)
  end

  describe "#update_desired_count" do
    subject(:update) { client.update_desired_count }

    context "when config enabled is false" do
      let(:enabled) { false }

      it { is_expected.to be_nil }
    end

    context "when task meta is null" do
      let(:stub_task_meta) { nil }

      it { is_expected.to be_nil }
    end

    context "when queue latency is less than max latency" do
      it { is_expected.to eq 6 }

      it do
        update
        expect(JSON.parse(io.tap(&:rewind).read).fetch("msg")).to(
          eq("SidekiqEcsScaler has updated the desired count of tasks from 1 to 6.")
        )
      end
    end

    context "when queue latency is grater than max_latency" do
      let(:queue) do
        Class.new do
          def latency
            36_000
          end
        end.new
      end

      it { is_expected.to eq 10 }
      it do
        update
        expect(JSON.parse(io.tap(&:rewind).read).fetch("msg")).to(
          eq("SidekiqEcsScaler has updated the desired count of tasks from 1 to 10.")
        )
      end
    end

    context "when desired_count is not changed" do
      let(:stub_services) { [{ cluster_arn: "cluster", service_name: "service", desired_count: 6 }] }

      it { is_expected.to eq 6 }
      it do
        update
        expect(JSON.parse(io.tap(&:rewind).read).fetch("msg")).to(
          eq("SidekiqEcsScaler doesn't have updated the desired count of tasks from 6.")
        )
      end
    end

    context "when task is not found" do
      let(:stub_tasks) { [] }

      it { expect { update }.to raise_error(SidekiqEcsScaler::Error) }
    end
  end
end
