class Errors
  class BadRequest < StandardError
    attr_reader :code, :message

    def initialize(error)
      super
      @code = error[:code]
      @message = error[:message]
    end
  end
  class Unauthorized < StandardError; end
  class Forbidden < StandardError; end
  class NotFound < StandardError
    attr_reader :code, :message

    def initialize(error)
      super
      @code = error[:code]
      @message = error[:message]
    end
  end
end