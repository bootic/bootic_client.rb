require 'uri_template'

module BooticClient
  class WhinyURI
    attr_reader :variables

    def initialize(href)
      @href = href
      @uri = URITemplate.new(href)
      @variables = @uri.variables
    end

    def expand(attrs = {})
      missing = missing_path_variables(attrs)
      if missing.any?
        raise InvalidURLError, missing_err(missing)
      end

      undeclared = undeclared_params(attrs)
      if undeclared.any?
        raise InvalidURLError, undeclared_err(undeclared)
      end

      uri.expand attrs
    end

    private
    attr_reader :uri, :href

    def path_variables
      @path_variables ||= (
        variables.find_all{ |v|
          Regexp.new("(\/\{#{v}\})|(\{\/#{v}\})") =~ href
        }
      )
    end

    def missing_path_variables(attrs)
      path_variables - attrs.keys.map(&:to_s)
    end

    def undeclared_params(attrs)
      attrs.keys.map(&:to_s) - variables
    end

    def undeclared_err(undeclared)
      msg = ["undeclared URI variables: #{format_vars(undeclared)}"]
      query_vars = variables - path_variables
      msg << "Allowed query variables are #{format_vars(query_vars)}" if query_vars.any?
      msg.join('. ')
    end

    def missing_err(missing)
      "missing required path variables: #{format_vars(missing)}"
    end

    def format_vars(vars)
      vars.map{|v| "`#{v}`"}.join(', ')
    end
  end
end

