require 'couchrest'
require 'active_model'

module CouchRecord
  autoload :Base, 'couch_record/base'
  autoload :Types, 'couch_record/types'
  autoload :Database, 'couch_record/database'
  autoload :Query, 'couch_record/query'
  autoload :Persistence, 'couch_record/persistence'
end
