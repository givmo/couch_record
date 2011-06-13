require 'rspec'
require 'couch_record'

RSpec.configure do |config|
  config.before(:each) do
    CouchRest.stub!(:put).and_return({'ok' => true, 'rev' => '1-12345', 'id' => '54321'})
    CouchRest.stub!(:post).and_return({'ok' => true, 'rev' => '2-12345', 'id' => '54321'})
    CouchRecord.server.stub!(:next_uuid).and_return('54321')
  end
end