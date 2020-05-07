require 'delegate'

Puppet::Functions.create_function(:'change_risk', Puppet::Functions::InternalFunction) do
  dispatch :class_function do
    scope_param
    param 'String', :risk
    return_type 'Enum[op,noop]'
  end

  dispatch :with_block do
    scope_param
    param 'String', :risk
    block_param
    return_type 'Enum[op,noop]'
  end

  def class_function(scope, risk)
    newtags = scope.resource.tags.delete_if { |t| t =~ /change_risk:/ }
    scope.resource.tags = newtags << "change_risk:#{risk}"

    if change_permitted?(risk)
      'op'
    else
      scope.call_function('noop', true)
      'noop'
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
    newscope = scope.newscope(:source => scope.source, :resource => resource)
    block.closure.call_by_name_with_scope(newscope, {}, false)

    if change_permitted?(risk)
      'op'
    else
      newscope.call_function('noop', true)
      'noop'
    end
  end

  def change_permitted?(risk)
    # Ensure config is loaded
    call_function('include', 'change_risk')

    # If the user passed --no-noop on the command line, don't no-op.
    return true if (call_function('getvar', 'facts.noop_cli_value') == false)

    permitted = call_function('getvar', "change_risk::risk_permitted.#{risk}") do |err|
      call_function('fail', "Risk permitted data unavailable for risk '#{risk}'")
    end

    permitted
  end

  class ResourceDelegator < SimpleDelegator
    def initialize(obj, risk)
      super(obj)
      @risk = risk
    end

    def tags
      super.delete_if { |t| t =~ /change_risk:/ } << "change_risk:#{@risk}"
    end

    def merge_into(tag_set)
      tag_set.merge(tags)
    end
  end
end
