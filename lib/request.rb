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

  def reject_map__and_hash(params)
    params.reject(&:empty?)
        .map { |param| param.split("=", 2) }
        .to_h
  end

  def parse_params(lines)
    case @method
    when "GET"
      query_string = @resource.split("?")[1] || ""
      query_string.split("&")
      .then { |params| reject_map__and_hash(params)}
        
    when "POST"
      body = lines.drop_while { |line| !line.empty? }[1]
      return {} unless body
      body.split("&")
        .then { |params| reject_map__and_hash(params)}

    else
      {}
    end
  end
end