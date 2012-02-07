namespace :couch_record do
  task :push => :environment do
    view_path = 'db/couch'
    Dir.glob(File.join(Rails.root, view_path, '*')).each do |db_dir|
      db_name = File.basename(db_dir)
      db_conn = CouchRecord.server.database(db_name)

      # Assemble views for each design document
      Dir.glob(File.join(db_dir, '*')).each do |design_doc_file|
        views = {}
        design_doc_name = derive_design_doc_name(design_doc_file)

        begin
          couchdb_design_doc = db_conn.get("_design/#{design_doc_name}")
        rescue RestClient::ResourceNotFound
          db_conn = CouchRecord.server.database!(db_name)
          couchdb_design_doc = db_conn.get("_design/#{design_doc_name}") rescue nil
        end

        file_extension = File.extname(design_doc_file)
        if file_extension == '.js'
          parser = ViewParser.new(design_doc_file, design_doc_name, couchdb_design_doc)
        else
          parser = NoopParser.new(design_doc_file, design_doc_name, couchdb_design_doc)
        end

        if parser.changed
          db_conn.save_doc(parser.doc)
          puts "Pushed views to #{db_name}/#{design_doc_name}\n"
        end

      end

      # delete views that no longer exist
      deleted_views_file = 'db/deleted_couch_views'
      deleted_views = (File.readlines deleted_views_file).each { |l| l.strip! }
      deleted_views.each do |view_file|
        view_file = view_file.sub! "#{db_name}/", ''
        if view_file
          design_doc_name = derive_design_doc_name(view_file)
          couchdb_design_doc = db_conn.get("_design/#{design_doc_name}") rescue nil
          if couchdb_design_doc
            db_conn.delete_doc(couchdb_design_doc)
            puts "Deleted views at #{db_name}/#{design_doc_name}\n"
          end
        end
      end

    end

  end
end

def derive_design_doc_name(design_doc_file)
  File.basename(design_doc_file, File.extname(design_doc_file))
end

class NoopParser
  attr_reader :changed
  attr_reader :doc

  def initialize(filename, design_doc_name, couchdb_design_doc)
    @doc = JSON.parse(File.read(filename))
    @doc['_id'] = "_design/#{design_doc_name}"
    @changed = true

    if couchdb_design_doc
      @doc['_rev'] = couchdb_design_doc['_rev']
      @changed = (@doc['views'] != couchdb_design_doc['views'])
    end
  end
  
end

class ViewParser
  attr_reader :changed
  attr_reader :doc

  def initialize(filename, design_doc_name, couchdb_design_doc)
    @doc = couchdb_design_doc
    views = {}

    file = File.open(filename)
    while start_line = get_next_start_line(file)
      name, function = start_line.split('=')
      name.strip!
      function.strip!

      unless function.end_with? ';'
        function += get_rest_of_function(file)
      end

      # remove ';'
      function = function.rstrip[0..-2]
      function = nil if function == 'null'

#          puts "#{name} = #{function}"
      if (name == 'map')
        map = function
      else
        views[name] = function
      end
    end

    views[design_doc_name] = nil if views.empty?

    views.merge!(views) do |name, function, x|
      view = {'map' => map}
      view['reduce'] = function unless function.nil?
      view
    end

    # new design doc?
    if @doc.nil?
      @doc = {
          "_id" => "_design/#{design_doc_name}",
          'language' => 'javascript'
      }
    end

    @changed = (@doc['views'] != views)
    @doc['views'] = views

  end

  protected

  def get_next_start_line(file)
    while line = file.gets do
      line.strip!
      break unless line.empty? || line.start_with?('//')
    end

    line
  end

  def get_rest_of_function(file)
    rest = $/
    while line = file.gets do
      rest += line
      line.strip!
      break if line == '};'
    end

    rest
  end

end
