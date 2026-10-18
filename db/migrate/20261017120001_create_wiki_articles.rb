class CreateWikiArticles < ActiveRecord::Migration[8.1]
  def change
    create_table :wiki_articles do |t|
      t.string :title, null: false
      t.string :slug, null: false
      t.text :summary, default: "", null: false
      t.text :body, default: "", null: false
      t.string :category, default: "", null: false

      t.timestamps
    end

    add_index :wiki_articles, :slug, unique: true
  end
end
