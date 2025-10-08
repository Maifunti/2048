FROM ruby:3.4.6

RUN mkdir -p /twenty_48/lib/twenty_48
WORKDIR /twenty_48
COPY Gemfile Gemfile.lock twenty-48.gemspec /twenty_48/
COPY lib/twenty_48/version.rb /twenty_48/lib/twenty_48/version.rb
RUN bundle install

COPY . /twenty_48

CMD ["bundle", "exec", "bin/twenty-48", "--ncurses"]
