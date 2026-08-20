# frozen_string_literal: true

require_relative "spec_helper"
require "stringio"

RSpec.describe "sessionful agent" do
  def agent = Raven::Agents::Muninn
  def app = Raven::Routes::Application

  # Fetch the CSRF token embedded in the homepage meta tag.
  def csrf_token
    get "/"
    last_response.body[/name="_csrf" content="([^"]+)"/, 1]
  end

  it "serves the homepage" do
    get "/"
    expect(last_response.status).to eq(200)
    expect(last_response.body).to include("r.uby.dev")
  end

  it "serves the resume" do
    get "/resume"
    expect(last_response.status).to eq(200)
    expect(last_response.body).to include("Resume")
  end

  describe "POST /api/agents" do
    it "creates an agent and binds it to the session" do
      token = csrf_token
      expect {
        post "/api/agents", {}, {"HTTP_X_CSRF_TOKEN" => token}
      }.to change(agent, :count).by(1)
      expect(last_response.status).to eq(200)
      body = JSON.parse(last_response.body)
      expect(body["ok"]).to eq(true)
      expect(body["id"]).to eq(agent.last.id)
      expect(last_request.session["agent_id"]).to eq(agent.last.id)
    end
  end

  describe "GET /api/agent" do
    it "responds with a server-sent event stream" do
      get "/api/agent", q: "hello"
      expect(last_response.status).to eq(200)
      expect(last_response["Content-Type"]).to eq("text/event-stream")
    end
  end

  describe "DELETE /api/agent" do
    it "destroys the bound agent and clears the session" do
      allow_any_instance_of(agent).to receive(:talk) { double(content: "x") }
      token = csrf_token
      post "/api/agents", {}, {"HTTP_X_CSRF_TOKEN" => token}
      agent_id = agent.last.id

      expect {
        delete "/api/agent", {}, {"HTTP_X_CSRF_TOKEN" => token}
      }.to change(agent, :count).by(-1)
      expect(last_response.status).to eq(200)
      expect(JSON.parse(last_response.body)["ok"]).to eq(true)
      expect(agent.exists?(agent_id)).to eq(false)
    end
  end
end

RSpec.describe Raven::Agents::Muninn::Stream do
  def stream = described_class.new(@io)

  before { @io = StringIO.new }

  it "emits content events" do
    stream.on_content("hi")
    expect(@io.string).to include("event: content")
    expect(@io.string).to include('{"text":"hi"}')
  end

  it "emits tool call and tool return events" do
    tool = double(id: "call_1", name: "knowledge", arguments: {"project" => "llm.rb"})
    result = double(error?: false)
    stream.on_tool_call(tool)
    stream.on_tool_return(tool, result)
    expect(@io.string).to include("event: tool_call")
    expect(@io.string).to include("event: tool_return")
    expect(@io.string).to include('"id":"call_1"')
    expect(@io.string).to include('"ok":true')
  end

  it "emits done events" do
    stream.done(res: double(content: "the answer"))
    expect(@io.string).to include("event: done")
    expect(@io.string).to include('"answer":"the answer"')
  end

  it "emits failed events" do
    stream.error(message: "boom")
    expect(@io.string).to include("event: failed")
    expect(@io.string).to include('"error":"boom"')
  end
end
