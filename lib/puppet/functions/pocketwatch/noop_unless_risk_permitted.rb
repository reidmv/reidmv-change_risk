Puppet::Functions.create_function(:'pocketwatch::noop_unless_risk_permitted') do
  dispatch :noop_class_interface do
    param 'Enum[unknown,low,medium,high]', :risk
    return_type 'Boolean'
  end

  dispatch :with_block do
    param 'Enum[unknown,low,medium,high]', :risk
    block_param
  end

  def noop_class_interface(risk)
    should_noop?(risk)
  end

  def with_block(risk, &block)
    # TODO: validate block

    if !should_noop?(risk)
      block.call
    else
      # Create a new scope, call noop() inside that scope, and then evaluate
      # the code block in that scope.
      scope = block.closure.enclosing_scope
      newscope = scope.newscope(:source => scope, :resource => scope.resource)
      newscope.call_function('noop', true)
      block.closure.call_by_name_with_scope(newscope, {}, false)
    end
  end

  def should_noop?(risk)
    # If the user passed --no-noop on the command line, don't no-op.
    return false if (call_function('getvar', 'facts.noop_cli_value') == false)

    call_function('include', 'pocketwatch')
    permitted = call_function('getvar', "pocketwatch::data.permitted.#{risk}") do |err|
      call_function('fail', 'Pocketwatch data unavailable')
    end

    # Return the inverse of permitted. If permitted == true, then noop == false
    # (and vise versa)
    !permitted
  end
end
