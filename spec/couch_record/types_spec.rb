require 'spec_helper'

describe 'CouchRecord::Types' do
  before :all do
    @attributes = {
        :t => '2011-06-12T16:14:12Z',
        :d => '2011-06-12',
        :sym => 'abc',
        :bd => '12.34',
        :r => {:x => 'qwerty'}
    }

    class Record < CouchRecord::Base
      property :x
      property :s, String
      property :i, Integer
      property :t, Time
      property :d, Date
      property :b, TrueClass
      property :sym, Symbol
      property :bd, BigDecimal
      property :defaulted, String, :default => 'a default'
      property :r, Record
    end

  end

  def check_types(r)
    r.t.should == Time.iso8601(@attributes[:t])
    r.d.should == Date.iso8601(@attributes[:d])
    r.sym.should == :abc
    r.bd.should == BigDecimal.new(@attributes[:bd])
    r.r.x.should == @attributes[:r][:x]
  end


  describe 'setting raw values' do
    it 'should convert to the given type when caling the setters' do
      r = Record.new
      r.t = @attributes[:t]
      r.d = @attributes[:d]
      r.sym = @attributes[:sym]
      r.bd = @attributes[:bd]
      r.r = @attributes[:r]
      check_types(r)
    end

    it 'should convert to the given type when using new' do
      r = Record.new(@attributes)
      check_types(r)
    end

    it 'should convert to the given type when using new(:raw)' do
      r = Record.new(@attributes, :raw => true)
      check_types(r)
    end

  end

  describe 'setting booleans' do
    it 'should convert string values to booleans' do
      r = Record.new
      r.b.should == nil
      r.b = 'true'
      r.b.should == true
      r.b = 'false'
      r.b.should == false
      r.b = ''
      r.b.should == nil
      r.b = '1'
      r.b.should == true
      r.b = '0'
      r.b.should == false
    end
  end

end