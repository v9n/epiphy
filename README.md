# Epiphy

A persistence framework for [RethinkDB](http://rethinkdb.com). The library is used on phim365.today. Its API is based on Lotus::Model.

I love Lotus::Model so much because it's leightweight, does the job, no
magic. I also should fork Lotus and add RethinkDB adapter. However, I want
to learn more Ruby and reinvent the wheel because I didn't know how the
wheel was created.

It delivers a convenient public API to execute queries and commands against a database.
The architecture eases keeping the business logic (entities) separated from details such as persistence or validations.

It implements the following concepts:

  * [Entity](#entities) - An object defined by its identity.
  * [Repository](#repositories) - An object that mediates between the entities and the persistence layer.
  * [Data Mapper](#data-mapper) - A persistence mapper that keep entities independent from database details.
  * [Adapter](#adapter) – A database adapter.
  * [Query](#query) - An object that represents a database query.

Like all the other Lotus components, it can be used as a standalone framework or within a full Rails/Lotus application.

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