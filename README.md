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

      find_by :name
    end

Each property declaration creates a getter and setter for the property that handle conversion to and from the specified type.

### Supported Types

- *String*
- *Integer*
- *TrueClass* - for booleans
- *Date* - stored as a string in iso8601 format
- *Time* - stored as a string in iso8601 format
- *BigDecimal* - stored as a string
- other models that extend *CouchRecord::Base*
- *Array* -  of the above types
- *Hash* - of the above types

## Queries

All queries are explicitly declared, just like the way CouchDB works.  CouchRecord provides 2 ways to create querying methods on the record class:

- *view_by* - generates a query method that returns raw rows from the database
- *find_by* - generates a query method that returns records of the model class, using the :include_docs query parameter

    find_by :name, :singular => true

Options

- *:design_doc* - defaults to "by_#{name}"
- *:view_name* - defaults to "by_#{name}"
- *:singular* - sets :limit => 1 on the query and returns the first row or record instead of an array
- *:case_insensitive* - downcases :key, :startkey, and :endkey when passed as parameters to the query method.  You're responsible for making sure your view doncases the values being indexed.
- any other options are passed as parameters on the query, so you can use :limit, :descending, etc.


## View Files

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



