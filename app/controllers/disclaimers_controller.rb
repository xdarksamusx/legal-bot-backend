class DisclaimersController < ApplicationController
  require 'openai'

  before_action :authenticate_user!, only: [:index, :show, :new, :create, :edit, :update, :destroy]



  def index
    @disclaimer = Disclaimer.new

    @disclaimers = current_user.disclaimers

    @latest_disclaimer = Disclaimer.order(created_at: :desc).first


    respond_to do |format|
      format.html 
      format.json {render json:@disclaimers}
    end

  end

  def show
    @disclaimer = current_user.disclaimers.find(params[:id])

    respond_to do |format|
    format.html 
    format.json {render json:@disclaimer}
    end
  end



  def new
    @disclaimer = Disclaimer.new
  end

  def create

    disclaimer_id = params[:disclaimer_id]
    existing = disclaimer_id.present? ? Disclaimer.find_by(id:disclaimer_id) : nil

  puts "Full incoming params: #{params.inspect}"


    @disclaimer =  existing ||  Disclaimer.new(disclaimer_params)
    @disclaimer.user = current_user


 
    prompt = "Write a legal disclaimer about #{params[:disclaimer][:message]}."
    client = OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY'])

    user_input = params[:disclaimer][:message]

    user_message =
    if user_input.is_a?(Array)
      user_input  
    else
      [ { role: "user", content: user_input } ]
    end

    chat_history = existing&.chat_history || [
      { role: "system", content: "You are a helpful legal bot." }
    ]

    messages = chat_history + user_message



    response = client.chat(
      parameters: {
        model: "gpt-4o-mini",
        messages: messages,
        temperature: 0.7
      }
    )

    generated_statement = response.dig("choices", 0, "message", "content").truncate(3000, separator: ' ')



    assistant_message = {
  role: "assistant",
  content: generated_statement
}


full_history = messages + [assistant_message]

@disclaimer.chat_history = full_history


@disclaimer.message = user_message



    @disclaimer.statement = generated_statement

 

  
    

 
    


 
    if @disclaimer.save 
      respond_to do |format |
        format.html {redirect_to disclaimers_path(disclaimer_id:@disclaimer.id)}

        format.json {render json: @disclaimer, status: :created}
      end
    else
      respond_to do |format|
        format.html { render :index, status: :unprocessable_entity }
        format.json { render json: @disclaimer.errors, status: :unprocessable_entity }
      end     
    end
  end



  def edit
    @disclaimer = current_user.disclaimers.find(params[:id])

    respond_to do |format|
      format.html # 
      format.json { render json: @disclaimer }
    end

 
  end


  def update
    @disclaimer = current_user.disclaimers.find(params[:id])

    if @disclaimer.update(disclaimer_params)

      respond_to do |format|
        format.json { render json: @disclaimer }

        format.turbo_stream {redirect_to dashboard_path, status: :see_other}
        format.html {redirect_to dashboard_path, notice: "Disclaimer Updated"}
      end
    else
      respond_to do |format|
        format.json { render json: @disclaimer.errors, status: :unprocessable_entity }

        format.turbo_stream {render :edit, status: :unprocessable_entity}
        format.html {render :edit, status: :unprocessable_entity}
      end


    end


  end






  def destroy
    @disclaimer = current_user.disclaimers.find(params[:id])

    @disclaimer.destroy 

    respond_to do |format|
      format.turbo_stream {redirect_to dashboard_path, status: :see_other}
      format.html {redirect_to dashboard_path, status:  :see_other}
    end
 


  end


  def download_pdf
    @disclaimer = current_user.disclaimers.find(params[:id])
    pdf = Prawn::Document.new
    pdf.text @disclaimer.statement
    send_data pdf.render,
              filename: "disclaimer_#{@disclaimer.id}.pdf",
              type: "application/pdf",
              disposition: "attachment"
  end


  def download_text_file

    @disclaimer = current_user.disclaimers.find(params[:id])
    text = <<~TEXT
    Prompt: #{@disclaimer.message}
    Statement: #{@disclaimer.statement}
  TEXT

  send_data text,
  filename: "disclaimer_#{@disclaimer.id}.txt",
  type: "text/plain",
  disposition: "attachment"

  end




  private

  def disclaimer_params
    params.require(:disclaimer).permit(
      :topic,
      :tone,
      :prompt,
      :statement,
      message: [:role, :content],
      chat_history: [:role, :content]
    )
  end
  



end
