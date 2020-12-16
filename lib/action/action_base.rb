# typed: false
# frozen_string_literal:true

require_relative '../messages'
require_relative '../generation'
require_relative '../exception'
require_relative '../log'
require_relative '../factory_base'
require 'rainbow/refinement'
require 'sorbet-runtime'

using Rainbow

module SheepAst
  # TBD
  class ActionBase < SheepObject
    extend T::Sig
    extend T::Helpers
    include Exception
    include Generation
    include Log
    abstract!

    sig { returns(DataStore) }
    attr_accessor :data_store

    sig { returns(T.nilable(Symbol)) }
    attr_accessor :store_sym

    sig { returns(FactoryBase) }
    attr_accessor :action_factory

    sig { returns(FactoryBase) }
    attr_accessor :match_factory

    sig { void }
    def initialize
      super()
      @nq = false
    end

    sig { abstract.params(data: AnalyzeData, node: Node).returns(MatchAction) }
    def action(data, node); end

    sig { params(data: AnalyzeData).returns(T::Hash[Symbol, T.any(T::Array[String], String)]) }
    def keyword_data(data)
      hash = {}
      data.stack.each_with_index do |elem, index|
        key = data.stack_symbol[index]
        value = hash[key] unless key.nil?

        expr = match_factory.from_id(elem).matched_expr
        if value.nil?
          hash[key] = expr
        elsif value.instance_of?(Array)
          value << expr
        else
          hash[key] = [value, expr]
        end
      end

      stack = []
      data.file_info.namespace_stack.each do |elem|
        stack << elem unless elem.nil?
      end

      hash[:_namespace] = stack
      hash[:_raw_line] = data.raw_line
      hash[:_data] = data
      return hash
    end

    sig { params(data: AnalyzeData, key: Symbol).returns(MatchBase) }
    def get_match(data, key)
      test = data.stack_symbol.find_index { |i| i == key }
      application_error 'specified key does not found in stack_symbol' if test.nil?

      id_ = data.stack[test]
      match = match_factory.from_id(id_)
      application_error 'match did not found' if match.nil?

      return match
    end

    sig { params(data: AnalyzeData).returns(MatchBase) }
    def get_first_match(data)
      id_ = data.stack.first
      match = match_factory.from_id(id_)
      application_error 'match did not found' if match.nil?

      return match
    end

    sig { params(data: AnalyzeData).returns(MatchBase) }
    def get_last_match(data)
      id_ = data.stack.last
      match = match_factory.from_id(id_)
      application_error 'match did not found' if match.nil?

      return match
    end

    sig { params(data: AnalyzeData).returns(T::Boolean) }
    def really_end?(data)
      ldebug 'really_end'
      if @qualifier.nil?
        lfatal warning
        missing_impl
      else
        ret = @qualifier.qualify(data)
        ldebug "Really end? = #{ret}"
        return ret
      end
    end

    sig {
      params(qualifier: T.nilable(Qualifier)).void
    }
    def register_qualifier(qualifier)
      @qualifier = qualifier
    end

    sig { returns(T::Boolean) }
    def qualifier?
      if @qualifier.nil?
        return false
      else
        return true
      end
    end

    sig { void }
    def need_qualify
      @nq = true
    end

    sig { returns(T::Boolean) }
    def need_qualify?
      return @nq
    end

    sig { returns(String) }
    def inspect
      "custom inspect <#{self.class.name} object_id = #{object_id}, store_sym = #{store_sym.inspect}"
    end

    sig { returns(String) }
    def description
      name
    end

    sig { returns(String) }
    def warning
      errmsg = <<~ERRORMSG
        To reach here, it means that the node has action, but there are further nodes after this node like:
        root -> this_node -> this_action
                          -> another_node -> another_action
        In this case, qualification to continue node search or just do action is needed.
        You need to implement qualifier function.
      ERRORMSG
      return errmsg
    end
  end
end
