# rubocop:disable Style/Documentation
# frozen_string_literal: true

require 'delegate'
require 'puppet/coercion'

Puppet::Functions.create_function(:change_risk, Puppet::Functions::InternalFunction) do
  # @param risk The assessed risk to apply to the class.
  # @return a string indicating which operative decision the function made.
  # @example Calling the function.
  #   change_risk('medium')
  dispatch :class_function do
    scope_param
    param 'String', :risk
    return_type 'Enum[op,noop,interface]'
  end

  # @param risk The assessed risk to apply to a block of code.
  # @yield a block of code the assessed risk applies to.
  # @return a string indicating which operative decision the function made.
  # @example Calling the function.
  #   change_risk('medium') || { ... }
  dispatch :with_block do
    scope_param
    param 'String', :risk
    block_param
    return_type 'Enum[op,noop]'
  end

  # Return whether or not a given change risk level is currently permitted.
  # This is common logic used by #class_function and #with_block to decide
  # whether or not to force their resources into noop mode.
  def change_permitted?(risk)
    # Ensure config is loaded
    call_function('include', 'change_risk')

    risk_not_found_action = closure_scope.lookupvar('change_risk::risk_not_found_action')
    Puppet.debug { "change_risk(#{risk}): risk_not_found_action=#{risk_not_found_action}" }

    permitted = closure_scope.lookupvar('change_risk::permitted_risk_normalized')[risk]
    Puppet.debug { "change_risk(#{risk}): permitted=#{permitted}" }

    # If we have a valid directive, we can just return it
    return permitted unless permitted.nil?

    # No valid directive means we need to figure out a return value ourselves
    if risk_not_found_action == 'none'
      true
    elsif risk_not_found_action == 'noop'
      false
    elsif risk_not_found_action == 'fail'
      call_function('fail', "Permitted risk data unavailable for risk '#{risk}'")
    else
      raise "Unexpected value for change_risk::risk_not_found_action: #{risk_not_found_action}"
    end
  end

  def ignore_permitted?(risk)
    if [true, 'true'].include?(closure_scope.lookupvar('change_risk::ignore_permitted_risk'))
      Puppet.debug { "change_risk(#{risk}): ignore_permitted_risk=true" }
      return true
    end

    disable_mechanism = closure_scope.lookupvar('change_risk::disable_mechanism')
    flag_set = closure_scope.lookupvar('facts')['noop_cli_value'] == false
    fact_set = [true, 'true'].include?(closure_scope.lookupvar('facts')['ignore_permitted_risk'])

    case disable_mechanism
    when 'flag'
      flag_set
    when 'fact'
      fact_set
    when 'both'
      flag_set || fact_set
    end
  end

  def eval_noop(scope, risk)
    Puppet.debug { "change_risk(#{risk}): #{scope.inspect}: evaluating..." }
    if change_permitted?(risk) || ignore_permitted?(risk)
      'op'
    else
      Puppet.debug { "change_risk(#{risk}): #{scope.inspect}: calling noop()" }
      scope.call_function('noop', true)
      'noop'
    end
  end

  def class_function(scope, risk)
    newtags = scope.resource.tags.delete_if { |t| t =~ %r{change_risk:} }
    scope.resource.tags = newtags << "change_risk:#{risk}"

    # Check if we're implementing noop::class_interface()
    if scope.lookupvar('change_risk::respect_noop_class_interface') && !scope.get_local_variable('class_noop').nil?
      scope.call_function('noop::class_interface', [])
      'interface'
    else
      eval_noop(scope, risk)
    end
  end

  def with_block(scope, risk, &block)
    # Create a new scope to evalutate the block in. The new scope will be
    # used to contain the effects of a call to noop() inside that scope, if
    # needed, and also to cheat a little to add a tag to all resources
    # contained in the block, and any child-scope blocks that might get
    # included.
    #
    # To reset the change_risk tag from a parent scope and ensure the desired
    # change_risk tag is propogated, the new scope is spiked with a Delegator
    # resource which overrides the #tag and #merge_into methods of the source
    # resource, thus getting what we want and avoiding the need to insert a
    # whole new class to contain the resources.
    resource = ResourceDelegator.new(scope.resource, risk)
    newscope = scope.newscope(source: scope.source, resource: resource)

    # Ensure all variables from parent in newscope, then evaluate the block
    scope.to_hash(false, true).each_pair do |k,v|
      newscope[k] = v unless [Puppet::Parser::Scope::RESERVED_VARIABLE_NAMES,
                              Puppet::Parser::Scope::VARNAME_SERVER_FACTS].flatten.include?(k)
    end
    block.closure.call_by_name_with_scope(newscope, {}, false)

    eval_noop(newscope, risk)
  end

  class ResourceDelegator < SimpleDelegator
    def initialize(obj, risk)
      super(obj)
      @risk = risk
    end

    def tags
      super.delete_if { |t| t =~ %r{change_risk:} } << "change_risk:#{@risk}"
    end

    def merge_into(tag_set)
      tag_set.merge(tags)
    end
  end
end
