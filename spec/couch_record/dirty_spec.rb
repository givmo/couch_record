require 'couch_record'
describe 'CouchRecord::Dirty' do

  before :all do
    class Record < CouchRecord::Base
      property :a, [Integer]
      property :b, [Hash]
      property :c, Record
      property :d, Hash
      timestamps!
    end
  end

  before :each do
    @r = Record.new(
        {
            :a => [1, 2, 3],
            :b => [{}, {}, {:x => 3}],
            :c => {:a => [1]},
            :d => {:x => Record.new({:a => 1}, :raw => true)}
        },
        :raw => true)

    @r.changed?.should == false
    @r.a_changed?.should == false
    @r.b_changed?.should == false
    @r.c_changed?.should == false
    @r.c.a_changed?.should == false
    @r.d_changed?.should == false
    @r.d[:x].a_changed?.should == false
  end


  describe 'setting an array value' do
    it 'should mark the propery and the record as dirty' do
      @r.a[0] = 0
      @r.changed?.should == true
      @r.a_changed?.should == true
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
