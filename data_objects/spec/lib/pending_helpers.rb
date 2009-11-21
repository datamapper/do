module DataObjects::Spec
  module PendingHelpers
    def pending_if(message, boolean)
      if boolean
        should.flunk(message) { yield }
      else
        yield
      end
    end
  end
end
