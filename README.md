ws-app
======

## Requirements

- [Ruby 2.1.1](https://www.ruby-lang.org/fr/downloads)

You'll also need to launch the [SOAP server](https://github.com/2slow/ws-soap-server) as this app get data from web services.

## Install

```
git clone git@github.com:rhannequin/ws-app.git && cd ws-app
bundle install
```

## Launch

```
foreman start # open http://127.0.0.1:5000
```

## Test

```
bundle exec rake test
```
