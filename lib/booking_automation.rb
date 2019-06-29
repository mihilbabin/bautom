require "httparty"
require "oj"
require "booking_automation/constants"
require "booking_automation/version"

module BookingAutomation
  class Error < StandardError; end

  class Client
    include HTTParty
    base_uri Constants::API_ENDPOINT

    attr_accessor :auth_token

    def initialize(auth_token)
      @auth_token = auth_token
    end

    def get_properties
      response = self.class.post('/getProperties', body: authentication.to_json)
      json = parse! response
      json['getProperties']
    rescue Oj::ParseError
      raise Error, Constants::PARSE_ERROR_MSG
    end

    def get_property(prop_key, options={})
      response = self.class.post(
        '/getProperty',
        body: payload(prop_key, Constants::DEFAULT_PROPERTY_OPTIONS.merge(options))
      )
      json = parse! response
      json['getProperty'].first
    rescue Oj::ParseError
      raise Error, Constants::PARSE_ERROR_MSG
    end

    def get_bookings(prop_key, options={})
      response = self.class.post(
        '/getBookings',
        body: payload(prop_key, Constants::DEFAULT_BOOKING_OPTIONS.merge(options))
      )
      parse! response
    rescue Oj::ParseError
      raise Error, Constants::PARSE_ERROR_MSG
    end

    private

    def authentication(prop_key=nil)
      {
        authentication: {
          apiKey: auth_token,
          propKey: prop_key
        }
      }
    end

    def payload(prop_key=nil, options={})
      authentication(prop_key)
        .merge(options)
        .to_json
    end

    def parse!(response)
      json = Oj.load response.body
      raise(
        Error,
        "API Error: #{json['errorCode']} #{json['error']}"
       ) if json.is_a?(Hash) && !json['error'].nil?
      json
    end
  end
end
