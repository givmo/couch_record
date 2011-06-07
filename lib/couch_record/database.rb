module CouchRecord
  class Database < CouchRest::Database
    def get_type(id, type, params = {})
      slug = escape_docid(id)
      url = CouchRest.paramify_url("#{@root}/#{slug}", params)
      result = CouchRest.get(url)
      return result unless result.is_a?(Hash)
      doc = if /^_design/ =~ result["_id"]
        Design.new(result)
      else
        type.new(result)
      end
      doc.database = self
      doc
    end
  end
end
