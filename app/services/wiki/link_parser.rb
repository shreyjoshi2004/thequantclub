module Wiki
  module LinkParser
    LINK_PATTERN = /\[\[([^\]]+)\]\]/

    module_function

    def titles_in(body)
      body.to_s.scan(LINK_PATTERN).flatten.map(&:strip).reject(&:blank?).uniq
    end
  end
end
