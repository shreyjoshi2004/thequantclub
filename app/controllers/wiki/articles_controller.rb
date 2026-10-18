module Wiki
  class ArticlesController < ApplicationController
    before_action :set_article, only: [:show, :edit, :update]

    def index
      @categories = WikiArticle.where.not(body: "").group(:category).order(:category).count
      @recent = WikiArticle.where.not(body: "").order(created_at: :desc).limit(5)
      @term_of_the_day = term_of_the_day
    end

    def search
      @query = params[:q].to_s.strip
      @results = @query.present? ? WikiArticle.where("title LIKE :q OR body LIKE :q", q: "%#{@query}%") : WikiArticle.none
    end

    def show
      rendered = Wiki::BodyRenderer.render(@article.body)
      @body_html = rendered.html
      @headings = rendered.headings
      @backlinks = @article.backlinked_articles
      @related = @article.linked_articles
    end

    def new
      @article = WikiArticle.new
    end

    def create
      @article = WikiArticle.new(article_params)

      if @article.save
        redirect_to wiki_article_path(@article), notice: "Article created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @article.update(article_params)
        redirect_to wiki_article_path(@article), notice: "Article updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_article
      @article = WikiArticle.find_by!(slug: params[:slug])
    end

    def article_params
      params.require(:wiki_article).permit(:title, :summary, :body, :category)
    end

    def term_of_the_day
      published = WikiArticle.where.not(body: "").order(:id).to_a
      return nil if published.empty?

      published[Date.current.yday % published.count]
    end
  end
end
