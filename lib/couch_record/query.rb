module CouchRecord
  module Query
    extend ActiveSupport::Concern

    module ClassMethods
      def find(id)
        #TODO
        id = id[0] if id.is_a? Array
        database.get_type id, self
      end
      alias_method :get, :find

      def reduce_by(name, options = {})
        options[:reduce] = true
        map_by(name, options)
      end

      def map_by(name, options = {})
        default_opts = _default_options_for(name)
        base_opts = default_opts.merge options

        reduce = base_opts.delete :reduce
        singular = base_opts.delete :singular

        map_or_reduce = reduce ? 'reduce' : 'map'

        define_singleton_method "#{map_or_reduce}_by_#{name}" do |*args|
          view_path, params = _merge_options(args, base_opts)
          raw = params.delete :raw

          results = database.view(view_path, params)

          if raw
            return results
          elsif singular
            return results['rows'][0] && results['rows'][0]['value']
          else
            return results['rows']
          end
        end
      end

      def find_by(name, options = {})
        default_opts = _default_options_for(name)
        default_opts[:include_docs] = true
        base_opts = default_opts.merge options

        define_singleton_method "find_by_#{name}" do |*args|
          view_path, params = _merge_options(args, base_opts)

          singular = params.delete :singular
          params[:limit] = 1 if singular

          results = database.view(view_path, params)['rows']
          results.map! { |row| self.new(row['doc'])}

          if (singular)
            return results.first
          else
            return results
          end
        end

        self.class_eval("class << self; alias_method :by_#{name}, :find_by_#{name}; end")
      end

      def _merge_options(args, base_opts)
        params = base_opts.dup

        args.each do |arg|
          if arg.is_a? Hash
            params.merge! arg
          else
            params[:key] = arg
          end
        end

        design_doc = params.delete :design_doc
        view_name = params.delete :view_name
        return "#{design_doc}/#{view_name}", params
      end

      private

      def _default_options_for(name)
        {
            :design_doc => "by_#{name}",
            :view_name => "by_#{name}"
        }
      end


    end
  end
end
