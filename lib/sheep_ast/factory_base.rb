# typed: true
# frozen_string_literal:true

require_relative 'log'
require_relative 'exception'
require_relative 'sheep_obj'
require_relative 'node_buf'

module SheepAst
  # This object is base object of the sheep fuctory pattern
  # Factory abstract/wrap instanciation process and it absorb change impact inside the framework
  #
  # @api private
  #
  module FactoryBase
    extend T::Sig
    include Log
    include Exception

    sig { returns(Node) }
    attr_reader :root_node

    sig { returns(String) }
    attr_accessor :my_name

    sig { returns(FactoryBase) }
    attr_accessor :my_factory

    sig { returns(Time) }
    attr_accessor :ctime

    sig { returns(FactoryBase) }
    attr_accessor :match_factory

    sig { returns(ActionFactory) }
    attr_accessor :action_factory

    sig { returns(DataStore) }
    attr_accessor :data_store

    sig { void }
    def initialize
      @ctime = Time.new
      @id_store = []
      @name_hash = {}
      @current_id = -1
      super()
    end

    sig { returns(String) }
    def inspect
      "custom inspect <#{self.class.name} object_id = #{object_id}, my_name = #{@my_name}>"
    end

    sig {
      params(
        obj: SheepObject,
        name: T.nilable(String)
      ).returns(Integer)
    }
    def create_id(obj, name = nil)
      @current_id += 1
      @id_store.push obj
      obj.my_id = @current_id

      unless name.nil?
        bind_name(name, @current_id)
      end

      ldebug2 "id = #{@current_id}, obj.my_id = #{obj.my_id} registrated object_id = #{obj.object_id}, name = '#{name}'"
      return @current_id
    end

    sig { params(id: T.nilable(Integer)).returns(SheepObject) }
    def from_id(id)
      ids = @id_store[id]

      ldebug2 "id = #{id}, obj.my_id = #{ids.my_id}, returned object_id = #{ids.object_id}"
      return ids
    end

    sig { params(name: String).returns(SheepObject) }
    def from_name(name)
      id = @name_hash[name]
      application_error "specified name = '#{name}' does not exist" if id.nil?

      return from_id(id)
    end

    sig { params(name: String).returns(T::Boolean) }
    def name_defined?(name)
      return true if @name_hash.key?(name)

      return false
    end

    sig { params(name: String, id: Integer).void }
    def bind_name(name, id)
      if @name_hash.key?(name)
        application_error "same name is already registered '#{name}'"
      end

      @name_hash[name] = id
    end

    sig { params(name: String).returns(FactoryBase) }
    def get_factory(name)
      @factories.each do |fac|
        if fac.my_name == name
          return fac
        end
      end
      application_error 'factory not found'
    end
  end
end
