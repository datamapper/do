module DataObjects
  # Abstract class for a single row
  class Row
    include Enumerable

    def each
      raise NotImplementedError
    end

  end
end