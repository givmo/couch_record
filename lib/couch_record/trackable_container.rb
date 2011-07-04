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
          value.parent_attr = attr && attr.to_sym
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

      def []=(*args)
        value = args.last
        index = args.length == 2 ? args[0] : args[0..1]
        _make_trackable(value)
        if (index.is_a?(Array) && self[index[0], index[1]] != value) ||
            (!index.is_a?(Array) && self[index] != value)
          _track_change
        end
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

      def delete_at(index)
        _track_change if (0..self.length-1).include? index
        super
      end

      def insert(*args)
        _track_change
        super
        _make_children_trackable
      end

      def map!
        block_given? or return enum_for(__method__)
        each_with_index { |v, i| self[i] = yield(v) }
        self
      end
      alias :collect! :map!

      def compact!
        result = super
        _track_change unless result.nil?
        result
      end

      def delete(value)
        result = super
        _track_change unless result.nil?
        result
      end

      def delete_if
        block_given? or return enum_for(__method__)
        each_with_index { |v, i| delete_at(i) if yield(v) }
        self
      end

      def reject!
        block_given? or return enum_for(__method__)
        l = self.length
        each_with_index { |v, i| delete_at(i) if yield(v) }
        l == self.length ? nil : self
      end

      def fill(*args)
        old = self.clone
        super
        _track_change unless old == self
        _make_children_trackable
      end

      def flatten!(*args)
        result = super
        _track_change unless result.nil?
        result
      end

      def replace(*args)
        old = self.clone
        super
        _track_change unless old == self
        _make_children_trackable
      end

      def keep_if
        block_given? or return enum_for(__method__)
        each_with_index { |v, i| delete_at(i) unless yield(v) }
        self
      end

      def select!
        block_given? or return enum_for(__method__)
        l = self.length
        each_with_index { |v, i| delete_at(i) unless yield(v) }
        l == self.length ? nil : self
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
        result = super
        _track_change unless result.nil? || result.empty?
        result
      end

      def sort!
        old = self.clone
        super
        _track_change unless old == self
      end

      def sort_by!
        old = self.clone
        super
        _track_change unless old == self
      end

      def uniq!
        result = super
        _track_change unless result.nil?
        result
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
        _track_change(key, value) unless value == self[key]
        super
      end

      alias :store :[]=

      def clear
        _track_change unless self.empty?
        super
      end

      def delete(key)
        _track_change(key) if self.has_key? key
        super
      end

      def delete_if
        block_given? or return enum_for(__method__)
        self.each_pair { |key, value| self.delete(key) if yield(key, value) }
        self
      end

      def reject!
        block_given? or return enum_for(__method__)
        n = size
        delete_if { |key, value| yield(key, value) }
        size == n ? nil : self
      end

      def replace(other_hash)
        _track_change
        super
        _make_children_trackable
      end

      def keep_if
        block_given? or return enum_for(__method__)
        self.each_pair { |key, value| self.delete(key) unless yield(key, value) }
        self
      end

      def select!
        block_given? or return enum_for(__method__)
        n = size
        keep_if { |key, value| yield(key, value) }
        size == n ? nil : self
      end

      def merge!(other_hash)
        self.each_pair do |key, value|
          if other_hash.has_key? key
            new_value = block_given? ? yield(key, value, other_hash[key]) : other_hash[key]
            self[key] = new_value
          end
        end
        self
      end

      alias :update :merge!


    end
  end
end