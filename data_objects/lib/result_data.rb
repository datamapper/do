module DataObjects
  class ResultData
  
    def initialize(conn, affected_rows, last_insert_row = nil)
      @conn, @affected_rows, @last_insert_row = conn, affected_rows, last_insert_row
    end

    attr_reader :affected_rows, :last_insert_row
    alias_method :to_i, :affected_rows
  
  end
end