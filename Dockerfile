FROM ruby:3.0.0-alpine3.13 AS base

WORKDIR /app

ENV RAILS_ENV=production

RUN apk add --update --no-cache postgresql-dev tzdata


FROM base AS builder

RUN apk add --update --no-cache build-base

COPY Gemfile .
COPY Gemfile.lock .

RUN bundle install --jobs 4

COPY . .

RUN SECRET_KEY_BASE=dummy bundle exec rails assets:precompile


FROM base AS main

COPY --from=builder /app /app
COPY --from=builder /usr/local/bundle /usr/local/bundle

CMD ["rails", "server", "-b", "0.0.0.0"]
