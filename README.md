# SidekiqEcsScaler

Auto scaler of [Sidekiq](https://github.com/mperham/sidekiq) worker deploymented to AWS ECS.

Only supported when deploying Sidekiq workers to AWS ECS Fargate (1.14.0+)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'sidekiq-ecs-scaler'
```

And then execute:

    $ bundle install

## Usage

### Configuration

```ruby
SidekiqEcsScaler.configure do |config|
  # enable / disable of scaler, default is true
  config.enabled = true

  # queue to monitor latency, default is "default"
  config.queue_name = "default"

  # minimum number of tasks, default is 1
  config.min_count = 1

  # maximum number of tasks, default is 1
  config.max_count = 3

  # maximum latency(seconds), default is 3600
  config.max_latency = 3600

  # custom ECS Client
  config.ecs_client = Aws::ECS::Client.new

  # Set worker options for scaling
  config.sidekiq_options = { "retry" => true, "queue" => "scheduler" }
end
```

### With Sidekiq Scheduler

When using [sidekiq-scheduler](https://github.com/moove-it/sidekiq-scheduler), schedule the scale by setting as follows.

```yml
# sidekiq.yml
# example

:schedule:
  SidekiqEcsScaler::Worker:
    cron: "0 */15 * * * *"
    # It is safe to set this queue to have a higher priority than the monitored queue.
    queue: scheduler
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/sidekiq-ecs-scaler.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
