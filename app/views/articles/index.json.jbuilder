json.array!(@articles) do |article|
  json.extract! article, :name, :content, :created_time, :updated_time
  json.url article_url(article, format: :json)
end
