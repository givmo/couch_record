module CouchRecord
  module Query
    extend ActiveSupport::Concern

    module ClassMethods
      def find(id)
        database.get_type id, self
      rescue RestClient::ResourceNotFound
      end

      def view_by(name, options = {})
        base_opts = _default_options_for(name).merge options
        method_name = base_opts.delete :method_name

        define_singleton_method method_name do |*args|
          view_path, params = _merge_options(args, base_opts)
          convert = params.delete :convert
          singular = params.delete :singular
          params[:limit] = 1 if singular

          results = database.view(view_path, params)['rows']
          if convert
            results.map! { |row| self.new(row['doc'], :raw => true) }
          end

          results = results.first if singular

          results
        end

      end

      def find_by(name, options = {})
        options[:include_docs] = true
        options[:convert] = true
        options[:method_name] = "find_by_#{name}" unless options[:method_name]
        view_by(name, options)
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

        case_insensitive = params.delete(:case_insensitive)
        [:key, :startkey, :endkey].each do |key|
          if params.has_key? key
            params[key] = _convert_for_save(params[key])
            params[key] = params[key].downcase if case_insensitive
          end
        end

        design_doc = params.delete :design_doc
        view_name = params.delete :view_name
        return "#{design_doc}/#{view_name}", params
      end

      private

      def _default_options_for(name)
        {
            :method_name => "view_by_#{name}",
            :design_doc => "by_#{name}",
            :view_name => "by_#{name}"
        }
      end


    end
  end
end
