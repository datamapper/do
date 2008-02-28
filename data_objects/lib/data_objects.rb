require File.dirname(__FILE__) + "/connection"
require File.dirname(__FILE__) + "/transaction"
require File.dirname(__FILE__) + "/command"
require File.dirname(__FILE__) + "/result"
require File.dirname(__FILE__) + "/reader"
require File.dirname(__FILE__) + "/field"
require File.dirname(__FILE__) + "/quoting"


module DataObjects
  class LengthMismatchError < StandardError; end
end

# class ConnectionFailed < StandardError; end
# 
# class ReaderClosed < StandardError; end
# 
# class ReaderError < StandardError; end
# 
# class QueryError < StandardError; end
# 
# class NoInsertError < StandardError; end
# 
# class LostConnectionError < StandardError; end
# 
# class UnknownError < StandardError; end