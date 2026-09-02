# frozen_string_literal: true

class RenamePuffiesTableToBeasties < ActiveRecord::Migration[8.0]
  def change
    rename_table :puffies, :beasties
  end
end
