module CouchRecord
  class Railtie < Rails::Railtie
    rake_tasks do
      load "tasks/couch_record.rake"
    end
  end
end