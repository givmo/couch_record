module CouchRecord
  module Persistence
    extend ActiveSupport::Concern

    def save(options = {})
      self.new? ? create(options) : update(options)
    end

    def create(options = {})
      return false if options[:validate] != false && !valid?
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
      @changed_attributes.clear
    end

    def update(options = {})
      return false if options[:validate] != false && !self.valid?
      return true if options[:force] != true && !self.changed?

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
      @changed_attributes.clear
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
