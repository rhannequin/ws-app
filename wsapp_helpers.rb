module WSApp
  module Helpers

    # Handle application errors.
    def app_error_message(error_type = nil)
      case error_type
        when :user_parameters_error
          status 401 # Unauthorized
        when :user_authentication_error
          status 401 # Unauthorized
        when :not_found_error
          status 404 # Not Found
        when :internal_server_error
          status 500 # Internal Server Error
        else # :unknown_error
          status 400 # Bad Request
      end
      { msg_id: error_type.to_s.upcase }.to_json.freeze
    end

    def log(arg, method = 'info')
      logger.send(method, arg)
    end

    def json_response(code, response)
      cross_origin
      content_type :json
      status code
      response[:code] = code
      if prettify?
        return JSON.pretty_generate response
      else
        return response.to_json
      end
    end

    def accept_params(params, *fields)
      h = {}
      fields.each do |name|
        h[name] = params[name] if params[name]
      end
      h
    end

    def prettify?
      not(!params[:pretty].nil? && params[:pretty] == 'false')
    end

    def h(text)
      Rack::Utils.escape_html(text)
    end

    def reformat_soap_results(soap_results)
      if soap_results[:item].kind_of? Array
        soap_results[:item].map! do |arr1|
          arr1[:item].map do |arr2|
            { arr2[:key] => arr2[:value] }
          end.reduce Hash.new, :merge
        end
      else
        return [] if soap_results[:item].nil?
        soap_results[:item][:item].map! do |arr|
          { arr[:key] => arr[:value] }
        end.reduce Hash.new, :merge
      end
    end

    def to_xml(obj)
      XmlSimple.xml_out(obj,
                        'AttrPrefix' => true,
                        'KeyAttr' => ['name', 'key', 'id'],
                        'XmlDeclaration' => true)
    end

    def from_xml(str, conversions = {})
      XmlSimple.xml_in str, conversions: conversions, forcearray: false
    end

    def random_id
      (0...8).map { (65 + rand(26)).chr }.join
    end

  end
end