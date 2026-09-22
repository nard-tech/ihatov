ARG RUBY_VERSION=3.4
FROM ruby:${RUBY_VERSION}

WORKDIR /workspace/ihatov

# ホストのBundler設定を使わず、開発用gemをイメージ内にインストールする。
# Install development gems in the image without using host Bundler settings.
ENV BUNDLE_APP_CONFIG=/tmp/ihatov-bundle-config

COPY . .
RUN bundle install

CMD ["bundle", "exec", "rspec"]
