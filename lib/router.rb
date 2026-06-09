# frozen_string_literal: true

class Router < Roda
  def self.root = File.realpath File.join(__dir__, "..")
  plugin :public, root: File.join(root, "public")

  route do |r|
    r.root do
      response["content-type"] = "text/html"
      File.read(File.join(self.class.root, "public", "index.html"))
    end

    r.public

    r.get "robert" do
      r.redirect "/robert/"
    end

    r.on "robert" do
      r.root do
        response["content-type"] = "text/html"
        File.read(File.join(self.class.root, "public", "robert", "index.html"))
      end
    end

    r.on "handbook" do
      q = r.params["q"]
      response["content-type"] = "application/json"

      r.on "u" do
        r.get "search" do
          search(q:, book_id: 1).to_json
        end
      end

      r.on "d" do
        r.get "search" do
          search(q:, book_id: 2).to_json
        end
      end

      r.on "p" do
        r.get "search" do
          search(q:, book_id: 3).to_json
        end
      end
    end
  end

  private

  def search(q:, book_id:)
    q = q.to_s.scan(/[[:alnum:]_:-]+/).join(" ")
    DB.fetch(sql, q, book_id).all
  end

  def sql
    <<~SQL
      SELECT
        sections.id, sections.title, sections.anchor,
        sections.level, sections.position, sections.source_line,
        sections.text,
        chapters.name AS chapter,
        books.name AS book,
        bm25(sections_fts) AS rank
      FROM sections_fts
      JOIN sections ON sections.id = sections_fts.section_id
      JOIN chapters ON chapters.id = sections.chapter_id
      JOIN books ON books.id = chapters.book_id
      WHERE sections_fts MATCH ? AND books.id = ?
      ORDER BY rank
      LIMIT 10
    SQL
  end
end
