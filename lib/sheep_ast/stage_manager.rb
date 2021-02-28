# typed: true
# frozen_string_literal: true

require_relative 'exception'
require_relative 'messages'
require_relative 'datastore'
require 'rainbow/refinement'
require 'sorbet-runtime'

using Rainbow

module SheepAst
  # Handle order delegation of analyze to Ast Maanger
  #
  # @api private
  #
  # rubocop: disable all
  class Stage
    extend T::Sig
    extend T::Helpers
    include Exception
    include Log

    sig { returns(AstManager) }
    attr_accessor :ast

    sig { returns(T.nilable(NodeInfo)) }
    attr_accessor :info

    sig { returns(T::Array[Integer]) }
    attr_accessor :match_id_array

    sig { returns(T::Array[T.nilable(Symbol)]) }
    attr_accessor :match_symbol_array

    def initialize(ast)
      super()
      @ast = ast
      init
      @committed_node_id = 0
    end

    sig { returns(Node) }
    def current_node
      node = @ast.node_factory.from_id(T.must(info).node_id)
      if node.nil?
        application_error 'current node is not found. Bug?'
      end
      return node
    end

    sig { params(info: NodeInfo).void }
    def put_stack(info)
      if info.status != MatchStatus::NotFound &&
         info.status != MatchStatus::ConditionMatchingProgress &&
         info.status != MatchStatus::ConditionMatchingAtEnd &&
         info.status != MatchStatus::ConditionEndButMatchingProgress
        @match_id_array << info.match_id
        @match_symbol_array << info.store_symbol
        ldebug "match_id_array = #{@match_id_array.inspect}"
        ldebug "match_symbol = #{@match_symbol_array.inspect}"
      end
    end

    sig { params(data: AnalyzeData).returns(T.nilable(T::Boolean)) }
    def analyze(data) # rubocop: disable all
      node = @ast.node_factory.from_id(T.must(info).node_id)
      ldebug "analyze start, node_id = #{T.must(info).node_id}, object_id =  #{node.object_id}, data = #{data.inspect}"
      ret_node_info = @ast.find_next_node(data, node)
      ldebug "#{name} matched! => info = #{ret_node_info.inspect} for data = #{data.inspect}"

      put_stack(ret_node_info)
      data.stack = @match_id_array.dup
      data.stack_symbol = @match_symbol_array.dup

      after_action = MatchAction::Abort

      case ret_node_info.status
      when MatchStatus::NotFound
        if match_id_array.length.zero?
          after_action = @ast.not_found(data, node)
        else
          after_action = @ast.not_found_in_progress(data, node)
        end
      when MatchStatus::ConditionMatchingStart
        after_action = @ast.condition_start(data, node)
      when MatchStatus::ConditionMatchingProgress
        after_action = @ast.condition_in_progress(data, node)
      when MatchStatus::MatchingProgress
        after_action = @ast.in_progress(data, node)
      when MatchStatus::ConditionEndButMatchingProgress
        after_action = @ast.condition_end_but_in_progress(data, node)
      when MatchStatus::AtEnd, MatchStatus::ConditionMatchingAtEnd
        node = @ast.node_factory.from_id(T.must(ret_node_info).node_id)
        application_error 'node is not got' if node.nil?

        ldebug "Invoking action my node id = #{node.my_id}"
        after_action = @ast.at_end(data, node)
      else
        application_error "Unknown status #{ret_node_info.status}"
      end

      return handle_after_action(after_action, data, ret_node_info)
    end

    sig { params(info: NodeInfo).void }
    def move_node(info)
      T.must(@info).copy(info)
    end

    def move_committed_node
      node_info = NodeInfo.new
      node_info.node_id = @committed_node_id
      move_node(node_info)
    end

    def commit_node
      @committed_node_id = T.must(@info).node_id
    end


    sig { params(after_action: MatchAction, data: AnalyzeData, info: NodeInfo).returns(T.nilable(T::Boolean)) }
    def handle_after_action(after_action, data, info) # rubocop: disable all
      ldebug "#{name} decided to #{after_action.inspect} for the '#{data.expr.inspect}'"
      case after_action
      when MatchAction::Abort
        expression_not_found "'#{data.expr.inspect}'"
      when MatchAction::LazyAbort
        return nil
      when MatchAction::StayNode
        return true
      when MatchAction::Next
        move_node(info)
        return true
      when MatchAction::Continue
        init
        return false
      when MatchAction::Finish
        move_node(info)
        save_req = nil
        if !data.save_request.nil?
          save_req = data.save_request
          data.save_request = nil
        end
        init
        handle_save_request(data, save_req) unless save_req.nil?

        return true
      else
        application_error "Match action #{after_action} is not defined"
      end
    end

    sig { params(data: AnalyzeData, save_req: SaveRequest).void }
    def handle_save_request(data, save_req)
      ldebug "handle_save_request save_req = #{save_req.inspect}"
      T.must(data.file_manager).register_next_chunk(T.must(save_req.chunk)) unless save_req.chunk.nil?
      T.must(data.file_manager).register_next_file(T.must(save_req.file)) unless save_req.file.nil?
      T.must(data.file_manager).ast_include_set(save_req.ast_include)
      T.must(data.file_manager).ast_exclude_set(save_req.ast_exclude)
      T.must(data.file_manager).put_namespace(save_req.namespace)
    end

    sig { returns(String) }
    def name
      return ast.full_name
    end

    sig { params(logs: Symbol).void }
    def dump_tree(logs)
      ast.dump_tree(logs)
    end

    sig { params(logs: Symbol).void }
    def dump_stack(logs)
      logf = method(logs)
      str = ''.dup
      match_id_array.each do |id|
        a_match = @ast.match_factory.from_id(id)
        application_error "match from id=#{id} not found" if a_match.nil?

        str += "#{a_match.matched_expr.inspect} => "
      end
      4.times { str.chop! }
      if str.empty? || str.nil?
        str = 'None'
      end
      logf.call str, :yellow
    end

    sig { params(other: Stage).returns(Stage) }
    def copy(other)
      T.must(@info).copy(T.must(other.info))
      @match_id_array = other.match_id_array.dup
      @match_symbol_array = other.match_symbol_array.dup
      return self
    end

    sig { params(other: Stage).returns(Stage) }
    def save(other)
      T.must(@info).copy(T.must(other.info))
      @match_id_array = []
      @match_symbol_array = []
      return self
    end

    sig { returns(String) }
    def inspect
      "custom inspect <#{self.class.name} object_id = #{object_id}, ast = #{@ast.inspect},"\
        " info = #{@info.inspect}, match_id_array = #{@match_id_array.inspect},"\
        " match_symbol_array = #{@match_symbol_array.inspect} >"
    end

    sig { void }
    def init
      ldebug "#{name.inspect} init the node_info now. the info was #{@info.inspect}, match_id_array =>"\
        " #{@match_id_array.inspect}, match_stack => #{@match_symbol_array.inspect}"
      @info = NodeInfo.new if @info.nil?
      @info.init
      @match_id_array = []
      @match_symbol_array = []
    end
  end

  # StageManager manages stages.
  class StageManager
    extend T::Sig
    extend T::Helpers
    include Exception
    include Log

    sig { void }
    def initialize
      @stages = []
      @stages_name = {}
      @save_stages = [{}]
      super()
    end

    sig { params(ast: AstManager).void }
    def add_stage(ast)
      if ast.full_name.nil? || @stages_name.key?(ast.full_name)
        lfatal "debug => #{@stages_name.keys} is listed, #{ast.full_name} to be added."
        application_error 'ast name should be not nil and not duplicate'
      end

      a_stage = Stage.new(ast)
      @stages_name[ast.full_name] = a_stage
      @stages << a_stage
    end

    sig { params(name: String).returns(Stage) }
    def stage_get(name)
      res = @stages_name[name]
      application_error 'specified name does not hit any stage' unless res
     
      return res
    end

    sig {
      params(
        incl: T::Array[T.any(String, Regexp)],
        excl: T.nilable(T::Array[T.any(String, Regexp)]),
        domain: String,
        full_name: String
      ).returns(T::Boolean)
    }
    def filter?(incl, excl, domain, full_name) # rubocop: disable all
      return true if domain == 'always'

      ret = T.let(false, T::Boolean)
      incl.each do |comp|
        res = comp == domain if comp.instance_of? String

        if !res
          res = comp == full_name if comp.instance_of? String
          res = comp =~ full_name if comp.instance_of? Regexp
        end

        if res
          ldebug "#{comp} is included", :yellow
          ret = true
          break
        end
      end

      if excl&.empty?
        return ret
      end

      T.must(excl).each do |comp|
        res = comp == domain if comp.instance_of? String

        if !res
          res = comp == full_name if comp.instance_of? String
          res = comp =~ full_name if comp.instance_of? Regexp
        end
        if res
          ldebug "#{comp} is excluded", :yellow
          ret = false
          break
        end
      end

      return ret
    end

    sig { params(data: AnalyzeData).void }
    def analyze_stages(data) # rubocop: disable all
      ldebug 'Analyze Stages start!', :red

      data.stage_manager = self
      @data = data

      incl = T.must(data.file_info).ast_include
      excl = T.must(data.file_info).ast_exclude

      if incl.nil?
        ldebug 'AST with default domain is procssed'
        incl = 'default'
      end

      if excl.nil?
        excl = ''
      end

      if incl.instance_of?(String)
        incl = [incl]
      end

      if excl.instance_of?(String)
        excl = [excl]
      end

      processed = T.let(false, T::Boolean)
      found = T.let(false, T::Boolean)
      ret = T.let(nil, T.untyped)
      @stages.each do |stage|
        if filter?(
            T.cast(incl, T::Array[T.any(String, Regexp)]),
            T.cast(excl, T::Array[T.any(String, Regexp)]),
            stage.ast.domain, stage.ast.full_name)
          processed = true
          ldebug "#{stage.name} start analyzing data!", :violet
          ret = stage.analyze(data)

          found = true if !ret.nil?
          break if ret
        else
          ldebug "#{stage.name} is filtered", :yellow
        end
      end

      if !processed
        lfatal 'At least one default domain ast shall be registered.'
        lfatal 'Please make sure that your registered AST Manager has default.<name> in its name.'
        lfatal 'Reason: Sheep_ast starts processing default.<name> initially.'
        application_error 'default domain AST Manager cannot be found.'
      end

      if !found
        lfatal 'All the AST stage not found expression. Lazy Abort!'
        expression_not_found "'#{data.expr.inspect}'"
      end

      if data.expr == '__sheep_eof__'
        eof_validation
      end

      ldebug 'Analyze Stages Finished!', :red
    end

    sig { void }
    def eof_validation
      @stages.each do |stage|
        len = stage.match_id_array.length
        if len != 0
          lfatal "Validation Fail!!! stage = #{stage.name}."
          lfatal 'To reach here means that in spite of end of file processing, some stages are'
          lfatal 'during AST process. This is thought to be invalid scenario.'
          lfatal 'Please check if this is really valid case.'
          lfatal 'You can off this by call disable_eof_validation in the AnalyzerCore'
          lfatal 'But the stiation maybe bug of sheep_ast or user code.'
          application_error
        end
      end
    end

    sig { void }
    def save_info
      save_data = {}
      @stages.each do |stage|
        save_stage =
          Stage.new(stage.ast)
        save_data[stage.name] = save_stage.save(stage)
        ldebug "#{stage.name} suspend process !!! info = #{stage.inspect}"
      end
      @save_stages << save_data
    end

    sig { returns(T::Boolean) }
    def restore_info
      save_data = @save_stages.last
      return false if save_data.nil?

      @stages.each do |stage|
        stage.copy(save_data[stage.name])
        ldebug "#{stage.name} resume process !!! info = #{stage.inspect}"
      end
      @save_stages.pop
      return true
    end

    sig { params(logs: Symbol).void }
    def dump_tree(logs) # rubocop: disable all
      if @data&.file_info&.line == nil
        line_no = nil
      else
        line_no = @data&.file_info&.line + 1
      end

      logf = method(logs)
      logf.call
      logf.call '## Analyze information start ##'
      logf.call 'Processing file'
      logf.call "- #{@data&.file_info&.file.inspect}"
      logf.call
      logf.call 'Tokenized Expression'
      logf.call "- expr = #{@data&.expr}"
      logf.call "- tokenized line = #{@data&.tokenized_line.inspect}"
      logf.call "- line no = #{line_no}"
      logf.call "- index = #{@data&.file_info&.index.inspect}"
      logf.call "- max_line = #{@data&.file_info&.max_line.inspect}"
      logf.call "- namespacee = #{@data&.file_info&.namespace_stack.inspect}"
      logf.call "- ast include = #{@data&.file_info&.ast_include.inspect}"
      logf.call "- ast exclude = #{@data&.file_info&.ast_exclude.inspect}"
      logf.call
      @stages.each do |stage|
        logf.call '|'
        logf.call '|'
        logf.call '|'
        logf.call '|/'
        logf.call '================================='
        logf.call "#{stage.name}> tree & Stack"
        logf.call '================================='
        logf.call '[AST]', :cyan
        stage.dump_tree(logs)
        logf.call '---------------------------------'
        logf.call '[Match Stack]', :yellow
        stage.dump_stack(logs)
        logf.call '================================='
      end
      logf.call '|'
      logf.call '|'
      logf.call '|'
      logf.call '|'
      logf.call '|  |\\ Next Expression'
      logf.call '|__|'
      logf.call ''
    end
  end
end
