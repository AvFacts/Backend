# frozen_string_literal: true

class CreateEpisodes < ActiveRecord::Migration[6.0]
  def change
    create_table :episodes do |t|
      t.integer :number, null: false

      t.string :title, null: false
      t.string :subtitle

      t.string :author

      t.string :summary
      t.text :description, null: false
      t.text :credits

      t.text :script

      t.datetime :published_at
      t.boolean :processed, null: false, default: false
      t.bigint :mp3_size, :aac_size

      t.boolean :explicit, :blocked, null: false, default: false

      t.tsvector :fulltext_search

      t.timestamps
    end

    add_index :episodes, :number, unique: true, name: "episodes_number_unique"
    add_index :episodes, %i[published_at number], name: "episodes_index_action"

    reversible do |dir|
      dir.up do
        execute <<~SQL.squish
          CREATE INDEX episodes_fulltext_search
            ON episodes
            USING GIN (fulltext_search)
        SQL
      end

      dir.down do
        remove_index :episodes_fulltext_search
      end
    end

    reversible do |dir|
      dir.up do
        execute <<~SQL.squish
          CREATE TRIGGER episodes_fulltext_update_trigger
            BEFORE INSERT OR UPDATE
              ON episodes
            FOR EACH ROW EXECUTE PROCEDURE
              tsvector_update_trigger(fulltext_search, 'pg_catalog.english', title, description, script);
        SQL
      end

      dir.down do
        execute "DROP TRIGGER episodes_fulltext_update_trigger"
      end
    end
  end
end
