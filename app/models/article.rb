class Article < ActiveRecord::Base
  validates_uniqueness_of :name

  def title
    File.basename(self.name, ".*")
  end

  def self.fetch_commits
    last_article = self.order('commit_time desc').first rescue return
    if last_article == nil
      commits = Octokit.commits(Hublog::Application.config.repo)
    else
      commits = Octokit.commits_since(Hublog::Application.config.repo, last_article.commit_time.to_json)
    end
    return if commits.include? :message
    commit_ids = []
    commits.each do |c|
      break if c[:sha] == last_article.commit_id if last_article
      commit_ids << c[:sha]
    end
    commit_ids.reverse.each do |commit_id|
      commit = Octokit.commit(Hublog::Application.config.repo, commit_id)
      commit[:files].each do |file|
        case file[:status]
        when "added"
          article = Article.new(name: file[:filename],
                                created_time: commit[:commit][:committer][:date],
                                commit_id: commit[:sha],
                                commit_time: DateTime.parse(commit[:commit][:committer][:date]))
          article.save!
        when "modified"
          article = Article.where(name: file[:filename]).first
          article = Article.new(name: file[:filename], created_time: commit[:commit][:committer][:date]) if article.nil?
          article.updated_time = DateTime.parse(commit[:commit][:committer][:date])
          article.content = nil
          article.commit_id = commit[:sha]
          article.commit_time = DateTime.parse(commit[:commit][:committer][:date])
          article.save!
        when "removed"
          article = Article.where(name: file[:filename]).first
          article.destroy unless article.nil?
        end
      end
    end
  end
end
