require 'httparty'
require 'ld-eventsource'

module Twenty48
  module Client::KimiAi
    extend self

    URI = "https://api.moonshot.ai/v1/chat/completions"
    HEADERS = {
      "Authorization" => "Bearer #{ENV['MOONSHOT_AI_API_KEY']}"
    }
    TIMEOUT = 180

    MODEL = 'kimi-thinking-preview'
    MAX_TOKENS = 2048

    def create(system, user, update:, complete:, error:)
      payload = {
        model: MODEL,
        messages: [
          { role: 'system', content: system },
          { role: 'user', content: user },
        ],
        max_tokens: MAX_TOKENS,
        timeout: TIMEOUT,
        stream: true
      }.to_json

      result = ''

      SSE::Client.new(URI, method: 'POST', headers: HEADERS, payload: payload) do |client|
        client.on_event do |event|
          if event.data == '[DONE]'
            complete.call
          elsif event.data
            parsedData = JSON.parse(event.data)
            content = parsedData["choices"][0]["delta"]["reasoning_content"]
            result << content if content
            update.call result
          end
        end

        client.on_error do |e|
          error.call(e)
        end
      end
    end
  end
end
