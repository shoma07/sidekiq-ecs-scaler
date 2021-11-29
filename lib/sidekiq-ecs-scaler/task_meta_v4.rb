# frozen_string_literal: true

module SidekiqEcsScaler
  # SidekiqEcsScaler::TaskMetaV4
  #
  # @see https://docs.aws.amazon.com/AmazonECS/latest/userguide/task-metadata-endpoint-v4-fargate.html
  class TaskMetaV4
    class << self
      # @todo If the metadata acquisition fails, an error will be output to the log.
      #
      # @return [SidekiqEcsScaler::TaskMetaV4, nil]
      def build_or_null
        ENV.fetch("ECS_CONTAINER_METADATA_URI_V4", nil)&.then do |uri|
          new(JSON.parse(Net::HTTP.get(URI.parse("#{uri}/task"))))
        end
      rescue StandardError
        nil
      end
    end

    # @!attribute [r] cluster
    # @return [String]
    attr_reader :cluster
    # @!attribute [r] task_arn
    # @return [String]
    attr_reader :task_arn

    # @param resp [Hash]
    # @return [void]
    def initialize(resp)
      @cluster = resp.fetch("Cluster")
      @task_arn = resp.fetch("TaskARN")
    end
  end
end
