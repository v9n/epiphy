require 'rubygems'
require 'json'
require 'rethinkdb'
include RethinkDB::Shortcuts

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'epiphy'


# Import yelp data set https://www.yelp.com/dataset_challenge/dataset
# Remember to create db first r.dbCreate('yelp')

Epiphy::Repository.configure do |config|
  config.adapter = Epiphy::Adapter::Rethinkdb.new Epiphy::Connection.create, database: :yelp
end

class Business
  include Epiphy::Entity
  self.attributes = :full_address, :hours, :open, :categories, :city, :review_count, :name, :neighborhoods, :longitude, :state, :stars, :latitude, :attributes, :type
end

class BusinessRepository
  include Epiphy::Repository
end
require 'pp'

# Clear old data
BusinessRepository.clear

# Inserting
count = 0
IO.foreach('/Volumes/MiscData/yelp/yelp_academic_dataset_business.json') do |line|
  count += 1
  puts count
  hash = JSON.parse line
  business = Business.new hash
  business.id = hash[:business_id]
  #pp business
  #business.business_id = nil
  BusinessRepository.create business
end

