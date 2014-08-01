require 'helper'

describe Epiphy do
   it "has to hold current version" do
      Epiphy::VERSION.wont_be_nil
   end 
end
