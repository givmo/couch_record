# CouchRecord: A streamlined CouchDB ORM, using CouchRest

## Design goals

- Be Fast - Your app has to map a lot of objects, so try to do as little as possible, especially when reading records from CouchDB
- Be Simple - You're going to end up looking at (debugging into) your ORM when something's not working as you expect, so the less code there is and the easier it is to understnd, the better.
- ActiveModel - Use ActiveModel modules wherever possible to support ActiveModel funcionality
- Don't Support Everything - CouchReccord is not a drop in replacement for ActiveRecord, CouchRest::Model or anything else.

## Installation

    $ sudo gem install couchrecord

## Configuration

CouchRecord will load the file "#{Rails.root}/config/couchdb.yml" which should look like this:

    development:
      url: https://username:password@host:port
    test:
      url: https://username:password@host:port
    production:
      url: https://username:password@host:port


## Models

Models should extend CouchRecord::Base.  CouchRecord property declaration syntax was inspired by that of CouchRest::Model.

    class Person < CouchRecord::Base
      property :name, String
      property :age, Integer, :default => 21
      property :children, [Person]

      timestamps!

      find_by :name
      view_by :count, :method_name => 'count_by_name', :design_doc => 'by_name', :view_name => 'name_count'
    end

Each property declaration creates a getter and setter for the property that handle conversion to and from the specified type.

The `timestamps!` declaration creates properties fro created_at and updated_at and sets them on create and update.

### Supported Types

- **String**
- **Integer**
- **TrueClass** - for booleans
- **Date** - stored as a string in iso8601 format
- **Time** - stored as a string in iso8601 format
- **BigDecimal** - stored as a string
- other models that extend **CouchRecord::Base**
- **Array** -  of the above types
- **Hash** - of the above types

## Queries

All queries are explicitly declared, just like the way CouchDB works.  CouchRecord provides 2 ways to create querying methods on the record class:

- **view_by** - generates a query method that returns raw rows from the database
- **find_by** - generates a query method that returns records of the model class, using the :include_docs query parameter

    find_by :name, :singular => true

Options

- **:design_doc** - defaults to "by_#{name}"
- **:view_name** - defaults to "by_#{name}"
- **:singular** - sets :limit => 1 on the query and returns the first row or record instead of an array
- **:case_insensitive** - downcases :key, :startkey, and :endkey when passed as parameters to the query method.  You're responsible for making sure your view doncases the values being indexed.
- any other options are passed as parameters on the query, so you can use :limit, :descending, etc.


## Design Docs and View Files

CouchRecord's query system is completely independent of how you create and load you views in CouchDB.  However, it does provide sytems for dealing with views that you can use.
In the Rails.root/db/couch/ directory, there are directories with the same names as your CouchDB databases.  We recommend using 1 database per Model, but this isn't required.
Within each database directory are JavaScript files for your views.

    Rails.root/db/couch/
    ├── people
    │   └── by_name.js
    ├── users
    │   ├── by_email.js
    │   ├── by_remember_token.js

Each js file maps to 1 design doc in your database.  Each file has 1 map function and 0 or more reduce functions.
Since CouchDB reindexes all views in a design doc together, and multiple views in a design doc can share the same map index, it seems like best practice to have 1 map per doc.

The example js file below will create a design doc with 2 views: `by_name` and `name_count`, both using the same map function.

    map = function(doc) {
        if (doc['name'] != null) {
            emit(doc['name'].toLowerCase(), 1);
        }
    };

    by_name = null

    name_count = function(keys, values) {
        return sum(values);
    }

### Deleting Design Docs

When you delete a design doc, you want it to get deleted from all development, test, and production databases.
CouchRecord handles this by keeping a list of deleted files in Rails.root/db/deleted_couch_views:

    people/by_email.js
    items/by_category.js

When you delete a design doc file from git, add it to thsi file so it gets removed from everyone's db when they migrate

### Migrating

To push the views in db/couch/ to your databases and delete the views in db/deleted_couch_views

    rake couch_record:push

## What works?

### ActiveModel::Dirty

- record.changed?
- record.changed
- record.changes
- record.{attr}_changed?
- record.{attr}_was
- record.{attr}_change

The sementics of these calls are slightly different than those in ActiveRecord.
We don't clear the list of changed attributes until *after* all the after_* callbacks are finished.
This means you can easily see what's changed in your after_* callbacks instead of having to look in `previous_changes`.
It also means if you change attribute values in your after_* callbacks, they won't get marked as dirty, so don't do that.

### ActiveModel::Callbacks

:before, :after, and :around for :create, :destroy, :save, and :update

### ActiveModel::Validations

All standard ActiveModel Validations plus a custom:

    validates_uniqness_of :attr


## Constraints

- currently only supports a single database connection
- currently only used in Rails, so may have different behavior outside Rails
