module CouchRecord
  module Persistence
    extend ActiveSupport::Concern

    def save
      self.new? ? create : update
    end

    def create
      return false unless valid?
      _run_create_callbacks do
        _run_save_callbacks do
          if self.class._save_timestamps?
            now = Time.now
            self.created_at = now
            self.updated_at = now
          end
          convert_for_save(self)
          result = database.save_doc(self)
          result["ok"]
        end
      end
    end

    def update
      return false unless valid?
      _run_update_callbacks do
        _run_save_callbacks do
          if self.class._save_timestamps?
            self.updated_at = Time.now
          end
          convert_for_save(self)
          result = database.save_doc(self)
          result["ok"]
        end
      end
    end

    def destroy
      _run_destroy_callbacks do
        result = database.delete_doc(self)
        result['ok']
      end
    end

    private

    def do_save
    end



  end
end
