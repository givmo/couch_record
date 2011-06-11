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

        parser = ViewParser.new(design_doc_file)
        parser.views[design_doc_name] = nil if parser.views.empty?

        parser.views.each do |name, function|
          views[name] = {}
          views[name]['map'] = parser.map
          views[name]['reduce'] = function unless function.nil?
        end

        # new design doc?
        if couchdb_design_doc.nil?
          couchdb_design_doc = {
              "_id" => "_design/#{design_doc_name}",
              'language' => 'javascript'
          }
        end

        if couchdb_design_doc['views'] == views
          puts "Ignoring unchanged views in #{db_name}/#{design_doc_name}\n"
          next
        else
          couchdb_design_doc['views'] = views
          db_conn.save_doc(couchdb_design_doc)
          puts "Pushed views to #{db_name}/#{design_doc_name}: #{views.keys.join(', ')}\n"
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

class ViewParser
  attr_reader :map
  attr_reader :views

  def initialize(filename)
    @views = {}

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
        @map = function
      else
        @views[name] = function
      end
    end
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
