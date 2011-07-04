require 'spec_helper'

describe CouchRecord::TrackableContainer do

  before :all do
    class DirtyTestRecord < CouchRecord::Base
      use_database :test

      property :a, [Integer]
      property :b, [Hash]
      property :c, DirtyTestRecord
      property :d, Hash
      property :e, Hash
      property :f, Array, :default => []

      property :clean_1, Date

      after_save :check_dirty

      def check_dirty
        clean_1_changed?.should == false
        c.clean_1_changed?.should == false
      end
    end
  end

  before :each do
    @r = DirtyTestRecord.new(
        {
            :a => [1, 2, 3],
            :b => [{}, {}, {:x => 3}],
            :c => {:a => [1]},
            :d => {:x => DirtyTestRecord.new({:a => [1]}, :raw => true), :y => DirtyTestRecord.new({:a => [2]}, :raw => true)},
        },
        :raw => true)

    @r.changed?.should == false
    @r.a_changed?.should == false
    @r.b_changed?.should == false
    @r.c_changed?.should == false
    @r.c.a_changed?.should == false
    @r.d_changed?.should == false
    @r.d[:x].a_changed?.should == false
    @r.d[:y].a_changed?.should == false
    @r.e_changed?.should == false
  end

  describe 'converting' do
    it 'should not dirty converted values' do
      r = DirtyTestRecord.new(
          {
              :clean_1 => '2011-06-13'
          },
          :raw => true)

      r.clean_1
      r.clean_1_changed?.should == false
    end
  end

  describe 'saving' do
    it 'should not dirty converted values' do
      r = DirtyTestRecord.new({:clean_1 => '2011-06-13', :c => {:clean_1 => '2011-06-13'}},
                              :raw => true)

      r.a = []
      r.clean_1
      r.c.clean_1
      r.save #this should trigger the check_dirty callback and check clean_1
    end
  end

  describe 'Hash changes' do
    after :each do
      @r.changed?.should == true
      @r.d_changed?.should == true
      @r.d.each_value do |value|
        value.should be_a CouchRecord::TrackableContainer
      end
    end

    describe '[]=' do
      it 'should mark the propery and the record as dirty' do
        @r.d[:y] = []
      end
    end

    describe 'store' do
      it 'should mark the propery and the record as dirty' do
        @r.d.store(:y, [])
      end
    end

    describe 'clear' do
      it 'should mark the propery and the record as dirty' do
        @r.d.clear
      end
    end

    describe 'delete' do
      it 'should mark the propery and the record as dirty' do
        @r.d.delete :y
      end
    end

    describe 'delete_if' do
      it 'should mark the propery and the record as dirty' do
        @r.d.delete_if { |key, value| key == :y }
      end
      it 'should mark the propery and the record as dirty' do
        @r.d.delete_if.each { |key, value| key == :y }
      end
    end

    describe 'reject!' do
      it 'should mark the propery and the record as dirty' do
        @r.d.reject! { |key, value| key == :y }
      end
    end

    describe 'replace' do
      it 'should mark the propery and the record as dirty' do
        @r.d.replace({:z => []})
      end
    end

    describe 'keep_if' do
      it 'should mark the propery and the record as dirty' do
        @r.d.keep_if { |key, value| key == :y }
      end
    end

    describe 'select!' do
      it 'should mark the propery and the record as dirty' do
        @r.d.select! { |key, value| key == :y }
      end
    end

    describe 'merge!' do
      it 'should mark the propery and the record as dirty' do
        @r.d.merge!({:y => [], :z => []})
      end
    end

    describe 'update' do
      it 'should mark the propery and the record as dirty' do
        @r.d.update({:y => [], :z => []}) do |key, v1, v2|
          []
        end
      end
    end

  end

  describe 'Hash non-changes' do
    after :each do
      @r.changed?.should == false
      @r.d_changed?.should == false
      @r.d.each_value do |value|
        value.should be_a CouchRecord::TrackableContainer
      end
      @r.e_changed?.should == false
    end

    describe '[]=' do
      it 'should not mark the propery and the record as dirty' do
        @r.d[:y] = @r.d[:y]
      end
    end

    describe 'store' do
      it 'should not mark the propery and the record as dirty' do
        @r.d.store(:y, @r.d[:y])
      end
    end

    describe 'clear' do
      it 'should not mark the propery and the record as dirty' do
        @r.e.clear
      end
    end

    describe 'delete' do
      it 'should not mark the propery and the record as dirty' do
        @r.d.delete :z
      end
    end

    describe 'delete_if' do
      it 'should not mark the propery and the record as dirty' do
        @r.d.delete_if { |key, value| false }
      end
    end

    describe 'reject!' do
      it 'should not mark the propery and the record as dirty' do
        @r.d.reject! { |key, value| false }
      end
    end

    describe 'keep_if' do
      it 'should not mark the propery and the record as dirty' do
        @r.d.keep_if { |key, value| true }
      end
    end

    describe 'select!' do
      it 'should not mark the propery and the record as dirty' do
        @r.d.select! { |key, value| true }
      end
    end

    describe 'merge!' do
      it 'should not mark the propery and the record as dirty' do
        @r.d.merge!(@r.d)
      end
    end

    describe 'update' do
      it 'should mark the propery and the record as dirty' do
        @r.d.update({:x => [], :y => []}) do |key, v1, v2|
          v1
        end
      end
    end

  end

  describe 'Array changes' do
    after :each do
      @r.changed?.should == true
      @r.a_changed?.should == true
      @r.b_changed?.should == true
      @r.b.each do |hash|
        next unless hash
        hash.should be_a CouchRecord::TrackableContainer
      end
    end

    describe '[]=' do
      it 'should mark the propery and the record as dirty' do
        @r.a[0] = 0
        @r.b[0] = nil
      end
    end

    describe '[1..2]=' do
      it 'should mark the propery and the record as dirty' do
        @r.a[1..2] = [0, 0]
        @r.a[1].should == 0
        @r.a[2].should == 0
        @r.b[1..2] = [{}, {}]
      end
    end

    describe '<<' do
      it 'should mark the propery and the record as dirty' do
        @r.a << 0
        @r.b << {}
      end
    end

    describe 'clear' do
      it 'should mark the propery and the record as dirty' do
        @r.a.clear
        @r.b.clear
      end
    end

    describe 'delete_at' do
      it 'should mark the propery and the record as dirty' do
        @r.a.delete_at 1
        @r.b.delete_at 1
      end
    end

    describe 'insert' do
      it 'should mark the propery and the record as dirty' do
        @r.a.insert(2, 0)
        @r.b.insert(2, {})
      end
    end

    describe 'map!' do
      it 'should mark the propery and the record as dirty' do
        @r.a.map! { |i| 0 }
        @r.b.map!.each { |i| {} }
      end
    end

    describe 'collect!' do
      it 'should mark the propery and the record as dirty' do
        @r.a.collect! { |i| 0 }
        @r.b.collect!.each { |i| {} }
      end
    end

    describe 'compact!' do
      it 'should mark the propery and the record as dirty' do
        @r = DirtyTestRecord.new(
            {
                :a => [1, nil, 3],
                :b => [{}, nil, {:x => 3}]
            }, :raw => true)

        @r.a.compact!
        @r.b.compact!
      end
    end

    describe 'delete' do
      it 'should mark the propery and the record as dirty' do
        @r.a.delete 1
        @r.b.delete({})
      end
    end

    describe 'delete_if' do
      it 'should mark the propery and the record as dirty' do
        @r.a.delete_if { |x| x == 2 }
        @r.b.delete_if.each { |x| x.empty? }
      end
    end

    describe 'reject!' do
      it 'should mark the propery and the record as dirty' do
        @r.a.reject! { |x| x == 2 }
        @r.b.reject!.each { |x| x.empty? }
      end
    end

    describe 'fill' do
      it 'should mark the propery and the record as dirty' do
        @r.a.fill { |i| 2 }
        @r.b.fill { |i| {} }
      end
    end

    describe 'replace' do
      it 'should mark the propery and the record as dirty' do
        @r.a.replace([1])
        @r.b.replace([{}])
      end
    end

    describe 'keep_if' do
      it 'should mark the propery and the record as dirty' do
        @r.a.keep_if { |x| x == 2 }
        @r.b.keep_if { |x| x.empty? }
      end
    end

    describe 'select!' do
      it 'should mark the propery and the record as dirty' do
        @r.a.select! { |x| x == 2 }
        @r.b.select! { |x| x.empty? }
      end
    end

    describe 'pop' do
      it 'should mark the propery and the record as dirty' do
        @r.a.pop
        @r.b.pop
      end
    end

    describe 'push' do
      it 'should mark the propery and the record as dirty' do
        @r.a.push 4
        @r.b.push({})
      end
    end

    describe 'reverse!' do
      it 'should mark the propery and the record as dirty' do
        @r.a.reverse!
        @r.b.reverse!
      end
    end

    describe 'rotate!' do
      it 'should mark the propery and the record as dirty' do
        @r.a.rotate! 2
        @r.b.rotate! 2
      end
    end

    describe 'shuffle!' do
      it 'should mark the propery and the record as dirty' do
        @r.a.shuffle!
        @r.b.shuffle!
      end
    end

    describe 'slice!' do
      it 'should mark the propery and the record as dirty' do
        @r.a.slice! 1, 1
        @r.b.slice! 1, 1
      end
    end

    describe 'sort!' do
      it 'should mark the propery and the record as dirty' do
        @r = DirtyTestRecord.new(
        {
            :a => [3, 2, 1]
        }, :raw => true)

        @r.a.sort!
        @r.b = [] # can't sort hashes
      end
    end

    describe 'sort_by!' do
      it 'should mark the propery and the record as dirty' do
        @r = DirtyTestRecord.new(
        {
            :a => [3, 2, 1]
        }, :raw => true)

        @r.a.sort_by! { |x| x }
        @r.b = [] # can't sort hashes
      end
    end

    describe 'uniq!' do
      it 'should mark the propery and the record as dirty' do
        @r = DirtyTestRecord.new(
        {
            :a => [1, 2, 2],
            :b => [{}, {}, nil]
        }, :raw => true)
        @r.a.uniq!
        @r.b.uniq!
      end
    end

    describe 'unshift' do
      it 'should mark the propery and the record as dirty' do
        @r.a.unshift 0, 5
        @r.b.unshift({}, {}, {})
      end
    end

  end

  describe 'Array special changes' do
    describe 'flatten!' do
      it 'should mark the propery and the record as dirty' do
        @r = DirtyTestRecord.new(
        {
            :f => [[1], [2, 3]]
        }, :raw => true)

        @r.f.flatten!
        @r.f.should == [1,2,3]
        @r.f_changed?.should == true
        @r.changed?.should == true
      end
    end

  end

  describe 'Array non-changes' do
    after :each do
      @r.changed?.should == false
      @r.a_changed?.should == false
      @r.b_changed?.should == false
      @r.b_changed?.should == false
      @r.b.each do |hash|
        hash.should be_a CouchRecord::TrackableContainer
      end
      @r.f_changed?.should == false
    end

    describe '[]=' do
      it 'should not mark the propery and the record as dirty' do
        @r.a[0] = 1
        @r.b[0] = {}
      end
    end

    describe '[1..2]=' do
      it 'should not mark the propery and the record as dirty' do
        @r.a[0..1] = [1, 2]
        @r.a[0].should == 1
        @r.a[1].should == 2
        @r.a[0,2] = [1,2]
        @r.a[0].should == 1
        @r.a[1].should == 2
        
        @r.b[0..1] = [{}, {}]
      end
    end

    describe 'clear' do
      it 'should not mark the propery and the record as dirty' do
        @r = DirtyTestRecord.new(
        {
            :a => []
        }, :raw => true)
        @r.a.clear
      end
    end

    describe 'delete_at' do
      it 'should not mark the propery and the record as dirty' do
        @r.a.delete_at 4
        @r.b.delete_at 4
      end
    end

    describe 'map!' do
      it 'should not mark the propery and the record as dirty' do
        @r.a.map! { |v| v }
        @r.b.map!.each { |v| v }
      end
    end

    describe 'collect!' do
      it 'should not mark the propery and the record as dirty' do
        @r.a.collect! { |v| v }
        @r.b.collect!.each { |v| v }
      end
    end

    describe 'compact!' do
      it 'should not mark the propery and the record as dirty' do
        @r.a.compact!
        @r.b.compact!
      end
    end

    describe 'delete' do
      it 'should not mark the propery and the record as dirty' do
        @r.a.delete 4
        @r.b.delete({:asd => 4})
      end
    end

    describe 'delete_if' do
      it 'should not mark the propery and the record as dirty' do
        @r.a.delete_if { |x| x == 4 }
        @r.b.delete_if.each { |x| x == {:asd => 4} }
      end
    end

    describe 'reject!' do
      it 'should not mark the propery and the record as dirty' do
        @r.a.reject! { |x| x == 4 }
        @r.b.reject!.each { |x| x == {:asd => 4} }
      end
    end

    describe 'fill' do
      it 'should not mark the propery and the record as dirty' do
        @r.a.fill { |i| @r.a[i] }
        @r.b.fill { |i| @r.b[i] }
      end
    end

    describe 'flatten!' do
      it 'should not mark the propery and the record as dirty' do
        @r.a.flatten!
        @r.b.flatten!
      end
    end

    describe 'replace' do
      it 'should not mark the propery and the record as dirty' do
        @r.a.replace(@r.a)
        @r.b.replace(@r.b)
      end
    end

    describe 'keep_if' do
      it 'should not mark the propery and the record as dirty' do
        @r.a.keep_if { |x| true }
        @r.b.keep_if { |x| true }
      end
    end

    describe 'select!' do
      it 'should not mark the propery and the record as dirty' do
        @r.a.select! { |x| true }
        @r.b.select! { |x| true }
      end
    end

    describe 'pop' do
      it 'should not mark the propery and the record as dirty' do
        @r.f.pop
      end
    end

    describe 'slice!' do
      it 'should not mark the propery and the record as dirty' do
        @r.a.slice! 1, 0
        @r.b.slice! 1, 0
      end
    end

    describe 'sort!' do
      it 'should not mark the propery and the record as dirty' do
        @r.a.sort!
      end
    end

    describe 'sort_by!' do
      it 'should not mark the propery and the record as dirty' do
        @r.a.sort_by! { |x| 1 }
        @r.b.sort_by! { |x| 1 }
      end
    end

    describe 'uniq!' do
      it 'should not mark the propery and the record as dirty' do
        @r = DirtyTestRecord.new(
        {
            :a => [1, 2, 3]
        }, :raw => true)
        @r.a.uniq!
      end
    end

  end

  describe 'setting nested values' do
    it 'should mark the propery and the record as dirty' do
      @r.b[2][:x] = 0
      @r.changed?.should == true
      @r.a_changed?.should == false
      @r.b_changed?.should == true
    end
  end

  describe 'setting values in nested CouchRecord' do
    it 'should mark the sub-record propery and record property and the record as dirty' do
      @r.c.a[0] = 0
      @r.a_changed?.should == false
      @r.c.a_changed?.should == true
      @r.c_changed?.should == true
      @r.changed?.should == true
    end
  end

  describe 'setting values in nested CouchRecord in an array' do
    it 'should mark the sub-record propery and record property and the record as dirty' do
      @r.d[:x].a = 0
      @r.changed?.should == true
      @r.a_changed?.should == false
      @r.d_changed?.should == true
      @r.d[:x].a_changed?.should == true
    end
  end
end
