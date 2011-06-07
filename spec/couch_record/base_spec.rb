require "spec_helper"

describe CouchRecord::Base do
  describe 'use_database' do
    it 'should create a database connection' do
      class Record < CouchRecord::Base
        use_database :test
      end
    end
  end
end