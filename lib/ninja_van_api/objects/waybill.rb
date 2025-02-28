# frozen_string_literal: true

module NinjaVanApi
  class Waybill < Base
    attr_reader :pdf

    def initialize(content)
      @pdf = content
    end
  end
end