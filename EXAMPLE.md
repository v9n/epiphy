# Epiphy

This is a guide that helps you to getting started with [**Epiphy**](https://github.com/kureikain/epiphy). This file is inspired by Lotus::Model

## Gems

First of all, we need to setup a `Gemfile`.

```ruby
source 'https://rubygems.org'

gem 'epiphy'
```

Then we can fetch the dependencies with `bundle install`.

## Setup

We need to feed `Epiphy` with an adapter. Adapter is a lighweight wrap
contains a RethinkDB connection and its run option.

```
# Default connect to localhost, 28015, no auth key, use database 'test'
# by default
connection = Epiphy::Connection.create 
adapter    = Epiphy::Adapter::RethinkDB.new connection, 'test'
RethinkDB::Repository.configure do |r|
  r.adapter = adapter 
end

# Or merge them all
RethinkDB::Repository.configure do |r|
  r.adapter = Epiphy::Adapter::RethinkDB.new(Epiphy::Connection.create)
end

# Or connect to a different host, use database `cms`
RethinkDB::Repository.configure do |r|
  r.adapter = Epiphy::Adapter::RethinkDB.new Epiphy::Connection.create({:host => '192.168.1.2'}, 'cms')
end

```

## Entities

We have two entities in our application: `Author` and `Article`.
`Author` is a `Struct`, Epiphy can persist it.
`Article` has a small API concerning its publishing process.

```ruby
Author = Struct.new(:id, :name) do
  def initialize(attributes = {})
    @id, @name = attributes.values_at(:id, :name)
  end
end

class Article
  include Epiphy::Entity
  self.attributes = :author_id, :title, :comments_count, :published # id is implicit

  def published?
    !!published
  end

  def publish!
    @published = true
  end
end
```

## Repositories

In order to persist and query the entities above, we define two corresponding repositories:

```ruby
class AuthorRepository
  include Epiphy::Repository
end

class ArticleRepository
  include Epiphy::Repository

  def self.most_recent_by_author(author, limit = 8)
    query do
      where(author_id: author.id).
        desc(:id).
        limit(limit)
    end
  end

  def self.most_recent_published_by_author(author, limit = 8)
    most_recent_by_author(author, limit).published
  end

  def self.published
    query do
      where(published: true)
    end
  end

  def self.drafts
    exclude published
  end

  def self.rank
    published.desc(:comments_count)
  end

  def self.best_article_ever
    rank.limit(1).first
  end

  def self.comments_average
    query.average(:comments_count)
  end
end
```

## Persist

Let's instantiate and persist some objects for our example:

```ruby
author = Author.new(name: 'Luca')
AuthorRepository.create(author)

articles = [
  Article.new(title: 'Announcing Epiphy',              author_id: author.id, comments_count: 123, published: true),
  Article.new(title: 'Introducing Epiphy::Router',     author_id: author.id, comments_count: 63,  published: true),
  Article.new(title: 'Introducing Epiphy::Controller', author_id: author.id, comments_count: 82,  published: true),
  Article.new(title: 'Introducing Epiphy',      author_id: author.id)
]

articles.each do |article|
  ArticleRepository.create(article)
end
```

## Query

We can use repositories to query the database and return the entities we're looking for:

```ruby
ArticleRepository.first # => return the first article
ArticleRepository.last  # => return the last article

ArticleRepository.published # => return all the published articles
ArticleRepository.drafts    # => return all the drafts

ArticleRepository.rank      # => all the published articles, sorted by popularity

ArticleRepository.best_article_ever # => the most commented article

ArticleRepository.comments_average # => calculates the average of comments across all the published articles.

ArticleRepository.most_recent_by_author(author) # => most recent articles by an author (drafts and published).
ArticleRepository.most_recent_published_by_author(author) # => most recent published articles by an author
```

## Business logic

As we've seen above, `Article` implements an API for publishing.
We're gonna use that logic to alter the state of an article (from draft to published) and then we use the repository to persist this new state.

```ruby
article = ArticleRepository.drafts.first

article.published? # => false
article.publish!

article.published? # => true

ArticleRepository.update(article)
```
