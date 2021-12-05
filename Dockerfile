FROM ruby:3.0.3-slim

RUN apt-get update \
    && apt-get install -y build-essential git \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /usr/src/sidekiq-ecs-scaler

RUN mkdir -p lib/sidekiq_ecs_scaler \
    && echo "module SidekiqEcsScaler\n  VERSION = \"0.1.0\"\nend\n" > lib/sidekiq_ecs_scaler/version.rb

COPY bin/setup ./bin/
COPY Gemfile Gemfile.lock sidekiq-ecs-scaler.gemspec .

RUN bin/setup
