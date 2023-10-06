FROM ruby:3.1.1

RUN apt update && apt install git npm nodejs curl ruby-foreman -y
RUN curl -sL https://deb.nodesource.com/setup_18.x | bash -
RUN apt update -y
RUN apt upgrade -y
RUN apt install nodejs -y
RUN node -v
RUN npm install -g yarn
RUN mkdir /app
WORKDIR /app
RUN gem install bundler
ADD Gemfile /app/Gemfile
ADD Gemfile.lock /app/Gemfile.lock
RUN bundle update rake
RUN bundle install
RUN mkdir /app/client
WORKDIR /app/client
ADD client/package.json /app/client/
ADD client/yarn.lock /app/client
RUN yarn
WORKDIR /app
ADD . /app
RUN chmod +x docker-run.sh
ENV RAILS_ENV=production
WORKDIR /app/client
ENV ESLINT_NO_DEV_ERRORS=true
RUN ESLINT_NO_DEV_ERRORS=true yarn run build-docker
WORKDIR /app
RUN mkdir "public"
RUN cp -Rf /app/client/build/* /app/public/
CMD ["sh", "-c", "./docker-run.sh"]

