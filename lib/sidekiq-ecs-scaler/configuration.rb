# frozen_string_literal: true

module SidekiqEcsScaler
  # SidekiqEcsScaler::Configuration
  class Configuration
    # @!attribute [r] queue_name
    # @return [String]
    attr_reader :queue_name
    # @!attribute [r] min_count
    # @return [Integer]
    attr_reader :min_count
    # @!attribute [r] max_count
    # @return [Integer]
    attr_reader :max_count
    # @!attribute [r] max_latency
    # @return [Integer]
    attr_reader :max_latency
    # @!attribute [r] task_meta
    # @return [SidekiqEcsScaler::TaskMetaV4, nil]
    attr_reader :task_meta
    # @!attribute [r] ecs_client
    # @return [Aws::ECS::Client]
    attr_reader :ecs_client

    # @return [void]
    def initialize
      @queue_name = "default"
      @min_count = 1
      @max_count = 1
      @max_latency = 3600
      @ecs_client = Aws::ECS::Client.new
      @task_meta = TaskMetaV4.build_or_null
    end

    # @param queue_name [String]
    # @return [void]
    def queue_name=(queue_name)
      raise ArgumentError unless queue_name.instance_of?(String)

      @queue_name = queue_name
    end

    # @param min_count [Integer]
    # @return [void]
    # @raise [ArgumentError]
    def min_count=(min_count)
      raise ArgumentError unless min_count.positive?

      @min_count = min_count
      @max_count = min_count if min_count > max_count
    end

    # @param max_count [Integer]
    # @return [void]
    # @raise [ArgumentError]
    def max_count=(max_count)
      raise ArgumentError unless max_count.positive?

      @max_count = max_count
      @min_count = max_count if max_count < min_count
    end

    # @param max_latency [Integer]
    # @return [void]
    # @raise [ArgumentError]
    def max_latency=(max_latency)
      raise ArgumentError if max_count > max_latency

      @max_latency = max_latency
    end

    # @param ecs_client [Aws::ECS::Client]
    # @return [void]
    # @raise [ArgumentError]
    def ecs_client=(ecs_client)
      raise ArgumentError unless ecs_client.is_a?(Aws::ECS::Client)

      @ecs_client = ecs_client
    end

    # @return [Integer]
    def latency_per_count
      (max_latency / (1 + max_count - min_count)).tap do |value|
        value.positive? || (raise Error, "latency per count isn't positive!")
      end
    end

    # @return [SidekiqEcsScaler::TaskMetaV4]
    def task_meta!
      task_meta || (raise Error, "task metadata is null!")
    end
  end
end