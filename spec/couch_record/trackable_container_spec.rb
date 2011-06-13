require 'spec_helper'

describe CouchRecord::TrackableContainer do

  before :all do
    class DirtyTestRecord < CouchRecord::Base
      use_database :test
      
      property :a, [Integer]
      property :b, [Hash]
      property :c, DirtyTestRecord
      property :d, Hash

      property :clean_1, Date

      after_save :check_dirty

      def check_dirty
        clean_1_changed?.should == false
      end
    end
  end

  before :each do
    @r = DirtyTestRecord.new(
        {
            :a => [1, 2, 3],
            :b => [{}, {}, {:x => 3}],
            :c => {:a => [1]},
            :d => {:x => DirtyTestRecord.new({:a => 1}, :raw => true), :y => DirtyTestRecord.new({:a => 1}, :raw => true)}
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
      r = DirtyTestRecord.new(
        {
            :clean_1 => '2011-06-13'
        },
        :raw => true)

      r.a = []
      r.clean_1
      r.save #this should trigger the check_dirty callback and check clean_1
    end
  end

  describe 'Hash' do
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

  end

  describe 'Array' do
    after :each do
      @r.changed?.should == true
      @r.a_changed?.should == true
      @r.b_changed?.should == true
      @r.b.each do |hash|
        hash.should be_a CouchRecord::TrackableContainer
      end
    end

    describe '[]=' do
      it 'should mark the propery and the record as dirty' do
        @r.a[0] = 0
        @r.b[0] = {}
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
