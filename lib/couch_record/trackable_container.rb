module CouchRecord
  module TrackableContainer
    attr_accessor :parent_record
    attr_accessor :parent_attr

    def _track_change(key = nil, value = nil)
      if self.is_a?(CouchRecord::Base)
        self.attribute_will_change_to!(key, value)
      else
        # passing nil here works because the current value must be non nil for self to exist
        self.parent_record.attribute_will_change_to!(self.parent_attr, nil)
      end
    end

    def _make_trackable(value, attr = nil)
      newly_trackable = false
      if value.is_a?(Array) && !value.is_a?(TrackableContainer)
        value.extend TrackableArray
        newly_trackable = true
      elsif value.is_a?(Hash) && !value.is_a?(TrackableContainer)
        value.extend TrackableHash
        newly_trackable = true
      end

      if value.is_a? TrackableContainer
        if self.is_a?(CouchRecord::Base)
          value.parent_record = self
          value.parent_attr = attr.to_sym
        else
          value.parent_record = self.parent_record
          value.parent_attr = self.parent_attr
        end

        _make_children_trackable(value) if newly_trackable

      end
    end

    def _make_children_trackable(value = self)
      if value.is_a?(Array)
        value.each { |subvalue| value._make_trackable(subvalue, self.parent_attr) }
      elsif value.is_a?(Hash)
        value.each_value { |subvalue| value._make_trackable(subvalue, self.parent_attr) }
      end
    end

    module TrackableArray
      include TrackableContainer

      def []=(index, value)
        _make_trackable(value)
        _track_change
        super
      end

      def <<(value)
        _make_trackable(value)
        _track_change
        super
      end

      def clear()
        _track_change unless self.empty?
        super
      end

      def collect!
        _track_change
        super
        _make_children_trackable
      end

      def map!
        _track_change
        super
        _make_children_trackable
      end

      def compact!()
        _track_change
        super
      end

      def delete_at(index)
        _track_change
        super
      end

      def delete(value)
        _track_change
        super
      end

      def delete_if
        _track_change
        super
      end

      def reject!
        _track_change
        super
      end

      def fill(*args)
        _track_change
        super
        _make_children_trackable
      end

      def flatten!
        _track_change
        super
      end

      def replace(*args)
        _track_change
        super
        _make_children_trackable
      end

      def insert(*args)
        _track_change
        super
        _make_children_trackable
      end

      def keep_if(*args)
        _track_change
        super
      end

      def select!(*args)
        _track_change
        super
      end

      def pop(*args)
        _track_change unless self.empty?
        super
      end

      def push(obj, *smth)
        _track_change
        super
        _make_trackable obj
        _make_trackable smth
      end

      def reverse!(*args)
        _track_change
        super
      end

      def rotate!(*args)
        _track_change
        super
      end

      def shuffle!(*args)
        _track_change
        super
      end

      def slice!(*args)
        _track_change
        super
      end

      def sort!(*args)
        _track_change
        super
      end

      def sort_by!(*args)
        _track_change
        super
      end

      def uniq!(*args)
        _track_change
        super
      end

      def unshift(obj, *smth)
        _track_change
        super
        _make_trackable obj
        _make_trackable smth
      end


    end

    module TrackableHash
      include TrackableContainer

      def []=(key, value)
        _make_trackable(value, key)
        _track_change(key, value)
        super
      end

      def store(key, value)
        _make_trackable(value, key)
        _track_change(key, value)
        super
      end

      def clear
        _track_change
        super
      end

      def delete(key)
        _track_change(key)
        super
      end

      def delete_if
        _track_change
        super
      end

      def reject!
        _track_change
        super
      end

      def replace(other_hash)
        _track_change
        super
        _make_children_trackable
      end

      def keep_if
        _track_change
        super
      end

      def select!
        _track_change
        super
      end

      def merge!(other_hash)
        _track_change
        super
        _make_children_trackable
      end

      def update(other_hash)
        _track_change
        super
        _make_children_trackable
      end

    end
  end
end