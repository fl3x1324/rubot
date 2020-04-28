FROM ruby:2.6
RUN apt-get update -qq && apt-get install -y postgresql-client
RUN mkdir /fbbot
WORKDIR /fbbot
COPY Gemfile /fbbot/Gemfile
COPY Gemfile.lock /fbbot/Gemfile.lock
RUN bundle install
COPY . /fbbot

# Add a script to be executed every time the container starts.
COPY entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]
EXPOSE 3000

# Start the main process.
CMD ["RAILS_ENV=production", "rails", "server", "-b", "0.0.0.0"]