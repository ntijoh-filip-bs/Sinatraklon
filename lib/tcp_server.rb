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
        @router.add_route("GET", "/") do |params|
          "<h1>Home page :)</h1>"
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
        
        if route
          response = Response.new(200, "text/html", route[:action].call(request.params))

        elsif static_file_request?(request.resource)
          content_type, body = load_static_file(request.resource)
          response = Response.new(200, content_type, body)

        else
          response = Response.new(404, "text/html", "<h1>404 Not Found</h1><p>#{request.resource} does not exist</p>")
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
     
    def load_static_file(resource)
      path = File.join(@public_dir, resource)
    
      if File.exist?(path) && File.file?(path)
        content_type = MIME::Types.type_for(path).first.to_s
        content_type = "application/octet-stream" if content_type.empty?
        body = File.binread(path)
    
        [content_type, body]
      end
    end
end

server = HTTPServer.new(4567)
server.start