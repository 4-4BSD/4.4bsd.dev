# frozen_string_literal: true

class CreateAgents < ActiveRecord::Migration[8.0]
  def change
    create_table :agents do |t|
      t.text :data # serialized LLM::Agent state (memory)
      t.timestamps
    end
  end
end