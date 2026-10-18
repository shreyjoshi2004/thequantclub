module Wiki
  class BodyRenderer
    Heading = Struct.new(:text, :id, keyword_init: true)
    Result = Struct.new(:html, :headings, keyword_init: true)

    def self.render(body)
      new(body).render
    end

    def initialize(body)
      @body = body.to_s
    end

    def render
      headings = []

      blocks = @body.split(/\n{2,}/).filter_map do |block|
        block = block.strip
        next if block.empty?

        if block.start_with?("## ")
          text = block.sub(/\A##\s+/, "")
          id = text.parameterize
          headings << Heading.new(text: text, id: id)
          %(<h2 id="#{ERB::Util.html_escape(id)}">#{linkify(text)}</h2>)
        else
          %(<p>#{linkify(block)}</p>)
        end
      end

      Result.new(html: blocks.join("\n").html_safe, headings: headings)
    end

    private

    def linkify(text)
      ERB::Util.html_escape(text).gsub(/\[\[([^\]]+)\]\]/) do
        title = Regexp.last_match(1).strip
        target = WikiArticle.find_by("lower(title) = ?", title.downcase)
        next ERB::Util.html_escape(title) unless target

        css_class = target.stub? ? "wiki-link wiki-link--stub" : "wiki-link"
        %(<a href="/wiki/#{target.slug}" class="#{css_class}">#{ERB::Util.html_escape(title)}</a>)
      end.html_safe
    end
  end
end
