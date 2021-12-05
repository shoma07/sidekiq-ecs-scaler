# frozen_string_literal: true

module SidekiqEcsScaler
  # SidekiqEcsScaler::Worker
  class Worker
    include Sidekiq::Worker

    # @return [Integer, nil]
    def perform
      SidekiqEcsScaler.client.update_desired_count
    end
  end
end
