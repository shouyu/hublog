require 'pp'

class ArticlesController < ApplicationController
  protect_from_forgery :expect => [:hook]

  # GET /articles
  # GET /articles.json
  def index
    @articles = Article.order('created_time desc').to_a
  end

  # GET /articles/1
  # GET /articles/1.json
  def show
    @article = Rails.cache.fetch("article#{params[:id]}") do
      Article.where(id: params[:id]).first
    end
    if @article.content.blank?
      contents = Octokit.contents(Hublog::Application.config.repo, path: @article.name)
      content = contents.encoding == "base64" ? Base64.decode64(contents.content).force_encoding('utf-8') : contents.content
      content = Octokit.markdown(content)
      @article.content = content.force_encoding('utf-8')
      @article.save!
      Rails.cache.write("article#{params[:id]}", @article)
    end
  end

  def hook
    Article.fetch_commits
    render nothing: true
  end
end
