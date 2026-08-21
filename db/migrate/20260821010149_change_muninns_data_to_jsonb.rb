# frozen_string_literal: true

class ChangeMuninnsDataToJsonb < ActiveRecord::Migration[8.0]
  def change
    change_column :muninns, :data, :jsonb, using: "data::jsonb"
  end
end