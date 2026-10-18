class WikiArticle < ApplicationRecord
  has_many :outgoing_links, class_name: "WikiLink", foreign_key: :from_article_id, dependent: :destroy, inverse_of: :from_article
  has_many :incoming_links, class_name: "WikiLink", foreign_key: :to_article_id, dependent: :destroy, inverse_of: :to_article
  has_many :linked_articles, through: :outgoing_links, source: :to_article
  has_many :backlinked_articles, through: :incoming_links, source: :from_article

  validates :title, presence: true, uniqueness: { case_sensitive: false }
  validates :slug, presence: true, uniqueness: true

  before_validation :assign_slug, if: -> { slug.blank? && title.present? }
  after_save :sync_wiki_links

  def self.find_or_create_stub!(title)
    find_by("lower(title) = ?", title.downcase.strip) ||
      create!(title: title.strip, body: "", summary: "", category: "")
  end

  def to_param
    slug
  end

  def stub?
    body.blank?
  end

  private

  def assign_slug
    base = title.to_s.parameterize
    candidate = base
    suffix = 2

    while WikiArticle.where.not(id: id).exists?(slug: candidate)
      candidate = "#{base}-#{suffix}"
      suffix += 1
    end

    self.slug = candidate
  end

  def sync_wiki_links
    target_ids = Wiki::LinkParser.titles_in(body).map { |t| WikiArticle.find_or_create_stub!(t).id }.uniq - [id]

    WikiLink.where(from_article_id: id).where.not(to_article_id: target_ids).destroy_all
    existing_ids = WikiLink.where(from_article_id: id).pluck(:to_article_id)
    (target_ids - existing_ids).each { |to_id| WikiLink.create!(from_article_id: id, to_article_id: to_id) }
  end
end
