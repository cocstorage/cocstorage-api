class Errors
  class Unauthorized < StandardError; end
  class Forbidden < StandardError; end
  class BadRequest < StandardError
    attr_reader :code, :message

    def initialize(error)
      super
      @code = error[:code]
      @message = error[:message]
    end
  end
end