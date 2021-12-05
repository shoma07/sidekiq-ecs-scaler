# frozen_string_literal: true

module SidekiqEcsScaler
  # SidekiqEcsScaler::Client
  class Client
    # @param config [SidekiqEcsScaler::Configuration]
    # @return [void]
    def initialize(config)
      @config = config
    end

    # @return [Integer, nil]
    def update_desired_count
      return if !config.enabled || config.task_meta.nil?

      desired_count = desired_count_by_latency
      service = describe_service

      if service.desired_count == desired_count
        not_change_log(desired_count)
      else
        update_service(service: service, desired_count: desired_count)
        change_log(service.desired_count, desired_count)
      end

      desired_count
    end

    private

    # @!attribute [r] config
    # @return [SidekiqEcsScaler::Configuration]
    attr_reader :config

    # @return [Float]
    def queue_latency
      Sidekiq::Queue.new(config.queue_name).latency
    end

    # @return [Integer]
    def desired_count_by_latency
      (config.min_count..config.max_count).to_a.at(
        (queue_latency.to_f / config.latency_per_count).floor.to_i
      ) || config.max_count
    end

    # @return [String]
    def service_name
      config.task_meta!.then do |task_meta|
        config.ecs_client.describe_tasks(
          { cluster: task_meta.cluster, tasks: [task_meta.task_arn] }
        ).tasks.first&.then { |task| task.group.delete_prefix("service:") } || (
          raise Error, "Task(#{task_meta.task_arn}) does not exist in cluster!"
        )
      end
    end

    # @return [Aws::ECS::Types::Service]
    def describe_service
      config.ecs_client.describe_services(
        { cluster: config.task_meta!.cluster, services: [service_name] }
      ).services.first || (raise Error, "Service(#{service_name}) does not exist in cluster!")
    end

    # @param service [Aws::ECS::Types::Service]
    # @param desired_count [Integer]
    # @return [Aws::ECS::Types::UpdateServiceResponse]
    def update_service(service:, desired_count:)
      config.ecs_client.update_service(
        {
          cluster: service.cluster_arn,
          service: service.service_name,
          desired_count: desired_count
        }
      )
    end

    # @param count [Integer]
    # @return [void]
    def not_change_log(count)
      config.logger.info("SidekiqEcsScaler doesn't have updated the desired count of tasks from #{count}.")
    end

    # @param before_count [Integer]
    # @param after_count [Integer]
    # @return [void]
    def change_log(before_count, after_count)
      config.logger.info(
        "SidekiqEcsScaler has updated the desired count of tasks from #{before_count} to #{after_count}."
      )
    end
  end
end
