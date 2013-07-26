class CreateArticles < ActiveRecord::Migration
  def change
    create_table :articles do |t|
      t.string :name
      t.text :content
      t.datetime :created_time
      t.datetime :updated_time
      t.datetime :commit_time
      t.string :commit_id
    end
  end
end
