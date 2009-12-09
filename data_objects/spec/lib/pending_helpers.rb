module DataObjects::Spec
  module Pending

    def pending(message = '')
      raise Bacon::Error.new(:pending, message)
    end

    def pending_if(message, boolean)
      if boolean
        pending(message) { yield }
      else
        yield
      end
    end
  end
end

module Bacon
  class Context
    include DataObjects::Spec::Pending
  end
end
