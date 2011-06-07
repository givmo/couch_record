begin
  couchdb_config = YAML::load(ERB.new(IO.read(Rails.root.to_s + "/config/couchdb.yml")).result)
  couchdb_config = couchdb_conf[Rails.env] if defined?(Rails) && Rails.env
  url = couchdb_config["url"]
  COUCHDB_SERVER = CouchRest.new url
rescue
  raise "There was a problem with your config/couchdb.yml file. Check and make sure it's present and the syntax is correct."
end
