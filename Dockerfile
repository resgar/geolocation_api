FROM ruby:3.3.4
RUN apt-get update -qq && apt-get install -y postgresql-client
WORKDIR /rails
# Install application gems
COPY Gemfile Gemfile.lock ./

RUN bundle install

# Copy application code
COPY . .

# Run and own only the runtime files as a non-root user for security
RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
    chown -R rails:rails db log storage tmp
USER 1000:1000

ENTRYPOINT ["/rails/bin/docker-entrypoint"]
EXPOSE 3000

# Configure the main process to run when running the image
CMD ["rails", "server", "-b", "0.0.0.0"]
