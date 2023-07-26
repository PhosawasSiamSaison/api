class Api::ClientGet < Api::ClientBase
  def call(url:, header:, param:)
    @conn.get do |req|
      req.url url
    end
  end
end
