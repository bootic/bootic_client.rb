# frozen_string_literal: true

require 'uri_template'

module BooticClient
  class WhinyURI
    attr_reader :variables

    def initialize(href, complain_on_undeclared_params = true)
      @href = href
      @uri = URITemplate.new(href)
      @variables = @uri.variables
      @complain_on_undeclared_params = complain_on_undeclared_params
    end

    def expand(attrs = {})
      attrs = stringify(attrs)

      missing = missing_path_variables(attrs)
      if missing.any?
        raise InvalidURLError, missing_err(missing)
      end

      undeclared = undeclared_params(attrs)
      if complain_on_undeclared_params
        if undeclared.any?
          raise InvalidURLError, undeclared_err(undeclared)
        end
      end

      uri.expand whitelisted(attrs)
    end

    private
    attr_reader :uri, :href, :complain_on_undeclared_params

    def path_variables
      @path_variables ||= (
        variables.find_all{ |v|
          !!(href["{#{v}}"]) || !!(href["{/#{v}}"])
        }
      )
    end

    def whitelisted(attrs = {})
      variables.each_with_object({}) do |key, hash|
        hash[key] = attrs[key] if attrs.key?(key)
      end
    end

    def missing_path_variables(attrs)
      path_variables - attrs.keys
    end

    def declared_params
      @declared_params ||= variables - path_variables
    end

    def undeclared_params(attrs)
      attrs.keys - variables
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

    def stringify(attrs)
      attrs.each_with_object({}) do |(k, v), hash|
        hash[k.to_s] = v
      end
    end
  end
end

