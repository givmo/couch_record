require 'rspec'
require 'couch_record'

describe CouchRecord::TrackableContainer do

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
            :d => {:x => Record.new({:a => 1}, :raw => true), :x => Record.new({:a => 1}, :raw => true)}
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
        @r.d.delete_if {|key, value| key == :y }
      end
    end

    describe 'reject!' do
      it 'should mark the propery and the record as dirty' do
        @r.d.reject! {|key, value| key == :y }
      end
    end

    describe 'replace' do
      it 'should mark the propery and the record as dirty' do
        @r.d.replace({:z => []})
      end
    end

    describe 'keep_if' do
      it 'should mark the propery and the record as dirty' do
        @r.d.keep_if {|key, value| key == :y }
      end
    end

    describe 'select!' do
      it 'should mark the propery and the record as dirty' do
        @r.d.select! {|key, value| key == :y }
      end
    end

    describe 'merge!' do
      it 'should mark the propery and the record as dirty' do
        @r.d.merge!({:y => [], :z => []})
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

    describe 'map!' do
      it 'should mark the propery and the record as dirty' do
        @r.a.map! { |i| 0 }
        @r.b.map! { |i| {} }
      end
    end

    describe 'collect!' do
      it 'should mark the propery and the record as dirty' do
        @r.a.collect! { |i| 0 }
        @r.b.collect! { |i| {} }
      end
    end

    describe 'compact!' do
      it 'should mark the propery and the record as dirty' do
        @r.a.compact!
        @r.b.compact!
      end
    end

    describe 'delete_at' do
      it 'should mark the propery and the record as dirty' do
        @r.a.delete_at 1
        @r.b.delete_at 1
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
        @r.b.delete_if { |x| x.empty? }
      end
    end

    describe 'reject!' do
      it 'should mark the propery and the record as dirty' do
        @r.a.reject! { |x| x == 2 }
        @r.b.reject! { |x| x.empty? }
      end
    end

    describe 'fill' do
      it 'should mark the propery and the record as dirty' do
        @r.a.fill { |i| 2 }
        @r.b.fill { |i| {} }
      end
    end

    describe 'flatten!' do
      it 'should mark the propery and the record as dirty' do
        @r.a.flatten!
        @r.b.flatten!
      end
    end

    describe 'replace on an array value' do
      it 'should mark the propery and the record as dirty' do
        @r.a.replace([0, 0])
        @r.b.replace([{}, {}])
      end
    end

    describe 'insert on an array value' do
      it 'should mark the propery and the record as dirty' do
        @r.a.insert(2, 0)
        @r.b.insert(2, {})
      end
    end

    describe 'keep_if on an array value' do
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

    describe 'pop on an array value' do
      it 'should mark the propery and the record as dirty' do
        @r.a.pop
        @r.b.pop
      end
    end

    describe 'push on an array value' do
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
        @r.a.sort!
        @r.b = [] # can't sort hashes
      end
    end

    describe 'sort_by!' do
      it 'should mark the propery and the record as dirty' do
        @r.a.sort_by! { |x| x }
        @r.b.sort_by! { |x| 1 }
      end
    end

    describe 'uniq!' do
      it 'should mark the propery and the record as dirty' do
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
