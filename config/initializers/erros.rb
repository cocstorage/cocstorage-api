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
  class WardenUnauthorized < StandardError
    attr_reader :code, :message

    def initialize(error)
      super
      @code = error[:code]
      @message = error[:message]
    end
  end
  class Forbidden < StandardError
    attr_reader :code, :message

    def initialize(error)
      super
      @code = error[:code]
      @message = error[:message]
    end
  end
  class NotFound < StandardError
    attr_reader :code, :message

    def initialize(error)
      super
      @code = error[:code]
      @message = error[:message]
    end
  end
end