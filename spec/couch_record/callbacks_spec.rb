require 'spec_helper'

describe 'CouchRecord::Callbacks' do
  before :all do
    class Record < CouchRecord::Base
      use_database :test
      
      property :x

      before_create :before_create_
      around_create :around_create_
      after_create :after_create_
      before_save :before_save_
      around_save :around_save_
      after_save :after_save_
      before_update :before_update_
      around_update :around_update_
      after_update :after_update_

    end

  end

  describe 'create callbacks' do
    it 'should call before/around/after for create/save' do
      r = Record.new
      r.should_receive(:before_create_)
      r.should_receive(:around_create_).and_yield
      r.should_receive(:after_create_)
      r.should_receive(:before_save_)
      r.should_receive(:around_save_).and_yield
      r.should_receive(:after_save_)
      r.create
    end
  end

  describe 'update callbacks' do
    it 'should call before/around/after for update/save' do
      r = Record.new
      r.id = '12345'
      r['_rev'] = '1-sdfds'
      r.should_receive(:before_update_)
      r.should_receive(:around_update_).and_yield
      r.should_receive(:after_update_)
      r.should_receive(:before_save_)
      r.should_receive(:around_save_).and_yield
      r.should_receive(:after_save_)
      r.update
    end
  end

end