# frozen_string_literal: true

RSpec.describe SidekiqEcsScaler::TaskMetaV4 do
  describe "self.build_or_null" do
    subject { described_class.build_or_null }

    context "when ecs environment is not exists" do
      it { is_expected.to be_nil }
    end

    context "when successful get metadata" do
      before do
        allow(ENV).to receive(:fetch).with("ECS_CONTAINER_METADATA_URI_V4", nil).and_return(
          "http://localhost:10000"
        )

        allow(Net::HTTP).to receive(:get).and_return({ "Cluster" => "local", "TaskARN" => "ARN" }.to_json)
      end

      it { is_expected.to be_instance_of(described_class) }

      it { is_expected.to have_attributes(cluster: "local", task_arn: "ARN") }
    end

    context "when failure get metadata" do
      before do
        allow(ENV).to receive(:fetch).with("ECS_CONTAINER_METADATA_URI_V4", nil).and_return(
          "http://localhost:10000"
        )

        allow(Net::HTTP).to receive(:get).and_raise(Errno::EADDRNOTAVAIL)
      end

      it { is_expected.to be_nil }
    end
  end
end
