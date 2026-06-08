# frozen_string_literal: true

class Router < Roda
  route do |r|
    r.get "search" do
      response["Content-Type"] = "application/json"
      search(r.params["q"]).to_json
    end

    r.root do
      response["Content-Type"] = "text/plain"
      <<~QUOTE
      Here's to the crazy ones.
      The misfits. The rebels. The troublemakers.
      The round pegs in the square holes - the ones who see things differently.
      They're not fond of rules and they have no respect for the status quo.
      You can praise them, disagree with them, quote them, disbelieve them,
      glorify or vilify them. About the only thing that you can't do is ignore them.
      Because they change things.
      QUOTE
    end
  end

  private

  def search(input)
    query = input.to_s.scan(/[[:alnum:]_:-]+/).join(" ")
    DB.fetch(sql, query).all
  end

  def sql
    <<~SQL
      SELECT
        sections.id,
        sections.title,
        sections.anchor,
        sections.level,
        sections.position,
        sections.source_line,
        sections.text,
        chapters.name AS chapter,
        chapters.path AS chapter_path,
        books.name AS book,
        books.path AS book_path,
        bm25(sections_fts) AS rank
      FROM sections_fts
      JOIN sections ON sections.id = sections_fts.section_id
      JOIN chapters ON chapters.id = sections.chapter_id
      JOIN books ON books.id = chapters.book_id
      WHERE sections_fts MATCH ?
      ORDER BY rank
      LIMIT 10
    SQL
  end
end
