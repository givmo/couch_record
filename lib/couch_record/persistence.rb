module CouchRecord
  module Persistence
    extend ActiveSupport::Concern

    def save(options = {})
      self.new? ? create(options) : update(options)
    end

    def create(options = {})
      return false if options[:validate] != false && !valid?

      result = false

      _run_create_callbacks do
        _run_save_callbacks do
          set_timestamps(:create)
          result = _do_save
        end
      end

      @changed_attributes.clear if @changed_attributes && result

      result
    end

    def update(options = {})
      return false if options[:validate] != false && !self.valid?

      result = false

      _run_update_callbacks do
        _run_save_callbacks do
          return true if options[:force] != true && !self.changed?
          set_timestamps
          result = _do_save
        end
      end

      @changed_attributes.clear if @changed_attributes && result

      result
    end

    def update_attributes(attributes)
      self.merge_attributes(attributes)
      self.save
    end

    def destroy
      _run_destroy_callbacks do
        result = database.delete_doc(self)
        result['ok']
      end
    end

    def set_timestamps(which = :update)
      if self.class._save_timestamps?
        now = Time.now
        self.created_at = now if which == :create
        self.updated_at = now
      end
    end

    def _do_save
      # set any defaults
      self.class._defaulted_properties.each { |attr| self.send(attr) }
      convert_for_save(self)
      result = database.save_doc(self)
      result['ok']
    end


  end
end
