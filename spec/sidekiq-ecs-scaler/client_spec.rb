# frozen_string_literal: true

RSpec.describe SidekiqEcsScaler::Client do
  let(:client) { described_class.new(config) }

  let(:config) do
    SidekiqEcsScaler::Configuration.new.tap do |c|
      c.queue_name = "highest"
      c.min_count = 1
      c.max_count = 10
      c.max_latency = 3600
      c.ecs_client = ecs_client
    end
  end

  let(:ecs_client) { Aws::ECS::Client.new(stub_responses: true) }

  describe "#update_desired_count" do
    subject(:update) { client.update_desired_count }

    context "when task meta is null" do
      before do
        allow(config).to receive(:task_meta).and_return(nil)
      end

      it { is_expected.to be_nil }
    end

    context "when queue latency is less than max latency" do
      before do
        allow(config).to receive(:task_meta).and_return(
          SidekiqEcsScaler::TaskMetaV4.new({ "Cluster" => "local", "TaskARN" => "ARN" })
        )
        allow(Sidekiq::Queue).to receive(:new).with("highest").and_return(queue)
        ecs_client.stub_responses(:describe_tasks, tasks: [{ group: "service:local" }])
        ecs_client.stub_responses(
          :describe_services,
          services: [{ cluster_arn: "cluster", service_name: "service", desired_count: 1 }]
        )
      end

      let(:queue) do
        Class.new do
          def latency
            1800
          end
        end.new
      end

      it { is_expected.to eq 6 }
    end

    context "when queue latency is grater than max_latency" do
      before do
        allow(config).to receive(:task_meta).and_return(
          SidekiqEcsScaler::TaskMetaV4.new({ "Cluster" => "local", "TaskARN" => "ARN" })
        )
        allow(Sidekiq::Queue).to receive(:new).with("highest").and_return(queue)
        ecs_client.stub_responses(:describe_tasks, tasks: [{ group: "service:local" }])
        ecs_client.stub_responses(
          :describe_services,
          services: [{ cluster_arn: "cluster", service_name: "service", desired_count: 1 }]
        )
      end

      let(:queue) do
        Class.new do
          def latency
            36_000
          end
        end.new
      end

      it { is_expected.to eq 10 }
    end

    context "when desired_count is not changed" do
      before do
        allow(config).to receive(:task_meta).and_return(
          SidekiqEcsScaler::TaskMetaV4.new({ "Cluster" => "local", "TaskARN" => "ARN" })
        )
        allow(Sidekiq::Queue).to receive(:new).with("highest").and_return(queue)
        ecs_client.stub_responses(:describe_tasks, tasks: [{ group: "service:local" }])
        ecs_client.stub_responses(
          :describe_services,
          services: [{ cluster_arn: "cluster", service_name: "service", desired_count: 6 }]
        )
      end

      let(:queue) do
        Class.new do
          def latency
            1800
          end
        end.new
      end

      it { is_expected.to eq 6 }
    end

    context "when task is not found" do
      before do
        allow(config).to receive(:task_meta).and_return(
          SidekiqEcsScaler::TaskMetaV4.new({ "Cluster" => "local", "TaskARN" => "ARN" })
        )
        allow(Sidekiq::Queue).to receive(:new).with("highest").and_return(queue)
        ecs_client.stub_responses(:describe_tasks, tasks: [])
      end

      let(:queue) do
        Class.new do
          def latency
            1800
          end
        end.new
      end

      it do
        expect { update }.to raise_error(SidekiqEcsScaler::Error)
      end
    end
  end
end
