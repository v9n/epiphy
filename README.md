# Epiphy [![wercker status](https://app.wercker.com/status/63dd458158948712a03a00d69a96f67b/m "wercker status")](https://app.wercker.com/project/bykey/63dd458158948712a03a00d69a96f67b)

A persistence framework for [RethinkDB](http://rethinkdb.com). The library is used on [phim365.today](http://phim365.today). Its API is based on Lotus::Model.

I love Lotus::Model so much because it's lightweight, does the job, no
magic. I also should fork Lotus and add RethinkDB adapter. However, I want
to learn more Ruby and reinvent the wheel because I didn't know how the
wheel was created. More than that, my bad code will not be able to make
it to Lotus::Model.

It delivers a convenient public API to execute queries and commands against a database.
The architecture eases keeping the business logic (entities) separated from details such as persistence or validations.

It implements the following concepts:

  * [Entity](#entities) - An object defined by its identity.
  * [Repository](#repositories) - An object that mediates between the entities and the persistence layer.
  * [Adapter](#adapter) – A database adapter.
  * [Query](#query) - An object that represents a database query.

`Epiphy` is name after `Epiphyllum`, my spouse's name.

# Install

```
gem install epiphy
```

or add

```
gem 'epiphy'
```

to your `Gemfile` if you use Bundle. Run `bundle install`


# Testing

`Minitest` is used for testing.

Make sure you have a working RethinkDB with default connection
information that is localhost, port 28015, without authentication key
and run

```
$ bundle install
$ rake test
```

A testing database will be created during the testing. The testing data
will hit your RethinkDB. Depend on your storge system, test can fast or
slow.

# Example

```ruby
connection = Epiphy::Connection.create
adapter    = Epiphy::Adapter::RethinkDB.new connection
RethinkDB::Repository.configure do |r|
  r.adapter = adapter 
end

class Movie
  include Epiphy::Entity
  include Epiphy::Entity::Timestamp

  attributes :title, :url
end

class MovieRepository
  include Epiphy::Repository  
end

movie = MovieRepository.find id # Find by id

movie = MovieRepository.first
movie = MovieRepository.last

movie = Movie.new
movie.title = "A movie"
MovieRepository.create movie
MovieRepository.update movie



```

# Contributing to epiphy
 
* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet.
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it.
* Fork the project.
* Start a feature/bugfix branch.
* Commit and push until you are happy with your contribution.
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
* Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.

# Copyright

Copyright (c) 2014 kureikain. See LICENSE.txt for
further details.
