require 'spec_helper'

RSpec.describe('Expression::Base#clone') do
  specify('Base#clone') do
    root = RP.parse(/^(?i:a)b+$/i)
    copy = root.clone

    expect(copy.to_s).to eq root.to_s

    expect(root).not_to equal copy
    expect(root.text).to eq copy.text
    expect(root.text).not_to equal copy.text

    root_1 = root[1]
    copy_1 = copy[1]

    expect(root_1.options).to eq copy_1.options
    expect(root_1.options).not_to equal copy_1.options

    expect(root_1.parent).to eq root
    expect(root_1.parent).not_to equal copy
    expect(copy_1.parent).to eq copy
    expect(copy_1.parent).not_to equal root

    root_2 = root[2]
    copy_2 = copy[2]

    expect(root_2).to be_quantified
    expect(copy_2).to be_quantified
    expect(root_2.quantifier.text).to eq copy_2.quantifier.text
    expect(root_2.quantifier.text).not_to equal copy_2.quantifier.text
    expect(root_2.quantifier).not_to equal copy_2.quantifier

    # regression test
    expect { root_2.clone }.not_to(change { root_2.quantifier.object_id })
    expect { root_2.clone }.not_to(change { root_2.quantifier.text.object_id })
  end

  specify('Subexpression#clone') do
    root = RP.parse(/^a(b([cde])f)g$/)
    copy = root.clone

    expect(copy.to_s).to eq root.to_s

    expect(root).to respond_to(:expressions)
    expect(copy).to respond_to(:expressions)
    expect(root.expressions).not_to equal copy.expressions
    copy.expressions.each_with_index do |exp, index|
      expect(root[index]).not_to equal exp
    end
    copy[2].each_with_index do |exp, index|
      expect(root[2][index]).not_to equal exp
    end

    # regression test
    expect { root.clone }.not_to(change { root.expressions.object_id })
  end

  specify('Group::Named#clone') do
    root = RP.parse('^(?<somename>a)+bc$')
    copy = root.clone

    expect(copy.to_s).to eq root.to_s

    root_1 = root[1]
    copy_1 = copy[1]

    expect(root_1.name).to eq copy_1.name
    expect(root_1.name).not_to equal copy_1.name
    expect(root_1.text).to eq copy_1.text
    expect(root_1.expressions).not_to equal copy_1.expressions
    copy_1.expressions.each_with_index do |exp, index|
      expect(root_1[index]).not_to equal exp
    end

    # regression test
    expect { root_1.clone }.not_to(change { root_1.name.object_id })
  end

  specify('Group::Options#clone') do
    root = RP.parse('foo(?i)bar')
    copy = root.clone

    expect(copy.to_s).to eq root.to_s

    root_1 = root[1]
    copy_1 = copy[1]

    expect(root_1.option_changes).to eq copy_1.option_changes
    expect(root_1.option_changes).not_to equal copy_1.option_changes

    # regression test
    expect { root_1.clone }.not_to(change { root_1.option_changes.object_id })
  end

  specify('Backreference::Base#clone') do
    root = RP.parse('(foo)\1')
    copy = root.clone

    expect(copy.to_s).to eq root.to_s

    root_1 = root[1]
    copy_1 = copy[1]

    expect(root_1.referenced_expression).to eq copy_1.referenced_expression
    expect(root_1.referenced_expression.to_s).to eq copy_1.referenced_expression.to_s
    expect(root_1.referenced_expression).not_to equal copy_1.referenced_expression

    # regression test
    expect { root_1.clone }.not_to(change { root_1.referenced_expression.object_id })
  end

  specify('Backreference::Base#clone works for recursive subexp calls') do
    root = RP.parse('a|b\g<0>')
    copy = root.clone

    expect(copy.to_s).to eq root.to_s

    root_call = root.dig(0, 1, 1)
    copy_call = copy.dig(0, 1, 1)

    expect(root).to eq copy
    expect(root).not_to equal copy

    expect(root_call).to eq copy_call
    expect(root_call).not_to equal copy_call

    expect(root_call.referenced_expression).not_to be_nil
    expect(root_call.referenced_expression.object_id).to eq root.object_id

    expect(copy_call.referenced_expression).not_to be_nil

    # Mapping the reference to the cloned referenced_expression would
    # probably require a context or 2-way bindings in the tree. Maybe later ...
    # expect(copy_call.referenced_expression.object_id).to eq copy.object_id
  end

  specify('Sequence#clone') do
    root = RP.parse(/(a|b)/)
    copy = root.clone

    # regression test
    expect(copy.to_s).to eq root.to_s

    root_seq_op = root[0][0]
    copy_seq_op = copy[0][0]
    root_seq_1 = root[0][0][0]
    copy_seq_1 = copy[0][0][0]

    expect(root_seq_op).not_to equal copy_seq_op
    expect(root_seq_1).not_to equal copy_seq_1
    copy_seq_1.expressions.each_with_index do |exp, index|
      expect(root_seq_1[index]).not_to equal exp
    end
  end

  describe('Base#unquantified_clone') do
    it 'produces a clone' do
      root = RP.parse(/^a(b([cde])f)g$/)
      copy = root.unquantified_clone

      expect(copy.to_s).to eq root.to_s

      expect(copy).not_to equal root
    end

    it 'does not carry over the callee quantifier' do
      expect(RP.parse(/a{3}/)[0]).to be_quantified
      expect(RP.parse(/a{3}/)[0].unquantified_clone).not_to be_quantified

      expect(RP.parse(/[a]{3}/)[0]).to be_quantified
      expect(RP.parse(/[a]{3}/)[0].unquantified_clone).not_to be_quantified

      expect(RP.parse(/(a|b){3}/)[0]).to be_quantified
      expect(RP.parse(/(a|b){3}/)[0].unquantified_clone).not_to be_quantified
    end

    it 'keeps quantifiers of callee children' do
      expect(RP.parse(/(a{3}){3}/)[0][0]).to be_quantified
      expect(RP.parse(/(a{3}){3}/)[0].unquantified_clone[0]).to be_quantified
    end
  end
end
