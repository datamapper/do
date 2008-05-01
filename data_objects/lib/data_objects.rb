require File.expand_path(File.join(File.dirname(__FILE__), 'logger'))
require File.expand_path(File.join(File.dirname(__FILE__), 'connection'))
require File.expand_path(File.join(File.dirname(__FILE__), 'transaction'))
require File.expand_path(File.join(File.dirname(__FILE__), 'command'))
require File.expand_path(File.join(File.dirname(__FILE__), 'result'))
require File.expand_path(File.join(File.dirname(__FILE__), 'reader'))
require File.expand_path(File.join(File.dirname(__FILE__), 'field'))
require File.expand_path(File.join(File.dirname(__FILE__), 'quoting'))


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
