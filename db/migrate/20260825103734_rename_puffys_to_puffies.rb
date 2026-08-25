# frozen_string_literal: true

class RenamePuffysToPuffies < ActiveRecord::Migration[8.0]
  def change
    rename_table :puffys, :puffies
  end
end