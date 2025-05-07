class DisclaimersController < ApplicationController
  require 'openai'

  before_action :authenticate_user!, only: [:new, :create, :edit, :update, :destroy]



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
    @disclaimer = Disclaimer.new(disclaimer_params)
    @disclaimer.user = current_user


 
    prompt = "Write a legal disclaimer about #{params[:disclaimer][:topic]} in a #{params[:disclaimer][:tone]} tone."
    client = OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY'])

    response = client.chat(
      parameters: {
        model: "gpt-4o-mini",
        messages: [
          { role: "user", content: prompt }
        ],
        temperature: 0.7
      }
    )

    generated_statement = response.dig("choices", 0, "message", "content").truncate(1000, separator: ' ')

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
        format.turbo_stream {redirect_to dashboard_path, status: :see_other}
        format.html {redirect_to dashboard_path, notice: "Disclaimer Updated"}
      end
    else
      respond_to do |format|
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
    Topic: #{@disclaimer.topic}
    Tone: #{@disclaimer.tone}
    Statement: #{@disclaimer.statement}
  TEXT

  send_data text,
  filename: "disclaimer_#{@disclaimer.id}.txt",
  type: "text/plain",
  disposition: "attachment"

  end




  private

  def disclaimer_params
    params.require(:disclaimer).permit(:statement, :topic, :tone)
    
  end




end
