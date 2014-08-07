# Epiphy 

A persistence framework for [RethinkDB](http://rethinkdb.com). The library is used on [phim365.today](http://phim365.today). Its API is inspired by Lotus::Model.

`Epiphy` is name after `Epiphyllum`, my wife's name.

# Status

[![wercker status](https://app.wercker.com/status/63dd458158948712a03a00d69a96f67b/m "wercker status")](https://app.wercker.com/project/bykey/63dd458158948712a03a00d69a96f67b)

# Book [Simply RethinkDB](http://leanpub.com/simplyrethinkdb)

I also write this book to practice RethinkDB. Please consider buying a
copy if you want to support the author.


I love Lotus::Model so much because it's lightweight, does the job, no
magic. I also should fork Lotus and add RethinkDB adapter. However, I want
to learn more Ruby and reinvent the wheel because I didn't know how the
wheel was created. More than that, my bad code will not be able to make
it to Lotus::Model.

# Philosophy

Does basic thing well and leave complex query to RethinkDB.

RethinkDB query is very good. By wrapping an ORM around it, we can
destroy the joy of using ReQL. I only want to do basic thing with
RethinkDB, the complex query should be done use ReQL. The result of
query is converted back to an entity of an array of entity when
possible.

# API 

RethinkDB  delivers a convenient public API to execute queries and commands
against a database. The architecture eases keeping the business logic 
(entities) separated from details such as persistence or validations.

It implements the following concepts:

  * [Entity](#entities) - An object defined by its identity.
  * [Repository](#repositories) - An object that mediates between the entities and the persistence layer.
  * [Adapter](#adapter) – A database adapter.
  * [Query](#query) - An object that represents a database query.

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
will hit your RethinkDB. Depend on your storge system, test can be fast or
slow.

# Usage

Checkout [Examples.md](blob/master/EXAMPLE.md) for detail guide and [examples](tree/master/examples) folder for real
code.

## Entities

An object that is defined by its identity.

An entity is the core of an application, where the part of the domain logic is implemented. It's a small, cohesive object that expresses coherent and meaningful behaviors.

It deals with one and only one responsibility that is pertinent to the domain of the application, without caring about details such as persistence or validations.

This simplicity of design allows developers to focus on behaviors, or message passing if you will, which is the quintessence of Object Oriented Programming.


## Setup

```ruby
connection = Epiphy::Connection.create
adapter    = Epiphy::Adapter::RethinkDB.new connection
RethinkDB::Repository.configure do |r|
  r.adapter = adapter 
end
```

## Define your entity

```ruby
class Movie
  include Epiphy::Entity

  self.attributes= :title, :url, :type
end
```

## Define your repository

```ruby
class MovieRepository
  include Epiphy::Repository  
end
```

## Query 

```ruby

movie = MovieRepository.find id # Find by id

movie = MovieRepository.first :created_at # Find first entity, order by field :date
movie = MovieRepository.last :created_at  # Find first entity, order by field :date

movie = Movie.new
movie.title = "A movie"
MovieRepository.create movie
puts movie.id # return the ID of inserted movie

movie.title = "A new title"
MovieRepository.update movie

movie = Movie.new title: 'Another one', url: "http://youtube.com/foo", type: 'anime'
movie.id = Time.now.to_i #Manually assign an id
MovieRepository.create movie

```

## Custom query

From inside a Repository, we can call `query` method and pass in a
block. The method expose two object
  
  * Current ReQL command to play
  * Global top name space `r`

```ruby
class MovieRepository
  
  def lop
  end
end
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
