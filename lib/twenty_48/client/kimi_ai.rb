require 'httparty'

module Twenty48
  module Client::KimiAi
    extend self

    URI = "https://api.moonshot.ai/v1/chat/completions"
    HEADERS = {
      "Content-Type" => "application/json",
      "Authorization" => "Bearer #{ENV['MOONSHOT_AI_API_KEY']}"
    }
    TIMEOUT = 180

    MODEL = 'kimi-thinking-preview'
    MAX_TOKENS = 2048

    def create(system, user)
      body = {
        model: MODEL,
        messages: [
          { role: 'system', content: system },
          { role: 'user', content: user },
        ],
        max_tokens: MAX_TOKENS,
        timeout: TIMEOUT
      }.to_json
      response = HTTParty.post URI, body: body, headers: HEADERS

      response["choices"][0]["message"]["content"] rescue 'error fetching AI response'
    end
  end
end
