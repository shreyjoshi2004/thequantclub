class WikiArticle < ApplicationRecord
  validates :title, presence: true, uniqueness: { case_sensitive: false }
  validates :slug, presence: true, uniqueness: true

  before_validation :assign_slug, if: -> { slug.blank? && title.present? }

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
end
