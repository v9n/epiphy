require 'errors'

class Rethink
  include RethinkDB::Shortcuts
  include RethinkdbHelper
  include Errors

  def initialize
    create_connect_if_need 
    @r = @@r.table(self.class.name.downcase)
  end

  def all
    self
  end

  # Get a single element by primary key
  def single(id)
    @r = @r.get(id)
    self
  end

  # Return raw RethinkDB object
  def raw_query
    @r
  end
  
  def reset
    @r = @@r.table self.class.name.downcase
  end

  # Run a RQL
  def get(r=nil)
    if r.nil?
      r = @r
    end
    r.run(@@rdb_connection)
  end

  [:update, "get_all", :limit, :order_by, :slice, :count, :filter].each do |name|
    define_method(name) do |*arg, &block|
      @r = @r.send(name, *arg, &block)
      self
    end
  end 
  
  # Command work ona single object
  #{:destroy => :delete}.each do |public_name, name| 
    #define_method(public_name) do |*arg, &block|
      #r = @@r.table self.class.name.downcase
      #r.get(*arg)
      #r.send(name, *arg, &block)
      #r.run @@rdb_connection
    #end
  #end
  
  def destroy(id)
    r = @@r.table self.class.name.downcase
    r.get(id)
      .delete()
      .run(@@rdb_connection)
  end

  # Validation
  def self.validate(args)
    if args.has_key? :errors
      raise ValidationError.new('Bad request', args[:errors])
    end

    args
  end

  def self.validate_present(args, *keys)
    for k in keys
      unless args.has_key?(k) and args[k].present?
        args[:errors] ||= {}
        args[:errors][k] ||= []
        args[:errors][k] << "can't be blank."
      end
    end
    args
  end

  def self.validate_email(args)
    if args.has_key? :email
      args[:email].downcase!

      unless args[:email].present? and
        args[:email].match EMAIL_REGEX

        args[:errors] ||= {}
        args[:errors][:email] ||= []
        args[:errors][:email] << "is invalid."
      end
    end
    args
  end
end

