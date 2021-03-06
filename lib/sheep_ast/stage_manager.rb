# typed: ignore
# frozen_string_literal: true

require_relative 'exception'
require_relative 'messages'
require_relative 'datastore/datastore'
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
        ldebug? and ldebug "match_id_array = #{@match_id_array.inspect}"
        ldebug? and ldebug "match_symbol = #{@match_symbol_array.inspect}"
      end
    end

    sig { params(data: AnalyzeData).returns(MatchResult) }
    def analyze(data) # rubocop: disable all
      node = @ast.node_factory.from_id(T.must(info).node_id)
      ldebug? and ldebug "analyze start, node_id = #{T.must(info).node_id}, object_id =  #{node.object_id}, data = #{data.inspect}"
      ret_node_info = @ast.find_next_node(data, node)
      ldebug? and ldebug "#{name} matched! => info = #{ret_node_info.inspect} for data = #{data.inspect}"

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

        ldebug? and ldebug "Invoking action my node id = #{node.my_id}"
        after_action = @ast.at_end(data, node)
      else
        application_error "Unknown status #{ret_node_info.status}"
      end

      return handle_after_action(after_action, data, ret_node_info)
    end

    sig { params(info: NodeInfo).void }
    def force_move_node(info)
      ldebug? and ldebug "force move node to #{info.inspect}", :blue
      init
      T.must(@info).copy(info)
    end

    sig { params(info: NodeInfo).void }
    def move_node(info)
      T.must(@info).copy(info)
    end

    def move_committed_node
      node_info = NodeInfo.new
      node_info.node_id = @committed_node_id
      force_move_node(node_info)
    end

    def commit_node
      @committed_node_id = T.must(@info).node_id
    end


    sig { params(after_action: MatchAction, data: AnalyzeData, info: NodeInfo).returns(MatchResult) }
    def handle_after_action(after_action, data, info) # rubocop: disable all
      ldebug? and ldebug "#{name} decided to #{after_action.inspect} for the '#{data.expr.inspect}'"
      case after_action
      when MatchAction::Abort
        expression_not_found "'#{data.expr.inspect}'"
      when MatchAction::LazyAbort
        return MatchResult::NotFound
      when MatchAction::StayNode
        return MatchResult::GetNext
      when MatchAction::Next
        move_node(info)
        return MatchResult::GetNext
      when MatchAction::Continue
        init
        return MatchResult::Continue
      when MatchAction::Finish
        move_node(info)
        save_req = nil
        if !data.save_request.nil?
          save_req = data.save_request
          data.save_request = nil
        end
        init
        handle_save_request(data, save_req) unless save_req.nil?

        return MatchResult::Finish
      else
        application_error "Match action #{after_action} is not defined"
      end
    end

    sig { params(data: AnalyzeData, save_req: SaveRequest).void }
    def handle_save_request(data, save_req)
      ldebug? and ldebug "handle_save_request save_req = #{save_req.inspect}"

      data.file_manager.enter_cb_invoke(save_req.enter_cb) unless save_req.enter_cb.nil?
      data.file_manager.register_next_chunk(save_req.chunk) unless save_req.chunk.nil?
      data.file_manager.register_next_file(save_req.file) unless save_req.file.nil?
      data.file_manager.ast_include_set(save_req.ast_include)
      data.file_manager.ast_exclude_set(save_req.ast_exclude)
      data.file_manager.put_namespace(save_req.namespace) unless save_req.namespace.nil?
      data.file_manager.put_meta1(save_req.meta1) unless save_req.meta1.nil?
      data.file_manager.put_meta2(save_req.meta2) unless save_req.meta2.nil?
      data.file_manager.put_meta3(save_req.meta3) unless save_req.meta3.nil?
      data.file_manager.exit_cb_set(save_req.exit_cb) unless save_req.exit_cb.nil?
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
      ldebug? and ldebug "#{name.inspect} init the node_info now. the info was #{@info.inspect}, match_id_array =>"\
        " #{@match_id_array.inspect}, match_stack => #{@match_symbol_array.inspect}", :cyan
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

    attr_accessor :condition_incl
    attr_accessor :condition_excl

    sig { params(data_store: DataStore).void }
    def initialize(data_store)
      @stages = []
      @stages_name = {}
      @save_stages = [{}]
      @data_store = data_store
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
      ast.stage_manager = self
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
        full_name: String,
        kind: String,
      ).returns(T::Boolean)
    }
    def filter?(incl, excl, domain, full_name, kind = 'redir') # rubocop: disable all
      return true if domain == 'always'

      ret = T.let(false, T::Boolean)

      # For kind = 'cond', default is all include
      ret = true if kind == 'cond'

      incl.each do |comp|
        res = comp == domain if comp.instance_of? String

        if !res
          res = comp == full_name if comp.instance_of? String
          res = comp =~ full_name if comp.instance_of? Regexp
        end

        if res
          ldebug? and ldebug "#{kind}> #{comp} is included", :yellow
          ret = true
          break
        else
          ret = false
        end
      end

      T.must(excl).each do |comp|
        res = comp == domain if comp.instance_of? String

        if !res
          res = comp == full_name if comp.instance_of? String
          res = comp =~ full_name if comp.instance_of? Regexp
        end
        if res
          ldebug? and ldebug "#{kind}> #{comp} is excluded", :yellow
          ret = false
          break
        end
      end

      return ret
    end

    def incl_init(incl, kind = 'redir')
      ret = incl.dup
      if ret.nil?
        if kind == 'redir'
          ldebug? and ldebug 'AST with default domain is procssed'
          ret = ['default']
        else
          ret = []
        end
      end

      if ret.instance_of?(String)
        ret = [ret]
      end

      return ret
    end

    def excl_init(excl, kind = 'redir')
      ret = excl.dup
      if ret.nil?
        ret = []
      end

      if ret.instance_of?(String)
        ret = [ret]
      end

      return ret
    end

    sig { params(data: AnalyzeData).returns(MatchResult) }
    def analyze_stages(data) # rubocop: disable all
      ldebug? and ldebug 'Analyze Stages start!', :red

      data.stage_manager = self
      @data = data

      incl = incl_init(T.must(data.file_info).ast_include)
      excl = excl_init(T.must(data.file_info).ast_exclude)

      cond_incl = incl_init(condition_incl, 'cond')
      cond_excl = excl_init(condition_excl, 'cond')

      processed = T.let(false, T::Boolean)
      ret = T.let(MatchResult::Default, MatchResult)

      @stages.each do |stage|
        judge = filter?(incl, excl, stage.ast.domain, stage.ast.full_name)
        cond_judge = filter?(cond_incl, cond_excl, stage.ast.domain, stage.ast.full_name, 'cond')

        if judge && cond_judge
          processed = true
          ldebug? and ldebug "#{stage.name} start analyzing data!", :violet
          ret = stage.analyze(data)

          break if ret == MatchResult::GetNext || ret == MatchResult::Finish
        else
          ldebug? and ldebug "#{stage.name} is filtered. judge = #{judge},"\
            " cond_judge = #{cond_judge}", :yellow
        end
      end

      if !processed
        lfatal 'At least one default domain ast shall be registered.'
        lfatal 'Please make sure that your registered AST Manager has default.<name> in its name.'
        lfatal 'Reason: Sheep_ast starts processing default.<name> initially.'
        application_error 'default domain AST Manager cannot be found.'
      end

      application_error 'Should not enter this route. Bug.' if ret == MatchResult::Default

      if ret == MatchResult::NotFound
        if @data_store.value(:_sheep_not_raise_when_lazy_abort)
          ldebug? and ldebug 'All the AST stage not found expression. But return false'
        else
          lfatal 'All the AST stage not found expression. Lazy Abort!'
          expression_not_found "'#{data.expr.inspect}'"
        end
      end

      if data.expr == '__sheep_eof__' || data.expr == '__sheep_eoc__'
        eof_validation
      end

      if data.expr == '__sheep_eof__' && data&.file_info&.file
        data.file_manager.print_eof(data.file_info.file)
      end

      ldebug? and ldebug "Analyze Stages Finished with #{ret.inspect} !", :red

      return ret
    end

    sig { void }
    def eof_validation
      @stages.each do |stage|
        len = stage.match_id_array.length
        if len != 0
          str = "\n\n"\
                "=========================================\n"\
                "Validation Fail!!! stage = #{stage.name}\n"\
                "=========================================\n"\
                'To reach here means that in spite of end of file (or end of redirected chunk),'\
                ' some stages are'\
                ' during AST process. This is thought to be invalid scenario.'\
                " Please check your registered stage = #{stage.name}, has some bugs."\
                " You can find something in the [Match Stack] for the #{stage.name} below.\n\n"
          application_error "eof validation error. Explanation is below. #{str}"
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
        ldebug? and ldebug "#{stage.name} suspend process !!! info = #{stage.inspect}"
      end
      @save_stages << save_data
    end

    sig { returns(T::Boolean) }
    def restore_info
      save_data = @save_stages.last
      return false if save_data.nil?

      @stages.each do |stage|
        stage.copy(save_data[stage.name])
        ldebug? and ldebug "#{stage.name} resume process !!! info = #{stage.inspect}"
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
      logf.call '## Analyze information ##'
      logf.call 'Processing Data'
      logf.call "- expr = #{@data&.expr}"
      logf.call "- tokenized line_prev = #{@data&.tokenized_line_prev.inspect}"
      logf.call "- tokenized line = #{@data&.tokenized_line.inspect}"
      logf.call "- line no = #{line_no}"
      logf.call "- index = #{@data&.file_info&.index.inspect}"
      logf.call "- max_line = #{@data&.file_info&.max_line.inspect}"
      logf.call "- namespacee = #{@data&.file_info&.namespace_stack.inspect}"
      logf.call "- ast include = #{@data&.file_info&.ast_include.inspect}"
      logf.call "- ast exclude = #{@data&.file_info&.ast_exclude.inspect}"
      logf.call "- condition ast include = #{condition_incl.inspect}"
      logf.call "- condition ast exclude = #{condition_excl.inspect}"
      logf.call "- file = #{@data&.file_info&.file.inspect}"
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
