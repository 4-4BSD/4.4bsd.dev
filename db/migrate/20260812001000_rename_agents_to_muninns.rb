# frozen_string_literal: true

class RenameAgentsToMuninns < ActiveRecord::Migration[8.0]
  def change
    rename_table :agents, :muninns
  end
end