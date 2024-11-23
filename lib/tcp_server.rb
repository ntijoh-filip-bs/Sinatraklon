require 'socket'

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


class HTTPServer
    def initialize(port)
      @port = port
    end
  
    def start
        server = TCPServer.new(@port)
        puts "Listening on #{@port}"
        @router = Router.new
        #@router.add_route
  
      while session = server.accept
        data = ""
        while line = session.gets and line !~ /^\s*$/
          data += line
        end

        #Hantera body om Content-Length är specificerat
        if data.match(/Content-Length: (\d+)/)
          content_length = $1.to_i
          body = session.read(content_length)
          data += "\n#{body}"
        end

        request = Request.new(data)

        puts "RECEIVED REQUEST"
        puts "-" * 40
        puts data
        puts "-" * 40 
  
        response = @router.match_route(request)
  
        session.print response.to_s
        session.close
      end
    end
end


class Request
  attr_reader :method, :resource, :version, :headers, :params

  def initialize(request_string)
    lines = request_string.split("\n")

    request_line = lines.first.split(" ")
    @method = request_line[0]
    @resource = request_line[1]
    @version = request_line[2]

    @headers = lines[1..-1]
        .take_while { |line| !line.empty? }
        .map { |header| header.split(": ", 2) }
        .to_h

    @params = parse_params(lines)
  end

  private

  def parse_params(lines)
    case @method
    when 'GET'
      query_string = @resource.split("?")[1] || ""
      query_string.split("&")
        .reject(&:empty?)
        .map { |param| param.split("=", 2) }
        .to_h
    when 'POST'
      body = lines.drop_while { |line| !line.empty? }[1]
      return {} unless body
      body.split("&")
        .reject(&:empty?)
        .map { |param| param.split("=", 2) }
        .to_h
    else
      {}
    end
  end
end


class Response
  attr_accessor :status_code, :content_type, :body

  def initialize
    @status_code = 200
    @content_type = "text/html"
    @body = ""
  end

  def to_s
    headers = [
      "HTTP/1.1 #{@status_code} #{status_message}",
      "Content-Type: #{@content_type}",
      "Content-Length: #{@body.bytesize}",
      "\r\n"
    ].join("\r\n")

    headers + @body
  end

  private

  def status_message
    case @status_code
    when 200 then "OK"
    when 404 then "Not Found"
    when 500 then "Internal Server Error"
    else "Unknown Status"
    end
  end
end

server = HTTPServer.new(4567)
server.start
