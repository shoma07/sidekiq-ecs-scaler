# frozen_string_literal: true

require "logger"
require "uri"
require "net/http"
require "json"
require "sidekiq"
require "sidekiq/api"
require "aws-sdk-ecs"
require_relative "sidekiq_ecs_scaler/version"
require_relative "sidekiq_ecs_scaler/task_meta_v4"
require_relative "sidekiq_ecs_scaler/configuration"
require_relative "sidekiq_ecs_scaler/client"
require_relative "sidekiq_ecs_scaler/worker"

# SidekiqEcsScaler
module SidekiqEcsScaler
  # SidekiqEcsScaler::Error
  class Error < StandardError; end

  class << self
    # @return [SidekiqEcsScaler::Configuration]
    def config
      @config ||= Configuration.new
    end

    # @yieldparam config [SidekiqEcsScaler::Configuration]
    # @yieldreturn [void]
    # @return [void]
    def configure
      raise Error, "No block is given!" unless block_given?

      yield config
    end

    # @return [SidekiqEcsScaler::Client]
    def client
      Client.new(config)
    end
  end
end
