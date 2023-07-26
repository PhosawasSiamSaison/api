class Api::ClientPost < Api::ClientBase
  def call(url:, header:, param:)
    @conn.post do |req|
      req.url url
      req.headers['Content-Type'] = header.delete(:content_type)
      req.body = param
    end
  end
end
