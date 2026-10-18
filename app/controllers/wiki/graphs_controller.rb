module Wiki
  class GraphsController < ApplicationController
    def show
    end

    def data
      articles =
        if params[:root].present?
          root = WikiArticle.find_by!(slug: params[:root])
          neighbor_ids = (root.outgoing_links.pluck(:to_article_id) + root.incoming_links.pluck(:from_article_id)).uniq
          WikiArticle.where(id: [root.id] + neighbor_ids)
        else
          WikiArticle.all
        end

      article_ids = articles.pluck(:id)
      links = WikiLink.where(from_article_id: article_ids, to_article_id: article_ids)

      render json: {
        nodes: articles.map { |a| { id: a.id, title: a.title, slug: a.slug, stub: a.stub? } },
        edges: links.map { |l| { source: l.from_article_id, target: l.to_article_id } }
      }
    end
  end
end
