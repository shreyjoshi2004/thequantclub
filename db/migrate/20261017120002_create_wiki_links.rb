class CreateWikiLinks < ActiveRecord::Migration[8.1]
  def change
    create_table :wiki_links do |t|
      t.references :from_article, null: false, foreign_key: { to_table: :wiki_articles }
      t.references :to_article, null: false, foreign_key: { to_table: :wiki_articles }

      t.timestamps
    end

    add_index :wiki_links, [:from_article_id, :to_article_id], unique: true, name: "index_wiki_links_on_from_and_to"
  end
end
