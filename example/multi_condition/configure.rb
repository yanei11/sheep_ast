# typed: ignore
# frozen_string_literal: true

# In this example, multiple condition matching and extraction by arbeitaly line index is shown.
#
# The usecase scenario is that, user wants to extract ens4 interface information when its address
# is 10.146.0.3 from well formatted file `example/multi_condition/test.txt`.
# Please not that test.txt file is created just for this example and not real world file.
#
# Also we assuemed user wants to analyze full information for the matched interface (ens4 && 10.146.0.3)
#
# So, in this case, multiple condition match is needed.

#rubocop: disable all
def configure(core)

  # `tok.use_split_rule` tells tokenizer to split specified character.
  # This is more simple than to use default tokenizer.
  core.config_tok do |tok|
      tok.use_split_rule { tok.split_space_only }
  end

  core.config_ast('always.ignore') do |_ast, syn|
    syn.within {
      register_syntax(A(:na)) {
        SS(
          S() << E(:e, ' ')
        )
      }
    }
  end

  # In this block, multiple condition is used.
  # Please see index_cond part, this line matches ExactMatch for `ens4:` expression.
  # Adding index_cond option, sheep_ast evaluate index condition after ExactMatch is done, which matches `ens4:`.
  #
  # Here line_offset is the line to use. The current line number + line_offset is the line
  # to be analyzed.
  # offset option is the string location. When line_offset >= 1, it is simply shows number
  # of location starts from 0. When line_offset = 0, offset is count from current index.
  #
  # So, it means, when ens4: is matched, and when the test string is at line number + 1, location = 2
  # is the 10.146.0.3, following action A(;let ... ) is called.
  core.config_ast('default.analyze') do |_ast, syn|
    syn.within {
      register_syntax {
        SS(
          S() << E(:e, 'ens4:', index_cond: idx('10.146.0.3', line_offset: 1, offset: 2))\
              << A(:let,
                   [:redirect,
                    redirect_line_from_to: 0..5,
                    dry_run: true,
                    ast_include: 'redirect'
                   ]
                  )
          # This example also shows redirect_line_from_to option like the above.
          # This redirect strings from line 0 to line + 5 which contains full interface information.
          # Please see the output of this example.
        )
      }
    }
  end


  core.config_ast('always.continue') do |_ast, syn|
    syn.within {
      register_syntax(A(:na)) {
        SS(
          S() << E(:any),
        )
      }
    }
  end
end
