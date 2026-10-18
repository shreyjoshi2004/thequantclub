class WikiLink < ApplicationRecord
  belongs_to :from_article, class_name: "WikiArticle"
  belongs_to :to_article, class_name: "WikiArticle"

  validates :to_article_id, uniqueness: { scope: :from_article_id }
end
