class Api::OpenaiController < ApplicationController
  protect_from_forgery with: :null_session

  def generate
    topic = params[:topic]
    tone = params[:tone]

    client = OpenAI::Client.new(access_token: ENV["OPENAI_API_KEY"])



    response = client.chat(
      parameters: {
        model: "gpt-4",
        messages: [
          { role: "system", content: "You are a legal expert that writes disclaimers." },
          { role: "user", content: "Write a #{tone} disclaimer about #{topic}." }
        ]
      }
    )

    disclaimer_text = response.dig("choices", 0, "message", "content")

    render json: {disclaimer: disclaimer_text}


  end



end