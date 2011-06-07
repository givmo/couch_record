require 'couchrest'
require 'active_model'

module CouchRecord
  autoload :Base, 'couch_record/base'
  autoload :Types, 'couch_record/types'
  autoload :Database, 'couch_record/database'
  autoload :Query, 'couch_record/query'
  autoload :Persistence, 'couch_record/persistence'
  autoload :Validations, 'couch_record/validations'

  class << self
    def server
      @server ||= begin
        couchdb_config = YAML::load(ERB.new(IO.read(Rails.root.to_s + "/config/couchdb.yml")).result)
        couchdb_config = couchdb_config[Rails.env] if defined?(Rails) && Rails.env
        url = couchdb_config["url"]
        CouchRest.new url
      end
    end
  end
end
