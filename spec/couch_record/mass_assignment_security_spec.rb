require 'spec_helper'

describe 'CouchRecord::MassAssignmentSecurity' do
  before :all do
    @attributes = {
        :a => 1,
        :b => {:a => 2, :a_x => 2},
        :c => [{:a => 3, :a_x => 3}],
        :a_x => 1,
        :b_x => {:a => 2, :a_x => 2},
        :c_x => [{:a => 3, :a_x => 3}]
    }
  end

  describe 'attr_accessible' do
    before :all do
      class Record < CouchRecord::Base
        property :a, Integer
        property :b, Record
        property :c, [Record]
        property :a_x, Integer
        property :b_x, Record
        property :c_x, [Record]

        attr_accessible :a
        attr_accessible :b
        attr_accessible :c
      end
    end

    describe 'passing an attribute hash to the constructor' do
      it 'should reject inaccessible properties' do
        r = Record.new(@attributes)

        r.a.should == 1
        r.b.a.should == 2
        r.b.a_x.should == nil
        r.c[0].a.should == 3
        r.c[0].a_x.should == nil
        r.a_x.should == nil
        r.b_x.a.should == nil
        r.c_x.should == []
      end
    end

    describe 'passing an attribute hash to attributes=' do
      it 'should reject inaccessible properties' do
        r = Record.new
        r.attributes = @attributes

        r.a.should == 1
        r.b.a.should == 2
        r.b.a_x.should == nil
        r.c[0].a.should == 3
        r.c[0].a_x.should == nil
        r.a_x.should == nil
        r.b_x.a.should == nil
        r.c_x.should == []
      end
    end

    describe 'passing an attribute hash to the constructor with :raw' do
      it 'should reject nothing' do
        r = Record.new(@attributes, :raw => true)

        r.a.should == 1
        r.b.a.should == 2
        r.b.a_x.should == 2
        r.c[0].a.should == 3
        r.c[0].a_x.should == 3
        r.a_x.should == 1
        r.b_x.a.should == 2
        r.b_x.a_x.should == 2
        r.c_x[0].a.should == 3
        r.c_x[0].a_x.should == 3
      end
    end

    describe 'setting an attribute directly' do
      it 'should reject nothing' do
        r = Record.new
        r.a = 1
        r.a_x = 1

        r.a.should == 1
        r.a_x.should == 1
      end
    end

  end

  describe 'attr_protected' do
    before :all do
      class Record < CouchRecord::Base
        property :a, Integer
        property :b, Record
        property :c, [Record]
        property :a_x, Integer
        property :b_x, Record
        property :c_x, [Record]

        attr_protected :a_x
        attr_protected :b_x
        attr_protected :c_x
      end
    end

    describe 'passing an attribute hash to the constructor' do
      it 'should reject inaccessible properties' do
        r = Record.new(@attributes)

        r.a.should == 1
        r.b.a.should == 2
        r.b.a_x.should == nil
        r.c[0].a.should == 3
        r.c[0].a_x.should == nil
        r.a_x.should == nil
        r.b_x.a.should == nil
        r.c_x.should == []
      end
    end

    describe 'passing an attribute hash to attributes=' do
      it 'should reject inaccessible properties' do
        r = Record.new
        r.attributes = @attributes

        r.a.should == 1
        r.b.a.should == 2
        r.b.a_x.should == nil
        r.c[0].a.should == 3
        r.c[0].a_x.should == nil
        r.a_x.should == nil
        r.b_x.a.should == nil
        r.c_x.should == []
      end
    end

    describe 'passing an attribute hash to the constructor with :raw' do
      it 'should reject nothing' do
        r = Record.new(@attributes, :raw => true)

        r.a.should == 1
        r.b.a.should == 2
        r.b.a_x.should == 2
        r.c[0].a.should == 3
        r.c[0].a_x.should == 3
        r.a_x.should == 1
        r.b_x.a.should == 2
        r.b_x.a_x.should == 2
        r.c_x[0].a.should == 3
        r.c_x[0].a_x.should == 3
      end
    end

    describe 'setting an attribute directly' do
      it 'should reject nothing' do
        r = Record.new
        r.a = 1
        r.a_x = 1

        r.a.should == 1
        r.a_x.should == 1
      end
    end

  end
end