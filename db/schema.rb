# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_10_17_120002) do
  create_table "wiki_articles", force: :cascade do |t|
    t.string "title", null: false
    t.string "slug", null: false
    t.text "summary", default: "", null: false
    t.text "body", default: "", null: false
    t.string "category", default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_wiki_articles_on_slug", unique: true
  end

  create_table "wiki_links", force: :cascade do |t|
    t.integer "from_article_id", null: false
    t.integer "to_article_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["from_article_id", "to_article_id"], name: "index_wiki_links_on_from_and_to", unique: true
    t.index ["from_article_id"], name: "index_wiki_links_on_from_article_id"
    t.index ["to_article_id"], name: "index_wiki_links_on_to_article_id"
  end

  add_foreign_key "wiki_links", "wiki_articles", column: "from_article_id"
  add_foreign_key "wiki_links", "wiki_articles", column: "to_article_id"
end
