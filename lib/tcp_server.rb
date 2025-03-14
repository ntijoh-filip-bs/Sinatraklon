require 'socket'
require 'mime-types'
require_relative 'request'
require_relative 'response'
require_relative 'router'

class HTTPServer
    def initialize(port)
      @port = port
      @public_dir = "public"
    end
  
    def start
        server = TCPServer.new(@port)
        puts "Listening on #{@port}"
        @router = Router.new
        @router.add_route("GET", "/") do |_request|
          Response.new.tap do |response|
            response.status_code = 200
            response.content_type = "text/html"
            response.body = "<h1>Welcome to the Home Page!</h1>"
          end
        end
    
        @router.add_route("GET", "/hello/:name") do |request|
          Response.new.tap do |response|
            response.status_code = 200
            response.content_type = "text/html"
            response.body = "<h1>Hello, #{request.params['name']}!</h1>"
          end
        end
  
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
  
        route = @router.match_route(request)
        
        if static_file_request?(request.resource)
          response = serve_static_file(request.resource)
        else
          response = @router.match_route(request)
        end
  
        session.print response.to_s
        session.close
      end
    end

    private

    def static_file_request?(resource)
      path = File.join(@public_dir, resource)
      File.file?(path) && File.exist?(path)
    end
    
    def serve_static_file(resource)
      path = File.join(@public_dir, resource)
    
      if File.exist?(path) && File.file?(path)
        content_type = MIME::Types.type_for(path).first.to_s
        content_type = "application/octet-stream" if content_type.empty?
    
        Response.new.tap do |response|
          response.status_code = 200
          response.content_type = content_type
          response.body = File.binread(path)
        end
      else
        Response.new.tap do |response|
          response.status_code = 404
          response.content_type = "text/html"
          response.body = "<h1>404 Not Found</h1><p>File not found: #{resource}</p>"
        end
      end
    end
end

server = HTTPServer.new(4567)
server.start