require_relative 'request'
require_relative 'response'

class Router
  def initialize
    @routes = []
  end

  def add_route(method, path, &action)
    @routes << { method: method.upcase, path: path, action: action }
  end

  def match_route(request)
    route = @routes.find do |r|
      r[:method] == request.method && path_match?(r[:path], request.resource)
    end

    if route
      route_params = extract_params(route[:path], request.resource)
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

  def path_match?(route_path, request_path)
    route_segments = route_path.split("/")
    request_segments = request_path.split("/")
    return false unless route_segments.size == request_segments.size

    route_segments.zip(request_segments).all? do |route_segment, request_segment|
      route_segment.start_with?(":") || route_segment == request_segment
    end
  end

  #Extreherar parametrar ur en dynamisk route
  def extract_params(route_path, request_path)
    route_segments = route_path.split("/")
    request_segments = request_path.split("/")
    params = {}

    route_segments.each_with_index do |segment, index|
      if segment.start_with?(":")
        params[segment[1..]] = request_segments[index]
      end
    end

    params
  end
end