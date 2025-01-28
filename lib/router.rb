require_relative 'request'
require_relative 'response'

class Router
  def initialize
    @routes = []
  end

  def add_route(method, path_pattern, &action)
    #Omvandla :param till regex så man inte behöver skriva regexs när man lägger till en route
    regex_pattern = convert_path_to_regex(path_pattern)
    @routes << { method: method.upcase, path_pattern: regex_pattern, action: action }
  end

  def match_route(request)
    route = @routes.find do |r|
      r[:method] == request.method && r[:path_pattern].match(request.resource)
    end

    if route
      route_params = extract_params(route[:path_pattern], request.resource)
      request.params.merge!(route_params)
      route[:action].call(request)
    else
      #Returnera ett 404-svar om ingen route matchar
      Response.new.tap do |response|
        response.status_code = 404
        response.body = "<h1>404 Not Found</h1>"
      end
    end
  end

  private

  def convert_path_to_regex(path_pattern)
    Regexp.new("^" + path_pattern.gsub(/:([\w]+)/, '(?<\1>[^/]+)') + "$")
  end

  #Extraherar parametrar ur en dynamisk route
  def extract_params(path_pattern, resource)
    match = path_pattern.match(resource)
    params = {}

    if match
      match.named_captures.each do |key, value|
        params[key] = value
      end
    end

    params
  end
end