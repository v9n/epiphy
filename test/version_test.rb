require 'helper'

describe Epiphy do
   it "has to hold current version" do
      Epiphy::VERSION.must_equal '0.1.1'
   end 
end
