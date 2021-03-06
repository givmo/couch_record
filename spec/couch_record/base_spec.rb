require 'spec_helper'

def check_values(a)
  a.s.should == @str_values[:s]
  a.i.should == @str_values[:i].to_i
  a.t.should == Time.iso8601(@str_values[:t])
  a.d.should == Date.iso8601(@str_values[:d])
  a.sym.should == @str_values[:sym].to_sym
  a.bd.should == BigDecimal.new(@str_values[:bd])
end

def set_values(a)
  a.s = @str_values[:s]
  a.i = @str_values[:i]
  a.t = @str_values[:t]
  a.d = @str_values[:d]
  a.sym = @str_values[:sym]
  a.bd = @str_values[:bd]
end

describe CouchRecord::Base do

  before :all do
    @str_values = {
        :s => 'string',
        :i => '123',
        :t => '2011-06-07T09:23:00Z',
        :d => '2011-06-07',
        :sym => :symbol,
        :bd => '12.34'
    }

    class Record < CouchRecord::Base
      use_database :test

      property :x
      property :s, String
      property :i, Integer
      property :t, Time
      property :d, Date
      property :sym, Symbol
      property :bd, BigDecimal
      property :defaulted, String, :default => 'a default'

      timestamps!
    end

  end

  describe 'property' do
    it 'should return default values instead of nils' do
      a = Record.new
      a.defaulted.should == 'a default'
    end
  end


  describe 'create' do
    it 'should create a record and save data' do
      CouchRest.should_receive(:put)
      a = Record.new(@str_values)
      a.create
      a.id.should_not == nil
    end

  end

  describe 'update' do
    it 'should save data' do
      CouchRest.should_receive(:put).twice
      a = Record.new
      a.create
      set_values(a)
      a.update
    end

  end

  describe 'persisted?' do
    it 'should return true for saved records and false for new ones' do
      a = Record.new
      a.persisted?.should == false
      a.create
      a.persisted?.should == true
    end
  end

  describe 'timestamps!' do
    it 'should create properties for created_at and updated_at' do
      a = Record.new
      a.respond_to?(:created_at).should == true
      a.respond_to?(:created_at=).should == true
      a.respond_to?(:updated_at).should == true
      a.respond_to?(:updated_at=).should == true
    end

    it 'should set created_at and updated_at' do
      a = Record.new

      before_create = Time.iso8601(Time.now.utc.iso8601)
      a.create
      after_create = Time.iso8601(Time.now.utc.iso8601)
      a.created_at.should be_between(before_create, after_create)
      a.updated_at.should be_between(before_create, after_create)
      a.update
      after_update = Time.iso8601(Time.now.utc.iso8601)
      a.created_at.should be_between(before_create, after_create)
      a.updated_at.should be_between(after_create, after_update)
    end
  end

  describe 'merge_atributes' do
    before :all do
      class MergeRecord < CouchRecord::Base
        property :x, Integer
        property :y, Integer
        property :a, MergeRecord
        property :b, [MergeRecord]
        property :c, Hash

        attr_accessor :non_prop
      end
    end

    before :each do
      @r = MergeRecord.new(
          {
              :x => 1,
              :y => 1,
              :a => {:x => 2, :y => 2},
              :b => [{:x => 3, :y => 3}, {:x => 4, :y => 4}, {:x => 5, :y => 5}],
              :c => {:d => MergeRecord.new({:x => 6, :y => 6}, :raw => true), :e => MergeRecord.new({:x => 7, :y => 7}, :raw => true)}
          }, :raw => true
      )
    end

    it 'should only set passed attributes' do
      @r.merge_attributes(
          {
              :x => 0,
              :a => {:x => 0},
              :b => [{:x => 0}, {}],
              :c => {:d => {:x => 0}}
          })
      
      @r.x.should == 0
      @r.y.should == 1
      @r.a.x.should == 0
      @r.a.y.should == 2

      @r.b[0].x.should == 0
      @r.b[0].y.should == 3
      @r.b[1].x.should == 4
      @r.b[1].y.should == 4
      @r.b[2].x.should == 5
      @r.b[2].y.should == 5

      @r.c[:d].x.should == 0
      @r.c[:d].y.should == 6
      @r.c[:e].x.should == 7
      @r.c[:e].y.should == 7
    end

    it 'should set non-propery attributes' do
      @r.merge_attributes(
          {
              :x => 0,
              :non_prop => 1
          })

      @r.x.should == 0
      @r.non_prop.should == 1
    end
  end


end