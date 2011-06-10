# CouchRecord: A streamlined CouchDB ORM, using CouchRest

## Design goals

- Be Fast - Your app has to map a lot of objects, so try to do as little as possible, especially when reading records from CouchDB
- Be Simple - You're going to end up looking at (debugging into) your ORM when something's not working as you expect, so the less code there is and the easier it is to understnd, the better.
- ActiveModel - Use ActiveModel modules wherever possible to support ActiveModel funcionality
- Don't Support Everything - CouchReccord is not a drop in replacement for ActiveRecord or anything else.

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

      find_by :name
    end

Each property declaration creates a getter and setter for the property that handle conversion to and from the specified type.

### Supported Types

- String
- Integer
- TrueClass - for booleans
- Date - stored as a string in iso8601 format
- Time - stored as a string in iso8601 format
- BigDecimal - stored as a string
- other models that extend CouchRecord::Base
- Arrays of the above types
- Hashes of the above types

## Queries

All queries are explicitly declared, just like the way CouchDB works.  CouchRecord provides 3 ways to create querying methods on the record class:

- find_by - generates a query method that returns records of the model class, using the
- view_by -
    find_by :name, :design_doc => 'by_name', :view_name => 'by_name'



## What works?

### ActiveModel::Dirty

- record.changed?
- record.changed
- record.changes
- record.{attr}_changed?
- record.{attr}_was
- record.{attr}_change

### ActiveModel::Callbacks

:before, :after, and :around for :create, :destroy, :save, and :update

### ActiveModel::Validations

All standard ActiveModel Validations plus a custom:

    validates_uniqness_of :attr



