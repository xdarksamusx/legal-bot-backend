class DisclaimersController < ApplicationController
  require 'openai'

  before_action :authenticate_user!, only: [:new, :create, :edit, :update, :destroy]



  def index
    @disclaimer = Disclaimer.new

    @disclaimers = Disclaimer.all

    @latest_disclaimer = Disclaimer.order(created_at: :desc).first


    respond_to do |format|
      format.html 
      format.json {render json:@disclaimers}
    end

  end

  def show
    @disclaimer = Disclaimer.find(params[:id])

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
    @disclaimer = disclaimer.find(params[:id])

 
  end


  def update
    @disclaimer = Disclaimer.find(params[:id])

    if @disclaimer.update(disclaimer_params)
      render json: @disclaimer 
    else
      render json: @disclaimer.errors, status: :unprocessable_entity
    end


  end






  def destroy
    @disclaimer = Disclaimer.find(params[:id])

    @disclaimer.destroy 

    head :no_content


  end

  private

  def disclaimer_params
    params.require(:disclaimer).permit(:statement, :topic, :tone)
    
  end




end
