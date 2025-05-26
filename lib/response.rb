class Response
  attr_accessor :status_code, :content_type, :body

  def initialize(status_code, content_type, body)
    @status_code = status_code
    @content_type = content_type
    @body = body
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